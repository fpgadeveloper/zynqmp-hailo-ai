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
# The last part of the script prints a list of the cameras that were found
# and configured, showing the port (CAM0,CAM1,CAM2,CAM3), the media device
# (eg. /dev/media0) and the video device (eg. /dev/video0) for each.

# This dictionary associates GStreamer pixel formats with those used with media-ctl
declare -A format_dict
format_dict["NV12"]="VYYUYY8_1X24"
format_dict["YUY2"]="UYVY8_1X16"

#--------------------------------------------------------------------------------
# Example settings - the script will configure ALL video pipelines to these specs
#--------------------------------------------------------------------------------
# Resolution of RPi cameras (must be a resolution supported by the IMX219 Linux driver 640x480, 1640x1232, 1920x1080)
SRC_RES_W="${1:-1920}"
SRC_RES_H="${2:-1080}"
# Resolution of RPi camera pipelines (after Video Processing Subsystem IP)
OUT_RES_W="${3:-1920}"
OUT_RES_H="${4:-1080}"
# Output format of the RPi camera pipelines (use a GStreamer pixel format from the dict above)
OUT_FORMAT="${5:-YUY2}"
#--------------------------------------------------------------------------------
# End of example settings
#--------------------------------------------------------------------------------

# Find the vmixer
VMIX_PATH=$(find /sys/bus/platform/devices/ -name "*.v_mix" | head -n 1)
VMIX=$(basename "$VMIX_PATH")

echo "-------------------------------------------------"
echo " Capture pipeline init: RPi cam -> Scaler -> DDR"
echo "-------------------------------------------------"

# Print the settings
echo "Configuring all video capture pipelines to:"
echo " - RPi Camera output    : $SRC_RES_W x $SRC_RES_H"
echo " - Scaler (VPSS) output : $OUT_RES_W x $OUT_RES_H $OUT_FORMAT"

# Print the bus_id of the video mixer
echo "Video Mixer found here:"
echo " - $VMIX"

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
# The section below serves as an example for configuring the video pipelines with
# media-ctl. In this example, we set all video pipelines to the same specs.
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
# List the media devices and their associated video devices
#-------------------------------------------------------------------------------
echo "Detected and configured the following cameras on RPi Camera FMC:"
for media in "${!media_to_video_mapping[@]}"; do
        echo " - ${media_to_cam_interface[$media]}: $media = ${media_to_video_mapping[$media]}"
done
