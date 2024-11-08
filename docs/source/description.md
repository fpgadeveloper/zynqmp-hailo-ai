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

| Target board        | FMC Slot Used | Cameras | Active M.2 Slots | VCU | Accelerator |
|---------------------|---------------|---------|-----|-----|-----|
{% for design in data.designs %}{% if design.group == group.label and design.publish %}| [{{ design.board }}]({{ design.link }}) | {{ design.connector }} | {{ design.cams | length }} | {{ design.lanes | length }} | {% if design.vcu %} ✅ {% else %} ❌ {% endif %} | {% if design.accel %} ✅ {% else %} ❌ {% endif %} |
{% endif %}{% endfor %}
{% endif %}
{% endfor %}

## Software

These reference designs can be driven within a PetaLinux environment. 
The repository includes all necessary scripts and code to build the PetaLinux environment. The table 
below outlines the corresponding applications available in each environment:

| Environment      | Available Applications  |
|------------------|-------------------------|
| PetaLinux        | Built-in Linux commands<br>Additional tools: ethtool, phytool, iperf3 |

## Architecture

The block diagram below illustrates the design from the top level.

![ZynqMP Hailo AI architecture](images/zynqmp-hailo-ai-arch.png)
    
## Video pipe

The block diagram below illustrates the video pipe:

![Video pipe sub-block diagram](images/zynqmp-hailo-ai-mipi.png)

## End-to-end pipeline

The end-to-end pipeline shows the flow of image frames through the design from the source (cameras) to the sink (monitor).

![End-to-end pipeline](images/zynqmp-hailo-ai-end-to-end.png)

[RPi Camera FMC]: https://camerafmc.com/docs/rpi-camera-fmc/overview/
[FPGA Drive FMC Gen4]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/
[M.2 M-key Stack FMC]: https://www.fpgadrive.com/docs/m2-mkey-stack-fmc/overview/
[Hailo-8 AI accelerator]: https://hailo.ai/products/ai-accelerators/hailo-8-m2-ai-acceleration-module/

