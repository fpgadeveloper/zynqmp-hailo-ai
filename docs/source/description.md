# Description

This project demonstrates multi-camera YOLOv5 accelerated by the Hailo-8 on the Zynq UltraScale+.
The setup has 4x Raspberry Pi cameras and can run on a few different Zynq UltraScale+ development
platforms. Cameras are connected to the Zynq UltraScale+ development boards via the Opsero [RPi Camera FMC]. 
The [Hailo-8 AI accelerator] connects to the development board via the [FPGA Drive FMC Gen4]
or the [M.2 M-key Stack FMC] depending on the target design 
(see list of [target designs](#target-designs)).

A detailed description of this example design has also been written in the blog post 
[Multi-camera YOLOv5 on Zynq UltraScale+ with Hailo-8 AI Acceleration](https://www.fpgadeveloper.com/multi-camera-yolov5-on-zynq-ultrascale-with-hailo-8-ai-acceleration/).

## Hardware Platforms

The hardware designs provided in this reference are based on Vivado and support a range of MPSoC evaluation
boards. The repository contains all necessary scripts and code to build these designs for the supported platforms listed below:

{% for group in data.groups %}
    {% set designs_in_group = [] %}
    {% for design in data.designs %}
        {% if design.group == group.label and design.publish %}
            {% set _ = designs_in_group.append(design.label) %}
        {% endif %}
    {% endfor %}
    {% if designs_in_group | length > 0 %}
### {{ group.name }} platforms

| Target board        | FMC Slot Used | Cameras | Active M.2 Slots | VCU |
|---------------------|---------------|---------|-----|-----|
{% for design in data.designs %}{% if design.group == group.label and design.publish %}| [{{ design.board }}]({{ design.link }}) | {{ design.connector }} | {{ design.cams | length }} | {{ design.lanes | length }} | {% if design.vcu %} ✅ {% else %} ❌ {% endif %} |
{% endif %}{% endfor %}
{% endif %}
{% endfor %}

## Software

These reference designs can be driven within a PetaLinux environment. 
The repository includes all necessary scripts and code to build the PetaLinux environment. The table 
below outlines the corresponding applications available in each environment:

| Environment      | Available Applications  |
|------------------|-------------------------|
| PetaLinux        | Built-in Linux commands<br>Additional tools: [GStreamer] |

## Architecture

The hardware design for these projects is built in Vivado and is composed of IP that implement the
MIPI interface with the cameras and VCU as well as a display pipeline. For interface with the Hailo AI
accelerator, the designs contain the XDMA IP.
The main elements are:

* 4x Raspberry Pi cameras each with an independent MIPI capture pipeline that writes to the DDR
* Video Mixer based display pipeline that writes to the DisplayPort live interface of the ZynqMP
* Video Codec Unit ([VCU])
* DMA for PCIe ([XDMA])

The block diagram below illustrates the design from the top level.

![ZynqMP Hailo AI architecture](images/zynqmp-hailo-ai-arch.png)
    
### Capture pipeline

There are four main capture/input pipelines in this design, one for each of the 4x Raspberry Pi cameras. 
The capture pipelines are composed of the following IP, implemented in the PL of the Zynq UltraScale+:

* [MIPI CSI-2 Receiver Subsystem IP](https://docs.xilinx.com/r/en-US/pg232-mipi-csi2-rx)
* [AXI4-Stream Data FIFO](https://docs.amd.com/r/en-US/pg085-axi4stream-infrastructure/AXI4-Stream-Data-FIFO)
* [ISP Pipeline of the Vitis Libraries](https://github.com/Xilinx/Vitis_Libraries/tree/main/vision/L3/examples/isppipeline)
* [Video Processing Subsystem IP](https://docs.xilinx.com/r/en-US/pg231-v-proc-ss)
* [Frame Buffer Write IP](https://docs.xilinx.com/r/en-US/pg278-v-frmbuf)

The MIPI CSI-2 RX IP is the front of the pipeline and receives image frames from the Raspberry Pi camera 
over the 2-lane MIPI interface. The MIPI IP generates an AXI-Streaming output of the frames in RAW10 format. The 
ISP Pipeline IP performs BPC (Bad Pixel Correction), gain control, demosaicing and auto white balance, to output 
the image frames in RGB888 format. The Video Processing Subsystem IP performs scaling and color space conversion 
(when needed). The Frame Buffer Write IP then writes the frame data to memory (DDR). The image below illustrates 
the MIPI pipeline. 

![Video pipe sub-block diagram](images/zynqmp-hailo-ai-mipi.png)

### End-to-end pipeline

The end-to-end pipeline shows an example of the flow of image frames through the entire system, from source to sink.
In the diagram, the image resolutions and pixel formats are shown at each interface between the image processing
blocks. The resolution and pixel format can be dynamically changed at the output of the RPi camera and the scaler 
(Video Processing Subsystem IP).

![End-to-end pipeline](images/zynqmp-hailo-ai-end-to-end.png)

### Video Codec Unit

For some of the target boards, the Zynq UltraScale+ device contains a hardened Video Codec Unit (VCU) that can be used to
perform video encoding and decoding of multiple video standards. On those target designs, we have included the VCU to 
enable these powerful features. Refer to the list of target designs to see which boards support this feature.


[AMD Xilinx MIPI CSI Controller Subsystem IP]: https://docs.xilinx.com/r/en-US/pg202-mipi-dphy
[RPi Camera FMC]: https://camerafmc.com/docs/rpi-camera-fmc/overview/
[FPGA Drive FMC Gen4]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/
[M.2 M-key Stack FMC]: https://www.fpgadrive.com/docs/m2-mkey-stack-fmc/overview/
[Hailo-8 AI accelerator]: https://hailo.ai/products/ai-accelerators/hailo-8-m2-ai-acceleration-module/
[XDMA]: https://www.xilinx.com/products/intellectual-property/pcie-dma.html
[GStreamer]: https://gstreamer.freedesktop.org/
[VCU]: https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842546/Xilinx+Zynq+UltraScale+MPSoC+Video+Codec+Unit
[G-Streamer plugins]: https://xilinx.github.io/VVAS/2.0/build/html/docs/common/common_plugins.html

