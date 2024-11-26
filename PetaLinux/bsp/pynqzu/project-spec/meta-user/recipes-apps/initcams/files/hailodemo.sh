#!/bin/bash

# Opsero Electronic Design Inc. 2024
#-----------------------------------
# This script goes through all of the media devices found and uses media-ctl
# to filter out the devices that are not attached to the xilinx-video driver.
# This way we attempt to target only the cameras that are connected to the 
# RPi Camera FMC, and ignore any USB (or other) cameras that are connected.
# We also use media-ctl to determine the video device that is associated
# with each media device, and we keep these values in an array.
# The second part of the script goes through the array of media devices and
# configures the associated video pipe with values for resolution, format
# and frame rate, according to a set of variables defined at the top of this
# script.
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

#--------------------------------------------------------------------------------
# Example settings - the script will configure ALL video pipelines to these specs
#--------------------------------------------------------------------------------
# Resolution of RPi cameras (must be a resolution supported by the IMX219 Linux driver 640x480, 1640x1232, 1920x1080)
SRC_RES_W=1920
SRC_RES_H=1080
# Resolution of RPi camera pipelines (after Video Processing Subsystem IP)
OUT_RES_W=1280
OUT_RES_H=720
# Output format of the RPi camera pipelines (use a GStreamer pixel format from the dict above)
OUT_FORMAT=YUY2
# Frame rate (fps)
FRM_RATE=25
#--------------------------------------------------------------------------------
# End of example settings
#--------------------------------------------------------------------------------

# Find the vmixer
VMIX_PATH=$(find /sys/bus/platform/devices/ -name "*.v_mix" | head -n 1)
VMIX=$(basename "$VMIX_PATH")

# Find out the monitor's highest resolution
output=$(modetest -c -M xlnx | grep "#0")
DISP_RES=$(echo "$output" | awk '{print $2}')

echo "-------------------------------------------------"
echo " Capture pipeline init: RPi cam -> Scaler -> DDR"
echo "-------------------------------------------------"

# Print the settings
echo "Configuring all video capture pipelines to:"
echo " - RPi Camera output    : $SRC_RES_W x $SRC_RES_H"
echo " - Scaler (VPSS) output : $OUT_RES_W x $OUT_RES_H $OUT_FORMAT"
echo " - Frame rate           : $FRM_RATE fps"

# Print the bus_id of the video mixer
echo "Video Mixer found here:"
echo " - $VMIX"

echo "Monitor resolution:"
echo " - $DISP_RES"

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

#-------------------------------------------------------------------------------
# Setup the display pipeline
#-------------------------------------------------------------------------------

init_variables $@


# Setup the split-display pipeline
echo | modetest -M xlnx -D ${VMIX} -s 60@46:${DISP_RES}@NV16

#------------------------------------------------------------------------------
# Run GStreamer to combine all videos and display on the screen
#-------------------------------------------------------------------------------
full_command="gst-launch-1.0 -v "

# Screen quadrants: TOP-LEFT, TOP-RIGHT, BOTTOM-LEFT, BOTTOM-RIGHT
quadrants=(
        "plane-id=34 render-rectangle=\"<0,0,${OUT_RES_W},${OUT_RES_H}>\""
        "plane-id=36 render-rectangle=\"<${OUT_RES_W},0,${OUT_RES_W},${OUT_RES_H}>\""
        "plane-id=38 render-rectangle=\"<0,${OUT_RES_H},${OUT_RES_W},${OUT_RES_H}>\""
        "plane-id=40 render-rectangle=\"<${OUT_RES_W},${OUT_RES_H},${OUT_RES_W},${OUT_RES_H}>\""
)

index=0

# For each connected camera, add pipeline to gstreamer command
for media in "${!media_to_video_mapping[@]}"; do
        # Append the specific command for the current iteration to the full command
        full_command+="v4l2src device=${media_to_video_mapping[$media]} io-mode=dmabuf-import stride-align=256 do-timestamp=true ! "
        full_command+="video/x-raw, width=${OUT_RES_W}, height=${OUT_RES_H}, format=${OUT_FORMAT}, framerate=${FRM_RATE}/1 ! "
        full_command+="synchailonet hef-path=$hef_path scheduling-algorithm=1 batch-size=1 vdevice-key=1 ! "
        full_command+="queue leaky=2 max-size-buffers=3 ! "
        full_command+="hailofilter function-name=$network_name config-path=$json_config_path so-path=$postprocess_so qos=false ! "
        full_command+="queue leaky=2 max-size-buffers=10  ! "
        full_command+="hailooverlay ! "
        full_command+="kmssink bus-id=${VMIX} ${quadrants[$index]} show-preroll-frame=false sync=false can-scale=false "
        index=$((index + 1))
done

# Display the command being run
echo "GStreamer command:"
echo "--------------------------"
echo "${full_command}"
echo "--------------------------"

# Execute the command
eval "${full_command}"
