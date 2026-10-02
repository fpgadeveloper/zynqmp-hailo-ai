# Requirements

In order to test this design on hardware, you will need the following:

* Vivado 2025.2
* Vitis 2025.2
* PetaLinux Tools 2025.2 (for the PetaLinux flow), or
  [Google's repo tool](https://gerrit.googlesource.com/git-repo/) (for the Yocto flow)
* Linux PC or Virtual machine (for the Linux builds)
* 1x [Hailo-8 M.2 AI Acceleration Module](https://hailo.ai/products/ai-accelerators/hailo-8-m2-ai-acceleration-module/)
* One or more [Raspberry Pi Camera Module 2]
* 1x [RPi Camera FMC]
* 1x [FPGA Drive FMC Gen4] (for `zcu106` target design only)
* 1x [M.2 M-key Stack FMC] (for all other designs)
* One DisplayPort monitor that supports 1920x1080 at 60 Hz (the design outputs this mode)
* Alternatively: an HDMI monitor that supports 1920x1080 at 60 Hz and a DP-to-HDMI adapter
* A microSD card (8 GB or more) and a card reader
* Optional, on the `zcu106_hpc0` and `uzev` targets only: a second Hailo-8 M.2 module or
  an M.2 NVMe SSD for the second M.2 slot
* One of the supported carrier boards listed below

## List of supported boards

{% set unique_boards = {} %}
{% for design in data.designs %}
	{% if design.publish %}
	    {% if design.board not in unique_boards %}
	        {% set _ = unique_boards.update({design.board: {"group": design.group, "link": design.link, "connectors": []}}) %}
	    {% endif %}
	    {% if design.connector not in unique_boards[design.board]["connectors"] %}
	    	{% set _ = unique_boards[design.board]["connectors"].append(design.connector) %}
	    {% endif %}
	{% endif %}
{% endfor %}

{% for group in data.groups %}
    {% set boards_in_group = [] %}
    {% for name, board in unique_boards.items() %}
        {% if board.group == group.label %}
            {% set _ = boards_in_group.append(board) %}
        {% endif %}
    {% endfor %}

    {% if boards_in_group | length > 0 %}
### {{ group.name }} boards

| Carrier board        | Supported FMC connector(s)    |
|---------------------|--------------|
{% for name,board in unique_boards.items() %}{% if board.group == group.label %}| [{{ name }}]({{ board.link }}) | {% for connector in board.connectors %}{{ connector }} {% endfor %} |
{% endif %}{% endfor %}
{% endif %}
{% endfor %}

For list of the target designs showing the number of cameras and M.2 slots supported, refer to the build instructions.

## Supported cameras

The [RPi Camera FMC] is designed to support all cameras with the standard
[15-pin Raspberry Pi camera interface](https://camerafmc.com/docs/rpi-camera-fmc/detailed-description/#camera-connectors),
however these example designs currently only have the software support for the [Raspberry Pi Camera Module 2].

```{tip}
We're working on developing software support for more cameras. If you'd like to help with
this effort, your pull requests are more than welcome.
```

[RPi Camera FMC]: https://docs.opsero.com/op068/datasheet/overview/
[Digilent Pcam 5C]: https://digilent.com/shop/pcam-5c-5-mp-fixed-focus-color-camera-module/
[Raspberry Pi Camera Module 2]: https://www.raspberrypi.com/products/camera-module-v2/
[FPGA Drive FMC Gen4]: https://docs.opsero.com/op063/datasheet/overview/
[M.2 M-key Stack FMC]: https://docs.opsero.com/op073/datasheet/overview/

