#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Opsero Electronic Design Inc.
"""
Generate the block diagrams for the Multi-camera ZynqMP Hailo AI reference design docs.

Three PNGs are written next to this script (i.e. into docs/source/images/):

  zynqmp-hailo-ai-arch.png        top-level architecture: 4 MIPI capture pipelines
                                  (CSI-2 RX -> FIFO -> ISP -> VPSS -> frame buffer write)
                                  into DDR, the Video Mixer display pipeline to the
                                  DisplayPort live input, one or two XDMA PCIe root ports
                                  (AXI Bridge mode) to the M.2 slots, the VCU, and the
                                  Zynq UltraScale+ PS ports each block uses.
  zynqmp-hailo-ai-end-to-end.png  the path of a camera frame through the Hailo demo
                                  (hailodemo.sh): resolutions and formats at each stage.
  zynqmp-hailo-ai-targets.png     how each target design connects the M.2 slots: FMC
                                  connector, GT quad, root ports and link width.

Everything drawn here follows Vivado/src/bd/bd_zynqmp.tcl, config/data.json and the
initcams scripts (init_cams.sh / hailodemo.sh) of the BSPs. If you change the block
design, update this script and re-run it.

Usage (from anywhere):
    python3 docs/source/images/gen_block_diagram.py
"""

import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, FancyBboxPatch

# ---- palette (shared with the other Opsero reference-design block diagrams) --
C_PS_FILL      = "#D9D9D9"; C_PS_EDGE      = "#7F7F7F"   # processor / DDR column
C_FAB_FILL     = "#F2F2F2"; C_FAB_EDGE     = "#BFBFBF"   # FPGA fabric container
C_MAC_FILL     = "#E8E8F2"; C_MAC_EDGE     = "#8C8CC0"   # PL IP (lavender)
C_GT_FILL      = "#F3EFE2"; C_GT_EDGE      = "#BFB585"   # hard blocks: GTH, VCU (cream)
C_FMC_FILL     = "#DCE6F2"; C_FMC_EDGE     = "#9DB7D4"   # external FMC (blue-grey)
C_CAGE_FILL    = "#FFFFFF"                                # devices on the FMC (white)
C_CLK_FILL     = "#FDE9D9"; C_CLK_EDGE     = "#E0B090"   # clocking (peach)
C_CTRL_FILL    = "#ECECEC"; C_CTRL_EDGE    = "#BFBFBF"   # control-plane caption
C_AXARR_FILL   = "#EDF3D4"; C_AXARR_EDGE   = "#A6B85A"   # AXI data arrows (pale green)
C_LINKARR_FILL = "#DAE8F5"; C_LINKARR_EDGE = "#6F9FCF"   # serial link arrows (pale blue)
TXT = "#1A1A1A"
# additions for this design
C_AI_FILL      = "#E4F0D0"; C_AI_EDGE      = "#7F9A2E"   # Hailo-8 / inference (green)
C_CPU_FILL     = "#FBF7E6"; C_CPU_EDGE     = "#D9C27A"   # software on the Cortex-A53
C_MUTED        = "#8C8C8C"                                # optional / not connected
C_NOTE         = "#404040"


def box(ax, x, y, w, h, fc, ec, label, fs=10, rot=0, lw=1.2, weight="normal",
        txtcolor=None, ls="-", z=2):
    ax.add_patch(plt.Rectangle((x, y), w, h, fc=fc, ec=ec, lw=lw, ls=ls, zorder=z))
    if label:
        ax.text(x + w / 2, y + h / 2, label, ha="center", va="center",
                fontsize=fs, rotation=rot, color=txtcolor or TXT, weight=weight,
                zorder=z + 1, linespacing=1.25)


def titled_box(ax, x, y, w, h, fc, ec, title, body, title_fs=9.5, body_fs=7.6,
               lw=1.2, txtcolor=None, title_dy=2.6, ls="-", z=2):
    """A box() with a bold title line at the top and a smaller body below it."""
    box(ax, x, y, w, h, fc, ec, "", lw=lw, ls=ls, z=z)
    cx = x + w / 2
    ax.text(cx, y + h - title_dy, title, ha="center", va="center",
            fontsize=title_fs, weight="bold", color=txtcolor or TXT, zorder=z + 1,
            linespacing=1.2)
    if body:
        ax.text(cx, y + (h - title_dy * 1.9) / 2, body, ha="center", va="center",
                fontsize=body_fs, color=txtcolor or TXT, zorder=z + 1,
                linespacing=1.3)


def harrow(ax, x0, x1, yc, label, fc, ec, double=False, bh=1.2, hh=2.2, hl=1.6,
           fs=7.4, lw=1.1, lab_dy=0.0, lab_color=None, ls="-"):
    """Horizontal block arrow from x0 to x1 (head at x1; both ends if double)."""
    if double:
        pts = [(x0, yc), (x0 + hl, yc + hh), (x0 + hl, yc + bh),
               (x1 - hl, yc + bh), (x1 - hl, yc + hh), (x1, yc),
               (x1 - hl, yc - hh), (x1 - hl, yc - bh),
               (x0 + hl, yc - bh), (x0 + hl, yc - hh)]
    else:
        s = 1.0 if x1 >= x0 else -1.0
        neck = x1 - s * hl
        pts = [(x0, yc + bh), (neck, yc + bh), (neck, yc + hh),
               (x1, yc), (neck, yc - hh), (neck, yc - bh), (x0, yc - bh)]
    ax.add_patch(Polygon(pts, closed=True, fc=fc, ec=ec, lw=lw, ls=ls, zorder=2))
    if label:
        ax.text((x0 + x1) / 2, yc + lab_dy, label, ha="center", va="center",
                fontsize=fs, color=lab_color or TXT, zorder=3, linespacing=1.15)


def varrow(ax, xc, y0, y1, fc, ec, double=False, bw=1.0, hw=2.0, hl=1.6, lw=1.1):
    """Vertical block arrow from y0 to y1 (head at y1; both ends if double)."""
    if double:
        lo, hi = min(y0, y1), max(y0, y1)
        pts = [(xc, lo), (xc + hw, lo + hl), (xc + bw, lo + hl),
               (xc + bw, hi - hl), (xc + hw, hi - hl), (xc, hi),
               (xc - hw, hi - hl), (xc - bw, hi - hl),
               (xc - bw, lo + hl), (xc - hw, lo + hl)]
    else:
        s = 1.0 if y1 >= y0 else -1.0
        neck = y1 - s * hl
        pts = [(xc - bw, y0), (xc - bw, neck), (xc - hw, neck), (xc, y1),
               (xc + hw, neck), (xc + bw, neck), (xc + bw, y0)]
    ax.add_patch(Polygon(pts, closed=True, fc=fc, ec=ec, lw=lw, zorder=2))


def legend(ax, x, y, items, fs=7.6, sw=4.0, sh=2.4, gap=17.5):
    """One row of colour swatches with captions."""
    for i, (fc, ec, lab, ls) in enumerate(items):
        xx = x + i * gap
        ax.add_patch(plt.Rectangle((xx, y), sw, sh, fc=fc, ec=ec, lw=1.1, ls=ls,
                                   zorder=3))
        ax.text(xx + sw + 1.0, y + sh / 2, lab, ha="left", va="center",
                fontsize=fs, color=TXT, zorder=3)


def save(fig, name):
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), name)
    fig.savefig(out, bbox_inches="tight", pad_inches=0.15, facecolor="white")
    plt.close(fig)
    print("wrote", out)


# =============================================================================
# 1. Top-level architecture
# =============================================================================
def arch():
    fig, ax = plt.subplots(figsize=(19.0, 12.6), dpi=110)
    ax.set_xlim(0, 190)
    ax.set_ylim(0, 126)
    ax.axis("off")

    # ---- external column (left): cameras, RPi Camera FMC, M.2 FMC ---------------
    ax.text(18.5, 123.0, "External to the Zynq UltraScale+", ha="center",
            va="bottom", fontsize=11.5, weight="bold", color=TXT)
    cam_ys = [109.0, 100.0, 91.0, 82.0]
    for i, y in enumerate(cam_ys):
        box(ax, 2.0, y, 15.0, 7.0, C_CAGE_FILL, C_FMC_EDGE,
            f"RPi Camera v2\n(IMX219)  CAM{i}", fs=7.4)
    box(ax, 21.0, 81.0, 12.5, 36.0, C_FMC_FILL, C_FMC_EDGE,
        "RPi Camera FMC\n(OP068)", fs=8.6, rot=90, weight="bold")
    for y in cam_ys:
        harrow(ax, 17.0, 21.0, y + 3.5, "", C_LINKARR_FILL, C_LINKARR_EDGE,
               bh=0.8, hh=1.6, hl=1.2)
    ax.text(17.8, 78.6, "CAM1 + CAM2 only on pynqzu", ha="center", va="center",
            fontsize=6.8, color=C_NOTE, style="italic")

    # M.2 carrier card(s)
    box(ax, 2.0, 30.0, 31.5, 42.0, C_FMC_FILL, C_FMC_EDGE, "", lw=1.3)
    ax.text(17.75, 67.6, "M.2 M-key Stack FMC (OP073)\nor FPGA Drive FMC Gen4\n"
            "(OP063, zcu106 target)", ha="center", va="center", fontsize=7.8,
            weight="bold", color=TXT, linespacing=1.25)
    titled_box(ax, 4.0, 47.0, 27.5, 13.0, C_AI_FILL, C_AI_EDGE,
               "M.2 slot 1", "Hailo-8 M.2 AI module\n(26 TOPS, PCIe Gen3 x4)",
               title_fs=8.4, body_fs=7.2, title_dy=2.4)
    titled_box(ax, 4.0, 32.0, 27.5, 13.0, C_CAGE_FILL, C_MUTED,
               "M.2 slot 2  (x4 targets only)",
               "second Hailo-8\nor NVMe SSD", title_fs=8.0, body_fs=7.2,
               title_dy=2.4, ls=(0, (4, 2)))

    # monitor + network (right, external)
    titled_box(ax, 170.0, 59.5, 18.0, 15.0, C_CAGE_FILL, C_FMC_EDGE,
               "Monitor", "DisplayPort\n(or DP-to-HDMI)\n1920x1080 @ 60 Hz",
               title_fs=8.6, body_fs=7.0, title_dy=2.4)
    titled_box(ax, 170.0, 41.5, 18.0, 14.0, C_CAGE_FILL, C_FMC_EDGE,
               "Network", "board RJ45\n(PYNQ-ZU: on-board\nWi-Fi, Yocto image)",
               title_fs=8.6, body_fs=6.8, title_dy=2.4)

    # ---- programmable logic -------------------------------------------------------
    pl_x0, pl_x1 = 37.0, 122.0
    ax.add_patch(plt.Rectangle((pl_x0, 2.0), pl_x1 - pl_x0, 119.0, fc=C_FAB_FILL,
                               ec=C_FAB_EDGE, lw=1.3, zorder=1))
    ax.text((pl_x0 + pl_x1) / 2, 123.0, "Programmable Logic (PL)", ha="center",
            va="bottom", fontsize=11.5, weight="bold", color=TXT)

    # MIPI capture pipelines
    stage_w, stage_gap = 12.2, 1.2
    stages = ["MIPI CSI-2\nRX (2-lane)", "AXIS\nFIFO", "ISP\nPipeline",
              "VPSS\nscaler + CSC", "Frame Buffer\nWrite"]
    for i, y in enumerate(cam_ys):
        x = 39.5
        for j, s in enumerate(stages):
            box(ax, x, y, stage_w, 7.0, C_MAC_FILL, C_MAC_EDGE, s, fs=6.6)
            if j < len(stages) - 1:
                harrow(ax, x + stage_w, x + stage_w + stage_gap, y + 3.5, "",
                       C_AXARR_FILL, C_AXARR_EDGE, bh=0.5, hh=1.1, hl=0.6)
            x += stage_w + stage_gap
        harrow(ax, 33.5, 39.5, y + 3.5, "", C_LINKARR_FILL, C_LINKARR_EDGE,
               bh=0.8, hh=1.6, hl=1.2)
        ax.text(36.2, y + 6.1, "D-PHY", ha="center", va="center", fontsize=5.8,
                color=C_NOTE)
    ax.text(79.0, 118.6, f"MIPI pipeline  mipi_N  (one per camera, N = 0..3)  —  "
            "RAW10 → RGB → YUY2 / NV12 into DDR", ha="center", va="center",
            fontsize=7.6, color=C_NOTE)
    sc_x = 107.0
    box(ax, sc_x, 82.0, 11.0, 34.0, C_MAC_FILL, C_MAC_EDGE,
        "SmartConnect\n(smartconnect_cams)", fs=7.0, rot=90)
    for y in cam_ys:
        harrow(ax, 39.5 + 5 * (stage_w + stage_gap) - stage_gap, sc_x, y + 3.5,
               "", C_AXARR_FILL, C_AXARR_EDGE, bh=0.5, hh=1.1, hl=0.6)

    # display pipeline
    dy0 = 60.0
    titled_box(ax, 39.5, dy0, 78.5, 17.0, "#F7F7FB", C_MAC_EDGE,
               "display_pipeline", "", title_fs=8.6, title_dy=2.2, lw=1.4)
    titled_box(ax, 41.5, dy0 + 1.5, 23.0, 11.5, C_MAC_FILL, C_MAC_EDGE,
               "Video Mixer", "6 layers: 4x YUYV (cameras),\n1x RGBA + alpha, "
               "1x NV16\nYUV 4:2:2 out, max 3840x2160", title_fs=8.0, body_fs=6.4,
               title_dy=2.0)
    titled_box(ax, 67.5, dy0 + 1.5, 15.5, 11.5, C_MAC_FILL, C_MAC_EDGE,
               "AXIS to\nVideo Out", "\n\n8-bit YUV 4:2:2",
               title_fs=7.6, body_fs=6.4, title_dy=3.0)
    titled_box(ax, 86.0, dy0 + 1.5, 13.0, 11.5, C_MAC_FILL, C_MAC_EDGE,
               "VTC", "video timing\n(1080p)", title_fs=8.0, body_fs=6.4,
               title_dy=2.0)
    titled_box(ax, 102.0, dy0 + 1.5, 14.5, 11.5, C_CLK_FILL, C_CLK_EDGE,
               "Clocking\nWizard", "\n\npixel clock\n148.5 MHz",
               title_fs=7.6, body_fs=6.4, title_dy=3.0)
    harrow(ax, 64.5, 67.5, dy0 + 7.2, "", C_AXARR_FILL, C_AXARR_EDGE,
           bh=0.6, hh=1.2, hl=0.8)
    harrow(ax, 86.0, 83.0, dy0 + 7.2, "", C_CTRL_FILL, C_PS_EDGE,
           bh=0.5, hh=1.1, hl=0.8)

    # PCIe root ports
    py0 = 31.0
    titled_box(ax, 39.5, py0 + 13.5, 52.0, 12.5, C_MAC_FILL, C_MAC_EDGE,
               "xdma_0  —  DMA/Bridge Subsystem for PCIe",
               "PCIe Root Port (AXI Bridge mode), Gen3 8 GT/s\n"
               "x1 (zcu104, zcu106, pynqzu) or x4 (zcu106_hpc0, uzev)",
               title_fs=7.8, body_fs=6.7, title_dy=2.2)
    titled_box(ax, 39.5, py0, 52.0, 12.0, C_CAGE_FILL, C_MUTED,
               "xdma_1  —  second root port  (zcu106_hpc0, uzev only)",
               "PCIe Root Port (AXI Bridge mode), Gen3 x4",
               title_fs=7.8, body_fs=6.7, title_dy=2.2, ls=(0, (4, 2)))
    titled_box(ax, 95.0, py0, 11.0, 26.0, C_GT_FILL, C_GT_EDGE,
               "GTH", "\nquad(s)\nper\ntarget", title_fs=8.4, body_fs=6.6,
               title_dy=2.4)
    harrow(ax, 91.5, 95.0, py0 + 19.7, "", C_LINKARR_FILL, C_LINKARR_EDGE,
           double=True, bh=0.7, hh=1.4, hl=0.9)
    harrow(ax, 91.5, 95.0, py0 + 6.0, "", C_LINKARR_FILL, C_LINKARR_EDGE,
           double=True, bh=0.7, hh=1.4, hl=0.9, ls=(0, (3, 2)))
    titled_box(ax, 108.5, py0, 11.5, 26.0, "#F0F0F0", C_CTRL_EDGE,
               "AXI IC", "\nperiph_\nintercon_0\n+ DMA\ninterconnect",
               title_fs=7.6, body_fs=6.2, title_dy=2.4)
    harrow(ax, 106.0, 108.5, py0 + 13.0, "", C_AXARR_FILL, C_AXARR_EDGE,
           double=True, bh=0.6, hh=1.2, hl=0.8)
    # GT <-> M.2 slots (serial lanes through the FMC connector)
    harrow(ax, 31.5, 39.5, 53.5, "", C_LINKARR_FILL, C_LINKARR_EDGE,
           double=True, bh=0.9, hh=1.8, hl=1.2)
    harrow(ax, 31.5, 39.5, 38.5, "", C_LINKARR_FILL, C_LINKARR_EDGE,
           double=True, bh=0.9, hh=1.8, hl=1.2, ls=(0, (3, 2)))
    ax.text(35.5, 57.6, "FMC\nGT", ha="center", va="center", fontsize=5.8,
            color=C_NOTE, linespacing=1.1)
    ax.text(65.5, py0 - 2.4, "BAR window: 0xB000_0000 (256 MB, 32-bit, "
            "non-prefetchable)  —  two root ports: 128 MB each",
            ha="center", va="center", fontsize=6.7, color=C_NOTE)

    # VCU (hard block in the PL column)
    titled_box(ax, 39.5, 6.0, 52.0, 15.0, C_GT_FILL, C_GT_EDGE,
               "VCU  —  Video Codec Unit (hard block)",
               "H.264 / H.265 encode + decode\nnot present on pynqzu (ZU5EG)",
               title_fs=8.0, body_fs=6.8, title_dy=2.3, ls=(0, (4, 2)))
    titled_box(ax, 95.0, 4.0, 25.0, 11.0, C_CLK_FILL, C_CLK_EDGE,
               "clk_wiz_0  (from pl_clk0)",
               "50/100/200/250/300 MHz\n250 MHz: video + PCIe AXI",
               title_fs=7.4, body_fs=6.3, title_dy=2.1)

    # ---- processing system ---------------------------------------------------------
    ps_x0, ps_x1 = 126.0, 165.0
    ax.add_patch(plt.Rectangle((ps_x0, 2.0), ps_x1 - ps_x0, 119.0, fc=C_PS_FILL,
                               ec=C_PS_EDGE, lw=1.3, zorder=1))
    ax.text((ps_x0 + ps_x1) / 2, 123.0, "Processing System (PS)", ha="center",
            va="bottom", fontsize=11.5, weight="bold", color=TXT)
    port_x, port_w = 127.5, 18.0

    def port(y, lab):
        box(ax, port_x, y - 2.5, port_w, 5.0, "#FFFFFF", C_PS_EDGE, lab, fs=6.9)

    port(99.0, "S_AXI_HPC0_FPD")
    harrow(ax, sc_x + 11.0, port_x, 99.0, "", C_AXARR_FILL, C_AXARR_EDGE,
           bh=1.2, hh=2.2, hl=1.4)
    ax.text(122.4, 102.6, "frames", ha="center", va="center", fontsize=6.4,
            color=C_NOTE)
    port(70.5, "S_AXI_HP3_FPD")
    harrow(ax, port_x, 118.0, 70.5, "", C_AXARR_FILL, C_AXARR_EDGE,
           bh=1.2, hh=2.2, hl=1.4)
    ax.text(122.4, 74.0, "layers", ha="center", va="center", fontsize=6.4,
            color=C_NOTE)
    port(62.5, "DP live video in")
    harrow(ax, 118.0, port_x, 62.5, "", C_LINKARR_FILL, C_LINKARR_EDGE,
           bh=1.0, hh=2.0, hl=1.4)
    port(49.0, "S_AXI_HP0_FPD")
    harrow(ax, 120.0, port_x, 49.0, "", C_AXARR_FILL, C_AXARR_EDGE,
           bh=1.2, hh=2.2, hl=1.4)
    ax.text(123.8, 52.4, "PCIe DMA", ha="center", va="center", fontsize=6.0,
            color=C_NOTE)
    port(38.0, "M_AXI_HPM1_FPD")
    harrow(ax, port_x, 120.0, 38.0, "", C_CTRL_FILL, C_PS_EDGE,
           bh=1.2, hh=2.2, hl=1.4)
    ax.text(123.8, 41.4, "BAR + ctrl", ha="center", va="center", fontsize=6.0,
            color=C_NOTE)
    port(18.0, "S_AXI_HP1/HP2_FPD\n+ S_AXI_LPD")
    harrow(ax, 91.5, port_x, 18.0, "", C_AXARR_FILL, C_AXARR_EDGE,
           bh=1.0, hh=2.0, hl=1.4)
    port(8.5, "M_AXI_HPM0_FPD/LPD")
    ax.text(110.0, 26.2, "AXI-Lite control of every PL IP: HPM0_LPD (100 MHz) and "
            "HPM0_FPD (250 MHz)", ha="center", va="center", fontsize=6.2,
            color=C_NOTE)

    # PS internals: CPU, DP, GEM, DDR
    titled_box(ax, 147.0, 84.0, 16.5, 31.0, "#FFFFFF", C_PS_EDGE,
               "Cortex-A53", "\nLinux\n(PetaLinux or\nYocto / EDF)\n\nV4L2, DRM,\n"
               "GStreamer,\nHailoRT 4.23.0,\nhailo_pci driver", title_fs=8.4,
               body_fs=6.6, title_dy=2.4)
    titled_box(ax, 147.0, 58.0, 16.5, 18.0, "#FFFFFF", C_PS_EDGE,
               "DisplayPort\n(DPSUB)", "\n\nlive input\nblended, to the\nDP connector",
               title_fs=7.8, body_fs=6.4, title_dy=3.2)
    harrow(ax, port_x + port_w, 147.0, 62.5, "", C_LINKARR_FILL, C_LINKARR_EDGE,
           bh=1.0, hh=2.0, hl=1.2)
    harrow(ax, 163.5, 170.0, 67.0, "", C_LINKARR_FILL, C_LINKARR_EDGE,
           bh=1.0, hh=2.0, hl=1.4)
    titled_box(ax, 147.0, 44.0, 16.5, 9.0, "#FFFFFF", C_PS_EDGE, "GEM",
               "Gigabit Ethernet", title_fs=7.6, body_fs=6.4, title_dy=2.2)
    harrow(ax, 163.5, 170.0, 48.5, "", C_LINKARR_FILL, C_LINKARR_EDGE,
           double=True, bh=0.8, hh=1.6, hl=1.0)
    titled_box(ax, 147.0, 4.0, 16.5, 36.0, C_PS_FILL, C_PS_EDGE, "DDR4",
               "\nframe buffers,\nCMA (cma=1536M;\nuzev 1000M),\n\nHailo DMA\nbuffers",
               title_fs=9.6, body_fs=6.6, title_dy=2.6, lw=1.3)

    legend(ax, 2.0, 1.0, [
        (C_MAC_FILL, C_MAC_EDGE, "PL IP", "-"),
        (C_GT_FILL, C_GT_EDGE, "hard block (GTH, VCU)", "-"),
        (C_FMC_FILL, C_FMC_EDGE, "Opsero FMC", "-"),
        (C_AI_FILL, C_AI_EDGE, "Hailo-8", "-"),
        (C_CAGE_FILL, C_MUTED, "only on some targets", (0, (4, 2))),
    ], gap=21.0)
    save(fig, "zynqmp-hailo-ai-arch.png")


# =============================================================================
# 2. End-to-end frame path of the Hailo demo
# =============================================================================
def end_to_end():
    fig, ax = plt.subplots(figsize=(19.0, 6.6), dpi=110)
    ax.set_xlim(0, 190)
    ax.set_ylim(-3, 66)
    ax.axis("off")

    ax.text(95.0, 64.0, "One camera branch of hailodemo.sh  (repeated for every "
            "connected camera, up to 4)", ha="center", va="center", fontsize=11,
            weight="bold", color=TXT)

    y0, h = 30.0, 16.0
    yc = y0 + h / 2
    blocks = [
        ("IMX219\ncamera", "", C_CAGE_FILL, C_FMC_EDGE, 10.0),
        ("MIPI CSI-2\nRX", "PL", C_MAC_FILL, C_MAC_EDGE, 12.0),
        ("ISP\nPipeline", "PL\nBPC, gain,\ndemosaic,\nAWB, gamma", C_MAC_FILL,
         C_MAC_EDGE, 13.0),
        ("VPSS", "PL\nscale + CSC", C_MAC_FILL, C_MAC_EDGE, 11.0),
        ("Frame\nBuffer Wr", "PL → DDR", C_MAC_FILL, C_MAC_EDGE, 11.0),
        ("synchailonet", "GStreamer\nHailo-8\nYOLOv5m\n(PCIe)", C_AI_FILL,
         C_AI_EDGE, 14.0),
        ("hailofilter", "A53\nYOLO decode\n+ NMS", C_CPU_FILL, C_CPU_EDGE,
         13.0),
        ("hailo-\noverlay", "A53\ndraws\nboxes", C_CPU_FILL, C_CPU_EDGE, 11.0),
        ("kmssink", "A53\nplane =\nmixer layer", C_CPU_FILL, C_CPU_EDGE, 11.0),
        ("Video\nMixer", "PL\nscales to\nquadrant", C_MAC_FILL, C_MAC_EDGE, 11.0),
        ("DP live\n+ DPSUB", "PS", C_PS_FILL, C_PS_EDGE, 11.0),
        ("Monitor", "", C_CAGE_FILL, C_FMC_EDGE, 9.5),
    ]
    labels = ["MIPI 2-lane\n1920x1080\nRAW10", "RAW10\n1920x1080",
              "RGB 8-bit\n1920x1080", "YUY2\n1280x720", "YUY2 1280x720\n25 fps\n(/dev/videoN)",
              "frame +\nraw tensors", "frame +\ndetections", "YUY2 1280x720\n+ boxes",
              "DMA-BUF", "YUV 4:2:2\n1920x1080", "DP\n1080p60"]
    gap = 3.4
    total = sum(b[4] for b in blocks) + gap * (len(blocks) - 1)
    x = (190.0 - total) / 2
    xs = []
    for (title, body, fc, ec, w) in blocks:
        titled_box(ax, x, y0, w, h, fc, ec, title, body, title_fs=7.8,
                   body_fs=6.3, title_dy=3.0)
        xs.append((x, w))
        x += w + gap
    for i in range(len(blocks) - 1):
        xa = xs[i][0] + xs[i][1]
        xb = xs[i + 1][0]
        harrow(ax, xa, xb, yc, "", C_AXARR_FILL, C_AXARR_EDGE, bh=0.7, hh=1.5,
               hl=1.2)
        ax.text((xa + xb) / 2, y0 + h + 5.6, labels[i], ha="center", va="center",
                fontsize=6.3, color=C_NOTE, linespacing=1.2)

    # brackets: what runs where
    def bracket(i0, i1, text, y, color):
        xa = xs[i0][0]
        xb = xs[i1][0] + xs[i1][1]
        ax.add_line(plt.Line2D([xa, xa, xb, xb], [y + 2.0, y, y, y + 2.0],
                               color=color, lw=1.6, zorder=2))
        ax.text((xa + xb) / 2, y - 3.2, text, ha="center", va="center",
                fontsize=7.8, color=color, weight="bold", linespacing=1.25)

    bracket(1, 4, "capture pipeline in the PL, set up by init_cams.sh / media-ctl\n"
            "(camera 1920x1080 → VPSS 1280x720 YUY2, 25 fps in the demo)", 24.0,
            "#5A5AA0")
    bracket(5, 8, "GStreamer pipeline on the Cortex-A53 (one branch per camera)\n"
            "synchailonet sends each frame to the Hailo-8 over PCIe", 24.0,
            "#5E7A1E")
    bracket(9, 10, "display: 1920x1080 @ 60 Hz,\neach camera in a 960x540 quadrant",
            24.0, "#5A5AA0")

    # bottom notes
    notes = (
        "• The bundled network is yolov5m_wo_spp_yuy2.hef (YOLOv5m, 80 COCO classes, "
        "1280x720 YUY2 input). On its own it runs at about 150 FPS on the Hailo-8 "
        "(hailortcli run), at both x1 and x4 link widths: the Hailo-8 compute, not "
        "the PCIe link, sets the rate.\n"
        "• Four cameras at 25 fps use 100 of those frames per second. A single camera "
        "branch without the display (fakesink) runs at the full camera rate of about "
        "30 fps.\n"
        "• The Video Mixer reads each camera layer from DDR and scales it from 1280x720 "
        "into its 960x540 quadrant of the 1920x1080 screen."
    )
    ax.text(4.0, 9.0, notes, ha="left", va="center", fontsize=7.8, color=TXT,
            linespacing=1.6)
    legend(ax, 4.0, -2.5, [
        (C_CAGE_FILL, C_FMC_EDGE, "external", "-"),
        (C_MAC_FILL, C_MAC_EDGE, "PL IP", "-"),
        (C_AI_FILL, C_AI_EDGE, "Hailo-8 (over PCIe)", "-"),
        (C_CPU_FILL, C_CPU_EDGE, "software on the A53", "-"),
        (C_PS_FILL, C_PS_EDGE, "PS hard IP", "-"),
    ], gap=24.0)
    save(fig, "zynqmp-hailo-ai-end-to-end.png")


# =============================================================================
# 3. PCIe / M.2 connection per target design
# =============================================================================
def targets():
    fig, ax = plt.subplots(figsize=(19.0, 13.4), dpi=110)
    ax.set_xlim(0, 190)
    ax.set_ylim(-4, 130)
    ax.axis("off")

    cols = [(2.0, 30.0, "Target design"), (35.0, 38.0, "Zynq UltraScale+ PL"),
            (78.0, 16.0, "FMC connector"), (99.0, 58.0, "M.2 adapter + M.2 slots"),
            (161.0, 27.0, "RPi Camera FMC")]
    for x, w, t in cols:
        ax.text(x + w / 2, 127.0, t, ha="center", va="center", fontsize=10.5,
                weight="bold", color=TXT)

    rows = [
        dict(t="zcu104", b="ZCU104", conn="LPC", rps=[("xdma_0", "GTH quad 226", "x1")],
             card="M.2 M-key Stack FMC (OP073)", slots=["hailo", "nc_lanes"],
             cam="stacked on the M.2\nM-key Stack FMC\n4 cameras",
             note="LPC: one GT lane (DP0)"),
        dict(t="pynqzu", b="PYNQ-ZU", conn="LPC", rps=[("xdma_0", "GTH quad 224", "x1")],
             card="M.2 M-key Stack FMC (OP073)", slots=["hailo", "nc_lanes"],
             cam="stacked on the M.2\nM-key Stack FMC\nCAM1 + CAM2 only",
             note="GT refclk through the board's\nSi5324 jitter attenuator"),
        dict(t="zcu106_hpc0", b="ZCU106", conn="HPC0",
             rps=[("xdma_0", "GTH quad 226", "x4"), ("xdma_1", "GTH quad 227", "x4")],
             card="M.2 M-key Stack FMC (OP073)", slots=["hailo", "either"],
             cam="stacked on the M.2\nM-key Stack FMC\n4 cameras", note=""),
        dict(t="uzev", b="UltraZed-EV\nCarrier", conn="HPC",
             rps=[("xdma_0", "GTH quad 225", "x4"), ("xdma_1", "GTH quad 224", "x4")],
             card="M.2 M-key Stack FMC (OP073)", slots=["hailo", "either"],
             cam="stacked on the M.2\nM-key Stack FMC\n4 cameras", note=""),
        dict(t="zcu106", b="ZCU106", conn="HPC1", rps=[("xdma_0", "GTH quad 223", "x1")],
             card="FPGA Drive FMC Gen4 (OP063)", slots=["hailo", "nc_hpc1"],
             cam="on its own connector:\nHPC0\n4 cameras",
             note="HPC1 has one GT lane"),
    ]
    rh, rgap = 21.0, 3.5
    y = 122.0
    for r in rows:
        y -= rh
        yc = y + rh / 2
        # target column
        titled_box(ax, 2.0, y, 30.0, rh, "#FFFFFF", C_PS_EDGE, r["t"],
                   f"{r['b']}\n\n"
                   + ("2 root ports, x4 each" if len(r["rps"]) == 2
                      else "1 root port, x1"),
                   title_fs=10.5, body_fs=7.6, title_dy=3.0)
        # root ports
        n = len(r["rps"])
        bh = (rh - 1.5 * (n - 1)) / n if n > 1 else rh * 0.62
        ry = [y + rh - bh - i * (bh + 1.5) for i in range(n)] if n > 1 \
            else [y + (rh - bh) / 2]
        for (name, quad, width), yy in zip(r["rps"], ry):
            titled_box(ax, 35.0, yy, 38.0, bh, C_MAC_FILL, C_MAC_EDGE,
                       f"{name}: PCIe root port", f"{quad}  ·  Gen3 {width}",
                       title_fs=7.8, body_fs=7.0, title_dy=2.2)
        # FMC connector
        box(ax, 78.0, y, 16.0, rh, C_FMC_FILL, C_FMC_EDGE, r["conn"], fs=10,
            weight="bold")
        # adapter card with two slots
        box(ax, 99.0, y, 58.0, rh, C_FMC_FILL, C_FMC_EDGE, "", lw=1.2)
        ax.text(128.0, y + rh - 2.2, r["card"], ha="center", va="center",
                fontsize=8.0, weight="bold", color=TXT)
        sw, sh = 26.0, rh - 6.5
        s1x, s2x, sy = 101.0, 129.0, y + 1.5
        titled_box(ax, s1x, sy, sw, sh, C_AI_FILL, C_AI_EDGE, "Slot 1",
                   "Hailo-8 M.2\n(" + ("x4 link" if r["rps"][0][2] == "x4" else
                                       "x1 link") + ")",
                   title_fs=8.0, body_fs=7.0, title_dy=2.2)
        kind = r["slots"][1]
        if kind == "either":
            titled_box(ax, s2x, sy, sw, sh, C_CAGE_FILL, C_AI_EDGE, "Slot 2",
                       "second Hailo-8\nor NVMe SSD (x4)", title_fs=8.0,
                       body_fs=7.0, title_dy=2.2)
        else:
            msg = ("not connected:\nLPC has 1 GT lane" if kind == "nc_lanes" else
                   "not connected:\nHPC1 has 1 GT lane")
            titled_box(ax, s2x, sy, sw, sh, "#F4F4F4", C_MUTED, "Slot 2", msg,
                       title_fs=8.0, body_fs=7.0, title_dy=2.2, ls=(0, (4, 2)),
                       txtcolor=C_MUTED)
        # links: root port -> connector -> slot
        for i, yy in enumerate(ry):
            ly = yy + bh / 2
            harrow(ax, 73.0, 78.0, ly, "", C_LINKARR_FILL, C_LINKARR_EDGE,
                   double=True, bh=0.8, hh=1.6, hl=1.0)
        harrow(ax, 94.0, 101.0, sy + sh / 2, "", C_LINKARR_FILL, C_LINKARR_EDGE,
               double=True, bh=0.8, hh=1.6, hl=1.0)
        if kind == "either":
            ax.add_line(plt.Line2D([96.5, 96.5, 129.0], [sy + sh / 2, y + 0.6, y + 0.6],
                                   color=C_LINKARR_EDGE, lw=1.6, zorder=3))
            ax.add_line(plt.Line2D([129.0, 129.0], [y + 0.6, sy],
                                   color=C_LINKARR_EDGE, lw=1.6, zorder=3))
        # camera card
        titled_box(ax, 161.0, y, 27.0, rh, C_FMC_FILL, C_FMC_EDGE,
                   "RPi Camera FMC", r["cam"], title_fs=8.2, body_fs=7.2,
                   title_dy=2.4)
        if r["note"]:
            ax.text(17.0, y + 2.6, r["note"], ha="center", va="center",
                    fontsize=6.4, color=C_NOTE, style="italic", linespacing=1.15)
        y -= rgap

    ax.text(95.0, -1.5, "ZynqMP XDMA root ports run at most Gen3 (8 GT/s). The Hailo-8 "
            "module advertises x4, so on the x1 targets lspci reports "
            "\"Width x1 (downgraded)\": that is expected.", ha="center", va="center",
            fontsize=8.0, color=C_NOTE)
    save(fig, "zynqmp-hailo-ai-targets.png")


if __name__ == "__main__":
    arch()
    end_to_end()
    targets()
