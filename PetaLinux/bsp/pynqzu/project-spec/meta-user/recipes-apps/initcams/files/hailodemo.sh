#!/bin/bash

# Opsero Electronic Design Inc. 2024
#-----------------------------------
# This script goes through all of the media devices found and uses media-ctl
# to filter out the devices that are not attached to the xilinx-video driver.
# This way we attempt to target only the cameras that are connected to the 
# RPi Camera FMC, and ignore any USB (or other) cameras that are connected.
# We also use media-ctl to determine the video device that is associated
# with each media device, and we keep these values in an array.
# The second part of the script goes through the array of cameras and makes 
# some changes to their settings. This can be useful for setting all of the
# cameras to the same configuration.
# The next part of the script prints a list of the cameras that were found
# and configured, showing the port (CAM0,CAM1,CAM2,CAM3), the media device
# (eg. /dev/media0) and the video device (eg. /dev/video0) for each.
# The last part of the script launches gstreamer to demonstrate the Hailo
# processing 4 video streams of 720p resolution.

set -e

CURRENT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

function init_variables() {
    readonly RESOURCES_DIR="${CURRENT_DIR}/resources"
    readonly POSTPROCESS_DIR="/usr/lib/hailo-post-processes"
    readonly DEFAULT_POSTPROCESS_SO="$POSTPROCESS_DIR/libyolo_post.so"
    readonly DEFAULT_NETWORK_NAME="yolov5"
    readonly DEFAULT_VIDEO_SOURCE="/dev/video0"
    readonly DEFAULT_HEF_PATH="${RESOURCES_DIR}/${DEFAULT_NETWORK_NAME}m_yuv.hef"
    readonly DEFAULT_JSON_CONFIG_PATH="$RESOURCES_DIR/configs/yolov5.json"

    postprocess_so=$DEFAULT_POSTPROCESS_SO
    network_name=$DEFAULT_NETWORK_NAME
    input_source=$DEFAULT_VIDEO_SOURCE
    hef_path=$DEFAULT_HEF_PATH
    json_config_path=$DEFAULT_JSON_CONFIG_PATH

    print_gst_launch_only=false
    additional_parameters=""
}



declare -A format_dict
format_dict["NV12"]="VYYUYY8_1X24"
format_dict["YUY2"]="UYVY8_1X16"

#-------------------------------------------------------------------------------
# Example settings
#-------------------------------------------------------------------------------
# Resolution of RPi cameras (must be a resolution supported by the IMX219 Linux driver 640x480, 1640x1232, 1920x1080)
SRC_RES_W=1920
SRC_RES_H=1080
# Resolution of RPi camera pipelines (after Video Processing Subsystem IP)
OUT_RES_W=1280
OUT_RES_H=720
# Output format of the RPi camera pipelines
OUT_FORMAT=YUY2
# Resolution of the monitor
DISP_RES_W=2560
DISP_RES_H=1440
# Frame rate (fps)
FRM_RATE=10

# Find all the media devices
media_devices=($(ls /dev/media*))

# Declare a associative arrays
declare -A unique_video_devices
declare -A media_to_video_mapping
declare -A media_to_cam_interface

# For each media device, find its associated video devices
for media in "${media_devices[@]}"; do
        output=$(media-ctl -d "$media" -p)
        # Check if the media device is of type "xilinx-video"
        if echo "$output" | grep -q "driver          xilinx-video"; then
                video_device=$(echo "$output" | grep "dev/video")
                # Extract video device path from the grep result
                if [[ $video_device =~ (/dev/video[0-9]+) ]]; then
                        unique_video_devices["${BASH_REMATCH[1]}"]=1
                        # Store the media to video relationship
                        media_to_video_mapping["$media"]="${BASH_REMATCH[1]}"

                        # Extract X from the string "vcap_mipi_X_v_proc"
                        if [[ $output =~ vcap_mipi_([0-9])_v_proc ]]; then
                                cam_interface="CAM${BASH_REMATCH[1]}"
                                media_to_cam_interface["$media"]="$cam_interface"
                        fi
                fi
        fi
done

#-------------------------------------------------------------------------------
# For each video device, set the parameters.
#===============================================================================
# Below is the section that you should edit if you want to use this script
# to configure all of the connected cameras in a certain way.
# See the documentation for help on these commands.
# https://rpi.camerafmc.com/ (PetaLinux -> Debugging tips section)
#-------------------------------------------------------------------------------
for media in "${!media_to_video_mapping[@]}"; do
        OUTPUT=$(media-ctl -d $media -p)
        I2C_BUS=$(echo "$OUTPUT" | grep '.*- entity.*imx219' | awk -F' ' '{print $5}')
        media-ctl -V "\"imx219 ${I2C_BUS}\":0 [fmt:SRGGB10_1X10/${SRC_RES_W}x${SRC_RES_H}]" -d $media
        MIPI_CSI=$(echo "$OUTPUT" | grep '.*- entity.*mipi_csi2_rx_subsystem' | awk -F' ' '{print $4}')
        media-ctl -V "\"${MIPI_CSI}\":0 [fmt:SRGGB10_1X10/${SRC_RES_W}x${SRC_RES_H} field:none colorspace:srgb]" -d $media
        media-ctl -V "\"${MIPI_CSI}\":1  [fmt:SRGGB10_1X10/${SRC_RES_W}x${SRC_RES_H} field:none colorspace:srgb]" -d $media
        ISP_PIPE=$(echo "$OUTPUT" | grep '.*- entity.*ISPPipeline_accel' | awk -F' ' '{print $4}')
        media-ctl -V "\"${ISP_PIPE}\":0  [fmt:SRGGB10_1X10/${SRC_RES_W}x${SRC_RES_H} field:none colorspace:srgb]" -d $media
        media-ctl -V "\"${ISP_PIPE}\":1  [fmt:RBG888_1X24/${SRC_RES_W}x${SRC_RES_H} field:none colorspace:srgb]" -d $media
        V_PROC=$(echo "$OUTPUT" | grep '.*- entity.*.v_proc_ss ' | awk -F' ' '{print $4}')
        media-ctl -V "\"${V_PROC}\":0  [fmt:RBG888_1X24/${SRC_RES_W}x${SRC_RES_H} field:none colorspace:srgb]" -d $media
        media-ctl -V "\"${V_PROC}\":1  [fmt:${format_dict[$OUT_FORMAT]}/${OUT_RES_W}x${OUT_RES_H} field:none colorspace:srgb]" -d $media
done


#-------------------------------------------------------------------------------
# End of the section to edit.
#-------------------------------------------------------------------------------

# Display the media devices and their associated video devices
echo "Detected and configured the following cameras on RPi Camera FMC:"
for media in "${!media_to_video_mapping[@]}"; do
        echo " - ${media_to_cam_interface[$media]}: $media = ${media_to_video_mapping[$media]}"
done

# Run GStreamer to combine 4 videos and display on the screen


init_variables $@

#parse_args $@


PIPELINE_00="\
    v4l2src device=/dev/video0 io-mode=dmabuf-import stride-align=256 do-timestamp=true ! \
    video/x-raw, width=${OUT_RES_W}, height=${OUT_RES_H}, format=${OUT_FORMAT}, framerate=${FRM_RATE}/1 ! \
    hailonet hef-path=$hef_path scheduling-algorithm=1 batch-size=1 vdevice-key=1 ! \
    queue leaky=2 max-size-buffers=3 ! \
    hailofilter function-name=$network_name config-path=$json_config_path so-path=$postprocess_so qos=false ! \
    queue leaky=2 max-size-buffers=10  ! \
    hailooverlay ! \
    queue leaky=2 max-size-buffers=10 max-size-bytes=0 max-size-time=0 "

PIPELINE_01="\
    v4l2src device=/dev/video1 io-mode=dmabuf-import stride-align=256 do-timestamp=true ! \
    video/x-raw, width=${OUT_RES_W}, height=${OUT_RES_H}, format=${OUT_FORMAT}, framerate=${FRM_RATE}/1 ! \
    hailonet hef-path=$hef_path scheduling-algorithm=1 batch-size=1 vdevice-key=1 ! \
    queue leaky=2 max-size-buffers=3 max-size-bytes=0 max-size-time=0 ! \
    hailofilter function-name=$network_name config-path=$json_config_path so-path=$postprocess_so qos=false ! \
    queue leaky=2 max-size-buffers=10 max-size-bytes=0 max-size-time=0 ! \
    hailooverlay ! \
    queue leaky=2 max-size-buffers=10 max-size-bytes=0 max-size-time=0 "

PIPELINE_02="\
    v4l2src device=/dev/video2 io-mode=dmabuf-import stride-align=256 do-timestamp=true ! \
    video/x-raw, width=${OUT_RES_W}, height=${OUT_RES_H}, format=${OUT_FORMAT}, framerate=${FRM_RATE}/1 ! \
    hailonet hef-path=$hef_path scheduling-algorithm=1 batch-size=1 vdevice-key=1 ! \
    queue leaky=2 max-size-buffers=3 max-size-bytes=0 max-size-time=0 ! \
    hailofilter function-name=$network_name config-path=$json_config_path so-path=$postprocess_so qos=false ! \
    queue leaky=2 max-size-buffers=10 max-size-bytes=0 max-size-time=0 ! \
    hailooverlay ! \
    queue leaky=2 max-size-buffers=10 max-size-bytes=0 max-size-time=0 "

PIPELINE_03="\
    v4l2src device=/dev/video3 io-mode=dmabuf-import stride-align=256 do-timestamp=true ! \
    video/x-raw, width=${OUT_RES_W}, height=${OUT_RES_H}, format=${OUT_FORMAT}, framerate=${FRM_RATE}/1 ! \
    hailonet hef-path=$hef_path scheduling-algorithm=1 batch-size=1 vdevice-key=1 ! \
    queue leaky=2 max-size-buffers=3 max-size-bytes=0 max-size-time=0 ! \
    hailofilter function-name=$network_name config-path=$json_config_path so-path=$postprocess_so qos=false ! \
    queue leaky=2 max-size-buffers=10 max-size-bytes=0 max-size-time=0 ! \
    hailooverlay ! \
    queue leaky=2 max-size-buffers=10 max-size-bytes=0 max-size-time=0 "


# v4l2src device=/dev/video0 io-mode=dmabuf-import stride-align=256 do-timestamp=true \
#! video/x-raw, width=${OUT_RES_W}, height=${OUT_RES_H}, format=${OUT_FORMAT}, framerate=${FRM_RATE}/1 \


gst-launch-1.0 -v \
${PIPELINE_00} \
! comp.sink_0 \
vvas_xcompositor xclbin-location=/run/media/mmcblk0p1/dpu.xclbin \
 sink_0::xpos=0     sink_0::ypos=0 \
 sink_1::xpos=${OUT_RES_W}   sink_1::ypos=0 \
 sink_2::xpos=0     sink_2::ypos=${OUT_RES_H} \
 sink_3::xpos=${OUT_RES_W}   sink_3::ypos=${OUT_RES_H} \
name=comp \
! video/x-raw , width=${DISP_RES_W}, height=${DISP_RES_H} , format=NV12 \
! queue leaky=1 max-size-buffers=3 \
! kmssink plane-id=39 fullscreen-overlay=true sync=false \
${PIPELINE_01} \
! comp.sink_1 \
${PIPELINE_02} \
! comp.sink_2 \
${PIPELINE_03} \
! comp.sink_3
