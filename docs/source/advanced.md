# Advanced: project structure and customization

This section is intended for users who want to modify the reference
designs — adding IP to the block design, changing constraints, or
adding packages or drivers to the PetaLinux or Yocto project. It describes how
the repository is laid out, how the build flow works, how
the PetaLinux side is organised, and what modifications have been
added on top of the stock AMD BSPs and the upstream Hailo Yocto layer.

The actual *build* instructions are in [build_instructions](build_instructions);
this section is about understanding the project well enough to modify
it.

## Repository layout

```
.
├── build.py                   <- Cross-platform build runner (the build logic)
├── build.sh / build.bat       <- Shims that invoke build.py (Linux/git bash, Windows)
├── Makefile                   <- Deprecated thin wrapper around build.sh (removed next version)
├── README.md
├── config/                    <- Source-of-truth design metadata and auto-generation
│   ├── data.json
│   └── update.py
├── docs/                      <- This documentation (Sphinx + Read the Docs)
├── PetaLinux/
│   └── bsp/                   <- Per-board (and optional per-target) BSP fragments
│       └── pynqzu/, uzev/, zcu104/, zcu106/
├── Yocto/
│   ├── bsp/                   <- Per-board Yocto / EDF BSP layers (meta-user, local.conf.append)
│   │   └── pynqzu/, uzev/, zcu104/, zcu106/
│   └── scripts/               <- Workspace set-up, build and packaging helpers
├── submodules/
│   └── meta-hailo/            <- Hailo Yocto layer (git submodule, hailo8-scarthgap branch)
└── Vivado/
    ├── scripts/
    │   ├── build.tcl          <- Project creation + block design assembly
    │   └── xsa.tcl            <- Synthesis, implementation, XSA export
    └── src/
        ├── bd/
        │   ├── bd_zynqmp.tcl  <- Block design for Zynq UltraScale+ targets
        │   └── mipi_locs.tcl  <- Per-target MIPI lane placement constants
        └── constraints/
            └── <target>.xdc   <- One XDC per target (pin assignments, timing)
```

This repository has no `Vitis/` directory — all supported targets are
Linux-only (the Hailo accelerator runs from user-space on the
Linux side; there is no standalone equivalent).

Per-target build outputs are written to `Vivado/<target>/`,
`PetaLinux/<target>/` and `Yocto/<target>/`. None of these are committed.

The Vivado design is shared with [rpi-camera-fmc] in structure (same
`bd_name = rpi`, similar MIPI camera bring-up); this repository adds
the Hailo-8 (PCIe root ports to the M.2 slots) on top.

[rpi-camera-fmc]: https://github.com/fpgadeveloper/rpi-camera-fmc

## Target naming

A *target label* is the canonical handle for a single design and is passed
to every build command via `--target`:

```
<board>[_<connector>]
```

Examples: `uzev`, `pynqzu`, `zcu104`, `zcu106`, `zcu106_hpc0`. The
first underscore-delimited token is taken as the *target board* and is
what the build runner uses to select the BSP under
`PetaLinux/bsp/<board>/`.

The complete list of valid targets comes from `config/data.json`; run
`./build.sh list` to print it.

## `config/data.json` and `config/update.py`

`config/data.json` is the canonical source of truth for the set of
supported designs and their per-target metadata (board name, FMC
connector, supported cameras, PetaLinux support, etc.). The
`build.py` runner reads it directly at runtime, so the target list is
never hand-maintained.

`config/update.py` reads `data.json` and regenerates the auto-managed
documentation and metadata that is *not* read at runtime: the target
tables in the top-level `README.md`, the `.gitignore`, and the per-board
sections still embedded in `PetaLinux/Makefile` — each delimited by
`UPDATER START` / `UPDATER END` comment markers.

When adding or modifying a target, edit `data.json` and re-run
`update.py`. Do not hand-edit content between the `UPDATER START` /
`UPDATER END` markers; it will be overwritten on the next regeneration.

## Build runner

All build stages are driven by the cross-platform `build.py` runner at the
root of the repository, invoked through the `build.sh` shim on Linux / git
bash or `build.bat` on Windows (identical arguments). It reads the target
list and per-target attributes straight from `config/data.json`, builds
whatever a requested stage depends on automatically, skips anything already
built, and locates and sources the AMD tools itself — so there is no need to
source the Vivado / PetaLinux settings scripts beforehand.

The build is organised into stages, each available as a sub-command:

| Command      | Stage                                                                                          |
|--------------|------------------------------------------------------------------------------------------------|
| `project`    | Create the Vivado project (`.xpr`) and block design.                                           |
| `xsa`        | Synthesise, implement and export the hardware (`.xsa`).                                         |
| `petalinux`  | Create the PetaLinux project from the XSA, apply the BSP overlays, integrate `meta-hailo`, build and package. |
| `yocto`      | Set up the Yocto / EDF workspace, generate the System Device Tree from the XSA, add the BSP layer and `meta-hailo`, run bitbake and gather the images. |
| `package`    | Gather the built boot artifacts into `bootimages/*.zip`.                                        |
| `all`        | Build every stage the target supports, then `package`.                                         |

Run `./build.sh list` to see the targets and their attributes, `./build.sh
status --target <t>` for per-stage artifact state, and `./build.sh --help`
for the full command list.

Because each stage builds its prerequisites first, a single `./build.sh all
--target <t>` cascades the whole pipeline:

```
./build.sh all --target t
  -> xsa         : vivado creates the project (build.tcl), then synth/impl/XSA export (xsa.tcl)
  -> petalinux   : petalinux-create --template zynqMP -> petalinux-config --get-hw-description <XSA>
                   -> copy bsp/<board>/project-spec/* (and bsp/<target>/* if present)
                   -> copy submodules/meta-hailo into project-spec/meta-user/  (Hailo Yocto layer)
                   -> petalinux-config --silentconfig -> petalinux-build -> petalinux-package boot
  -> package     : zip the boot files into bootimages/
```

Build a single stage on its own with `./build.sh <stage> --target <t>`; the
runner still builds any missing prerequisite stages first.

Per-target lock files (`.<target>.lock` at the repository root) prevent two
concurrent builds of the same target from clobbering each other.

### `meta-hailo` integration

`PetaLinux/Makefile` brings the Hailo Yocto layer into each PetaLinux
project at configure time by copying `submodules/meta-hailo/` into the
target's `project-spec/meta-user/` directory. The submodule tracks
upstream Hailo's `hailo8-scarthgap` branch (pinned to a specific
SRCREV in `.gitmodules`), which is the branch Hailo maintains for
scarthgap-based builds and is already scarthgap-compat out of the box —
no local patch is applied on top.

Updating the Hailo layer means bumping the submodule pointer:

```
git -C submodules/meta-hailo fetch origin hailo8-scarthgap
git -C submodules/meta-hailo checkout <new-commit>
git add submodules/meta-hailo
```

Or, to follow the branch tip:

```
git submodule update --remote submodules/meta-hailo
```

## Vivado side

### Block design

The block-design scripts live under `Vivado/src/bd/`:

* `bd_zynqmp.tcl` — Zynq UltraScale+ targets.
* `mipi_locs.tcl` — Tcl dictionary mapping each target to its MIPI
  lane placement, sourced by `bd_zynqmp.tcl`.

`bd_zynqmp.tcl` contains per-board conditional blocks where a target
needs to deviate from the family defaults — typically for clock
routing, PS configuration, or PL pinout.

After sourcing the BD script, `scripts/build.tcl` runs
`validate_bd_design -force`, which triggers parameter propagation and
fills in connection-automation rules. As a result the final
implemented design may contain nets that aren't visible in the BD TCL
source — to see the actual netlist as built, inspect the saved `.bd`
file under `Vivado/<target>/<target>.srcs/sources_1/bd/<bd_name>/` or
use `write_bd_tcl` to export a complete script from an open project.

### PCIe root ports and address map

The number of XDMA root ports and their width come from the `lanes` list of the target
in `config/data.json` (one entry per root port: `[1]` = one Gen3 x1 root port,
`[4, 4]` = two Gen3 x4 root ports). The GT quad and PCIe block of each root port are set
per board at the top of `bd_zynqmp.tcl` (`select_quad_*`, `pcie_blk_locn_*`).

The AXI BAR window of each root port (`axibar2pciebar_0`, and the matching
`SEG_xdma_<n>_BAR0` address segment on `M_AXI_HPM1_FPD`) is placed in the 32-bit address
space, mapped 1:1 to the same PCIe address: `0xB000_0000` for `xdma_0` and, on the targets
with two root ports, `0xB800_0000` for `xdma_1` (128 MB each; 256 MB for a single root
port). The device-tree generator then exports a 32-bit non-prefetchable memory window,
which is what an NVMe SSD needs for its non-prefetchable BAR0 (a 64-bit window above
4 GB can only hold prefetchable BARs). `0xA000_0000`, the 32-bit window of
`M_AXI_HPM0_FPD`, is used by the video IP. If you change these addresses, keep
`axibar2pciebar_0` equal to the segment offset and keep the window below 4 GB, or SSDs
will not enumerate. Notes (1) to (5) in `bd_zynqmp.tcl` explain the XDMA settings.

### Constraints

`Vivado/src/constraints/<target>.xdc` contains pin assignments and any
target-specific timing constraints. Constraints common to all targets
of a given family are not factored out — each target's XDC is
self-contained.

### Build scripts

* `Vivado/scripts/build.tcl` creates the Vivado project, adds the
  target's XDC, sources `bd_zynqmp.tcl`, and validates the block
  design. Invoked via `./build.sh project --target <t>`.
* `Vivado/scripts/xsa.tcl` opens the existing project, runs synthesis
  and implementation, exports the XSA, and writes the bitstream into
  the implementation run directory. Invoked via `./build.sh xsa --target <t>`.

Both scripts check `XILINX_VIVADO` to confirm the installed Vivado
version matches the `version_required` constant at the top of the
file.

### Modifying the block design

Edit `Vivado/src/bd/bd_zynqmp.tcl` directly. If the change applies
only to some targets, wrap the additions in the appropriate per-board
conditional block.

Once the script is edited, delete any existing per-target Vivado
project directory (`rm -rf Vivado/<target>`) and re-run the Vivado
build:

```
./build.sh xsa --target <target>
```

This re-creates the project, sources the modified BD script, runs
`validate_bd_design`, synthesises, implements, and re-exports the XSA.
Downstream PetaLinux / boot-image steps will pick up the new XSA on
the next build.

### Adding or modifying constraints

Edit `Vivado/src/constraints/<target>.xdc` directly. If a constraint
applies to all targets in a family, it still needs to be replicated to
each target's XDC.

## PetaLinux side

### BSP composition

The PetaLinux project for a given target is composed at build time
from up to two BSP fragments plus the Hailo Yocto layer:

1. A **board BSP** at `PetaLinux/bsp/<board>/` — always applied.
   Provides board-specific kernel and U-Boot configuration, the
   system device-tree fragment for the board, the `initcams` startup
   scripts (including a `hailodemo.sh` and the `yolov5m_wo_spp_yuy2.hef`
   pre-compiled Hailo network), the recipes that add `xtl`, `xsimd`,
   and `xtensor` to the rootfs, and any board-specific patches.
2. An **optional per-target BSP overlay** at `PetaLinux/bsp/<target>/`
   — applied only if the directory exists (the `cp` is prefixed with
   `-` in the Makefile so a missing directory is not an error).
3. The **`meta-hailo` Yocto layer** copied verbatim from
   `submodules/meta-hailo/` (tracking the `hailo8-scarthgap` branch)
   into `project-spec/meta-user/meta-hailo/`. This adds the Hailo
   runtime (`libhailort`) and the TAPPAS application framework to the
   build. See [Hailo libraries and applications](hailo-libraries-and-applications)
   below for how the layer is structured and how to add to it.

### Layout of a board BSP

```
PetaLinux/bsp/<board>/project-spec/
├── configs/
│   ├── config                <- petalinux-config: bootargs, rootfs, hostname
│   ├── rootfs_config         <- petalinux-config -c rootfs: included packages
│   ├── init-ifupdown/
│   │   └── interfaces        <- /etc/network/interfaces
│   └── busybox/
│       └── inetd.conf
└── meta-user/
    ├── conf/
    │   ├── user-rootfsconfig <- declares additional rootfs config options
    │   ├── petalinuxbsp.conf
    │   └── layer.conf
    ├── recipes-apps/
    │   └── initcams/         <- Startup scripts + Hailo demo network
    │       ├── initcams.bb
    │       └── files/
    │           ├── init_cams.sh
    │           ├── displaycams.sh
    │           ├── hailodemo.sh
    │           ├── yolov5.json
    │           └── yolov5m_wo_spp_yuy2.hef
    ├── recipes-support/      <- Hailo C++ deps added to rootfs
    │   ├── xtl/xtl_0.7.7.bbappend
    │   ├── xsimd/xsimd_11.2.0.bbappend
    │   └── xtensor/xtensor_0.24.7.bbappend
    ├── recipes-bsp/
    │   ├── device-tree/
    │   │   ├── device-tree.bbappend
    │   │   └── files/
    │   │       └── system-user.dtsi    <- board-specific DT additions
    │   ├── u-boot/
    │   │   ├── u-boot-xlnx_%.bbappend
    │   │   └── files/
    │   │       ├── bsp.cfg
    │   │       ├── platform-top.h
    │   │       └── *.patch             <- U-Boot source patches
    │   └── embeddedsw/                 <- (zcu104 only)
    │       ├── fsbl-firmware_%.bbappend
    │       └── files/
    │           └── zcu104_vadj_fsbl.patch
    └── recipes-kernel/
        └── linux/
            ├── linux-xlnx_%.bbappend
            └── linux-xlnx/
                └── bsp.cfg             <- kernel Kconfig additions
```

### Adding a package to the root filesystem

1. Append the new option to `bsp/<board>/project-spec/configs/rootfs_config`.
2. If the package is not in the default `petalinux-config -c rootfs`
   menu, also append a declaration line to
   `bsp/<board>/project-spec/meta-user/conf/user-rootfsconfig`.
3. If the package is not provided by an existing meta-layer (including
   `meta-hailo`), add a recipe under
   `bsp/<board>/project-spec/meta-user/recipes-apps/<package>/<package>.bb`.

### Adding a kernel config option

Append the option to
`bsp/<board>/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`.

### Adding a device-tree fragment

Edit
`bsp/<board>/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`.
If you add new files, ensure they are listed in `SRC_URI:append` in
`device-tree.bbappend`.

### Adding a kernel patch or out-of-tree driver

1. Drop the patch file into
   `bsp/<board>/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/`.
2. Add `SRC_URI:append = " file://<your-patch>.patch"` to
   `recipes-kernel/linux/linux-xlnx_%.bbappend`.

### Modifying U-Boot

The same pattern as the kernel, under
`bsp/<board>/project-spec/meta-user/recipes-bsp/u-boot/`. `bsp.cfg`
adds U-Boot Kconfig options; `platform-top.h` overrides the U-Boot
platform header; patches are listed in `SRC_URI:append` in
`u-boot-xlnx_%.bbappend`.

### Modifying the Hailo layer

See [Hailo libraries and applications](hailo-libraries-and-applications)
below — that section covers the layer's structure, how to add new
recipes, and how to override existing ones via per-BSP bbappends.

(hailo-libraries-and-applications)=
## Hailo libraries and applications

The Hailo runtime, drivers, and gstreamer plugins reach the rootfs
through the `meta-hailo` Yocto layer, brought in as a git submodule
that tracks Hailo's `hailo8-scarthgap` branch.

### Layer layout

`submodules/meta-hailo/` (copied into each project's
`meta-user/meta-hailo/` at configure time):

```
meta-hailo/
├── meta-hailo-libhailort/        <- core runtime + CLI + gstreamer plugin
│   ├── classes/
│   │   └── hailort-base.bbclass  <- shared cmake recipe glue, offline-build hooks
│   ├── conf/layer.conf
│   ├── recipes-core/packagegroups/
│   │   └── packagegroup-hailo-hailort.bb
│   ├── recipes-gstreamer/libgsthailo/
│   │   └── libgsthailo_4.23.0.bb       <- HailoNet gstreamer element
│   └── recipes-hailo/
│       ├── libhailort/libhailort_4.23.0.bb   <- libhailort.so + headers
│       ├── hailortcli/hailortcli_4.23.0.bb   <- hailortcli + benchmark commands
│       ├── pyhailort/pyhailort_4.23.0.bb     <- Python bindings
│       └── hailort-service/hailort-service_4.23.0.bb
├── meta-hailo-accelerator/       <- kernel-side: hailo PCIe / I²C driver
│   ├── recipes-kernel/hailo-accelerator/
│   │   └── hailo-accelerator.bb
│   └── recipes-core/packagegroups/
│       └── packagegroup-hailo-accelerator.bb
└── meta-hailo-tappas/            <- TAPPAS app framework + post-processing libs
    ├── recipes-gstreamer/
    │   ├── hailo-post-processes/   (5.1.0)
    │   ├── libgsthailotools/       (5.1.0)
    │   ├── tappas-tracers/         (5.1.0)
    │   └── xtl, xtensor, xsimd     (TAPPAS C++ deps; version-pinned)
    └── recipes-core/packagegroups/
        └── packagegroup-hailo-tappas.bb
```

The three sublayers must be registered with bitbake's layer
configuration. The board BSPs in this repository carry the
registration in `project-spec/configs/config`:

```
CONFIG_USER_LAYER_0="${PROOT}/project-spec/meta-user/meta-hailo/meta-hailo-libhailort"
CONFIG_USER_LAYER_1="${PROOT}/project-spec/meta-user/meta-hailo/meta-hailo-accelerator"
CONFIG_USER_LAYER_2="${PROOT}/project-spec/meta-user/meta-hailo/meta-hailo-tappas"
```

`${PROOT}` is expanded to the PetaLinux project root by
`meta-xilinx-core/gen-machine-conf/lib/update_buildconf.py:AddUserLayers()`.
Without these lines `petalinux-config --silentconfig` does not pick up
the layers nested under `meta-user/meta-hailo/` and recipes from them
fail to parse.

### What gets installed in the rootfs

The board BSPs select the Hailo content via two paths in
`project-spec/configs/rootfs_config`:

* `CONFIG_packagegroup-hailo-accelerator=y` → pulls in the kernel
  module and userspace plumbing for the Hailo-8 device.
* `CONFIG_packagegroup-hailo-tappas=y` (or the `-dev-pkg` variant) →
  pulls in `hailo-post-processes`, `libgsthailo`, `libgsthailotools`,
  and the TAPPAS C++ dependencies.

`hailortcli` is enabled separately (`CONFIG_hailortcli=y`). Add or
remove these lines in a BSP's `rootfs_config` to control what ships.

### Initialisation and demo

Each board BSP ships a `recipes-apps/initcams/` recipe carrying camera
and Hailo startup scripts:

* `init_cams.sh` — finds the cameras on the RPi Camera FMC and sets the
  format of each MIPI capture pipeline (sensor, CSI-2 RX, ISP, VPSS)
  with `media-ctl`.
* `displaycams.sh` — sets the display to 1920x1080 at 60 Hz and shows
  every camera in a quadrant of the DisplayPort monitor.
* `hailodemo.sh` — runs a sample inference pipeline using
  `gst-launch-1.0` + the HailoNet gstreamer element against a bundled
  pre-compiled network file.
* `yolov5m_wo_spp_yuy2.hef` — the bundled YOLOv5m network compiled for
  the Hailo-8 (1280x720 YUY2 input, ≈16 MB, installed in
  `/usr/bin/resources/`), with its post-processing configuration
  `yolov5.json` (`/usr/bin/resources/configs/`).

To swap the bundled `.hef` for a different model, drop the new file
into the same `recipes-apps/initcams/files/` directory and update the
`SRC_URI` in `initcams.bb`. To use it from a different demo script,
add the script to the same directory and reference it from
`do_install`.

### Adding a new Hailo recipe (e.g. another sublayer, library, or app)

Three patterns, depending on the change:

1. **bbappend an existing meta-hailo recipe** — preferred when you
   want to tweak `EXTRA_OECMAKE`, add a `DEPENDS`, or override a file
   shipped by the recipe. Put the bbappend under the BSP, not in the
   submodule, so it's tracked in this repository:

   ```
   PetaLinux/bsp/<board>/project-spec/meta-user/recipes-hailo/
     └── libhailort/
         └── libhailort_4.23.0.bbappend
   ```

   The version `4.23.0` must match the PV of the recipe in
   `meta-hailo-libhailort/recipes-hailo/libhailort/libhailort_4.23.0.bb`.
   The bbappend dir is searched automatically once it lives under
   `meta-user/` of the active project.

2. **A new BB recipe that depends on Hailo** — for an application,
   library, or systemd service that builds against libhailort. Drop
   it under the BSP:

   ```
   PetaLinux/bsp/<board>/project-spec/meta-user/recipes-apps/<name>/
     ├── <name>_<ver>.bb         (recipe; DEPENDS = "libhailort", etc.)
     └── files/                  (source / patches)
   ```

   Add `CONFIG_<name>=y` to the BSP's `rootfs_config`.

3. **Modify the meta-hailo submodule itself** — only do this when the
   change really belongs in the layer (a new sublayer, an upstream
   bugfix backport, etc.) and you've decided not to upstream it to
   Hailo. The standard git-submodule workflow applies:
   `cd submodules/meta-hailo`, branch off `hailo8-scarthgap`, commit,
   then bump the parent repo's submodule pointer. Be aware that the
   `PetaLinux/Makefile` copies the submodule contents fresh into each
   project at configure time, so local-only changes you forgot to
   commit *do* get picked up by the next build — but only until the
   parent submodule pointer drifts.

### Non-standard things this repo does on top of stock meta-hailo

* **`packagegroup-hailo-tappas` no longer pulls in `tappas-apps`.** The
  Hailo 5.1.0 TAPPAS restructure removed the legacy `tappas-apps`
  recipe; the BSPs' `rootfs_config` files have had the corresponding
  `CONFIG_tappas-apps=y` line removed to match.
* **`meta-hailo-vpu` is not registered.** Upstream's `hailo8-scarthgap`
  branch removed the VPU sublayer (it was Hailo-15-specific); there's
  no `CONFIG_USER_LAYER_3=...meta-hailo-vpu` line.
* **Host CA-bundle workaround required for builds.** PetaLinux
  2025.2's eSDK ships a `git-native` whose CA path is the unrelocated
  placeholder `/usr/local/oe-sdk-hardcoded-buildpath/...`.
  libhailort's CMake `FetchContent_Declare` clones at `do_configure`
  and fails on that path. The build host needs a one-time `sudo`
  symlink — see the top-level `README.md` section *Build issue and
  workaround*. `PetaLinux/Makefile` runs a `check_ca_workaround`
  target as a prerequisite of `petalinux` and fails fast with the fix
  instructions if the symlink isn't present.
* **`LICENSE_PATH` is rewritten from `=` to `+=` in the project-local
  copy of `meta-hailo-tappas/conf/layer.conf`.** Upstream's
  `hailo8-scarthgap` branch declares
  `LICENSE_PATH = "${LAYERDIR}/licenses/"` (hard assignment), which
  clobbers contributions from prior layers (notably `meta-qt5`, which
  ships `The-Qt-Company-GPL-Exception-1.0` in its own `licenses/`
  dir). Any recipe whose `LICENSE` field references a non-SPDX
  license carried by another layer — qtbase being the most prominent
  — then fails `do_create_spdx` with
  *"Cannot find any text for license …"*. The Makefile runs a `sed`
  on the project-local copy after `cp -R $(HAILO_RECIPES)`, so the
  submodule is left untouched (and `git submodule update --remote`
  won't undo the fix). The underlying bug should be reported
  upstream against `hailo-ai/meta-hailo`.

## Modifications layered on the stock BSPs

The board BSPs in this repository started as the corresponding stock
AMD reference BSPs and have been modified in the following ways. This
list is the answer to *"what would I lose if I overwrote the BSP with
the stock one?"* — it is what to re-apply if you ever do that.

### All BSPs

* **Hostname / product name** set in `configs/config` via
  `CONFIG_SUBSYSTEM_HOSTNAME` and `CONFIG_SUBSYSTEM_PRODUCT`. Latest
  values are `zcu104-hailo-2025-2`, `zcu106-hailo-2025-2`,
  `pynqzu-hailo-2025-2`, `uzev-hailo-2025-2`.
* **SD-card root filesystem** configured in `configs/config`:
  `CONFIG_SUBSYSTEM_ROOTFS_EXT4`, `CONFIG_SUBSYSTEM_SDROOT_DEV`,
  `CONFIG_SUBSYSTEM_USER_CMDLINE` (with `cma=` raised for video frame
  buffers and Hailo network buffers, and
  `xlnx_mixer.connect_drm_bridge=1` to route v_mix into DPSUB via the
  2025.2 DRM-bridge path).
* **Custom `system-user.dtsi`** with device-tree nodes for the
  RPi-camera I²C bus, camera sensors, clock generator, frame-buffer /
  video pipeline, and the XDMA PCIe root port(s).
* **`recipes-apps/initcams/`** providing the camera + Hailo startup
  scripts and the bundled pre-compiled Hailo network
  (`yolov5m_wo_spp_yuy2.hef`).
* **`recipes-support/{xtl,xsimd,xtensor}_*.bbappend`** adding the
  C++ header-only libraries that the Hailo TAPPAS pipeline depends
  on to the rootfs (and to the SDK sysroot, for cross-compiling
  user applications).
* **U-Boot patch `0001-ubifs-distroboot-support.patch`** staged under
  `recipes-bsp/u-boot/files/`. Note that the canonical `u-boot-xlnx_%.bbappend`
  in the BSP only references `platform-top.h` and `bsp.cfg` via `SRC_URI:append`;
  the `.patch` file is present in the `files/` directory but is not currently
  hooked into `SRC_URI`, so it is staged but inert. Add an
  `SRC_URI:append = " file://0001-ubifs-distroboot-support.patch"` line if
  you need UBIFS distroboot for QSPI flash boot.
* **`hailo-pci_4.23.0.bbappend` + `0001-vdma-take-mmap_read_lock-around-find_vma.patch`**
  under `recipes-kernel/hailo-pci/`. The HailoRT v4.23 `hailo_pci` driver
  calls `find_vma()` without holding `mmap_lock`, which is fatal on
  kernel ≥ 6.5 (PetaLinux 2025.2 ships kernel 6.12 and asserts in
  `include/linux/rwsem.h`). The patch wraps the call in
  `mmap_read_lock`/`mmap_read_unlock`, backporting the fix Hailo
  already shipped on its `v5.3.0-hotfix-kernel-above-6-15` branch. The
  bbappend applies the patch idempotently from `do_compile:prepend()`
  (not via `SRC_URI`, because the recipe's `S` is set to a sibling
  directory of the patch target, so `do_patch` cannot reach it).
* **`linux-xlnx_%.bbappend` + three DRM patches** under
  `recipes-kernel/linux/linux-xlnx/`, all required when the v_mix
  driver runs in DRM-bridge mode
  (`xlnx_mixer.connect_drm_bridge=1`):
  - `0001-drm-xlnx-mixer-fix-NULL-deref-in-connector_init.patch`
    fixes a NULL deref where `xlnx_mix_connector_init()` dereferences
    `mixer->master` before it has been assigned by
    `xlnx_drm_pipeline_init()`.
  - `0002-drm-xlnx-drv-drop-mode_config_cleanup-on-unbind.patch`
    removes the manual `drm_mode_config_cleanup()` from
    `xlnx_unbind()` — drm_managed-based connectors registered by the
    bridge path would otherwise be cleaned up twice (NULL deref +
    `ida_free` on an unallocated ID at poweroff/reboot).
  - `0003-drm-xlnx-drv-disable-vblank-before-cleanup-on-shutdown.patch`
    calls `drm_atomic_helper_shutdown()` at the start of
    `xlnx_unbind()` so vblank is disabled before drm_managed
    teardown runs, silencing a `WARN_ON` at shutdown.
* **`linux-xlnx_%.bbappend` + two ISP pipeline driver patches** under
  `recipes-kernel/linux/linux-xlnx/` (`drivers/media/platform/xilinx/xilinx-isppipeline.c`):
  - `0004-media-xilinx-isppipeline-fix-gamma-LUT-plane-order.patch`
    writes the red, green and blue gamma tables to the red, green and blue
    planes of the ISP core (the driver had them permuted: `red_gamma` acted
    on blue, `green_gamma` on red, `blue_gamma` on green) and makes all three
    default curves equal (gamma 2.0). Without it every camera picture has a
    magenta tint.
  - `0005-media-xilinx-isppipeline-use-the-DT-gain-and-threshold.patch`
    uses the `xlnx,rgain`, `xlnx,bgain` and `xlnx,pawb` device-tree values
    as the defaults of the `red_gain`, `blue_gain` and `threshold` controls
    (they were parsed but then overwritten by fixed defaults at probe).
* **`hailodemo.sh` sets the display mode to 1920x1080 at 60 Hz**
  (`DISP_RES=1920x1080`, `DISP_RATE=60`), the only mode the display
  pipeline produces, instead of the monitor's preferred mode.

### ZCU104 BSP

* **FSBL patch `zcu104_vadj_fsbl.patch`** in
  `recipes-bsp/embeddedsw/files/`, registered via
  `fsbl-firmware_%.bbappend`. The stock 2025.2 ZCU104 FSBL reads the
  wrong I²C address (it reads the on-board EEPROM at 0x54, not the FMC
  EEPROM at 0x50) and reads only 32 bytes, which is too short to cover
  the VADJ voltage record. Without the patch, VADJ is not properly
  programmed for the FMC. The patch also fixes the I²C mux channel
  selection so the FMC EEPROM is reachable.
* **`sdhci1` device-tree override** in `system-user.dtsi`. Opsero ZynqMP
  Vivado designs export a minimal `sdhci1` node, which causes a -110
  timeout during SD init on PetaLinux 2025.2. The BSP re-adds the
  properties (clock-frequency, bus-width, no-1-8-v, etc.) the stock
  AMD ZCU104 BSP carries.
* **2025.2 embeddedsw patching mechanics.** The `fsbl-firmware_%.bbappend`
  declares `SRC_URI:append = " file://zcu104_vadj_fsbl.patch;apply=no"`
  and adds a new shell task that runs `patch -p1` between
  `do_copy_shared_src` and `do_configure`. This is required because
  2025.2's `xlnx-embeddedsw.bbclass` schedules `do_copy_shared_src`
  *after* `do_patch`, so the normal `SRC_URI`-attached patch
  mechanism cannot find the source tree.

### UltraZed-EV (uzev) BSP

* **`CONFIG_YOCTO_MACHINE_NAME="zynqmp-generic"`** in `configs/config`
  (the UZ-EV is not a stock Xilinx eval board).
* **SD-card device set to `/dev/mmcblk1p2`** rather than the ZynqMP
  default `mmcblk0p2`. The carrier exposes both PSU SD0 (eMMC on the
  SoM) and PSU SD1 (carrier SD slot); boot uses PSU SD1.
* **`PRIMARY_SD_PSU_SD_1_SELECT=y`** to route the boot SD interface
  through PSU SD1 instead of SD0.
* **`CMA=1000M`** rather than the default 1536M used on ZCU10x boards
  — the UZ-EV ships with less DDR. Note: the uzev `configs/config`
  intentionally contains two `CONFIG_SUBSYSTEM_USER_CMDLINE` lines —
  the first inherits the ZynqMP defaults, the second (in the
  `# UZ-EV configs` block) overrides `mmcblk0p2` → `mmcblk1p2` and
  `cma=1536M` → `cma=1000M`. The last assignment wins.
* **UART0 forced** for PMUFW / FSBL / TF-A / Linux. Vivado 2025.2's
  `gen-machine-conf` flow defaults to PSU_UART_1 on this board, but
  the carrier's USB-serial interface is wired to PSU_UART_0, so the
  BSP explicitly selects `CONFIG_SUBSYSTEM_*_SERIAL_PSU_UART_0_SELECT=y`.
* **Custom `system-user.dtsi`** with UZ-EV-specific peripheral
  configuration.
* **`meta-xilinx-tools/recipes-bsp/uboot-device-tree/`** overlay that
  overrides the U-Boot device tree.

### ZCU106 BSPs (`zcu106` and `zcu106_hpc0`)

Both targets share the same board BSP under `PetaLinux/bsp/zcu106/`
because `PetaLinux/Makefile` derives the board name from the first
underscore-delimited token of `TARGET`. There is no per-target BSP
overlay for `zcu106_hpc0` — the only difference between the two is the
Vivado design.

### Genesys-ZU (`genesyszu`)

The Vivado target is defined and synthesizes, but there is no
PetaLinux BSP under `PetaLinux/bsp/genesyszu/` and `data.json` has
`"publish": false` and `"petalinux": false`. The design is excluded
from the published target list in the docs. To bring it up,
add a `PetaLinux/bsp/genesyszu/` BSP and flip the data.json flags.

### PYNQ-ZU BSP

* **WILC WiFi driver overlay** under `recipes-modules/wilc/` adding
  support for the WILC1000 module fitted on the PYNQ-ZU carrier.
* **Si5324 set-up in U-Boot** (`recipes-bsp/u-boot/files/platform-top.h`): the
  environment variable `fmc_gt_clk_en`, run by the boot command before the distro boot,
  puts the Si5324 in bypass mode (FMC 100 MHz clock from CKIN2 straight through to
  CKOUT1, no PLL) with three I2C writes on bus 1 (`hdmi_axi_iic`), then pulses
  pl_resetn0 to reset the XDMA IP. See [board specific notes](pynqzu-notes).

## Yocto side

### BSP composition

`./build.sh yocto --target <t>` creates the workspace `Yocto/<t>/`, generates a System
Device Tree from the XSA with `sdtgen`, generates the machine configuration from it
(`gen-machineconf parse-sdt`), and builds `edf-linux-disk-image` with these additions from
`Yocto/bsp/<board>/` (the board is the first token of the target label, so `zcu106` and
`zcu106_hpc0` share `Yocto/bsp/zcu106/`):

* `conf/local.conf.append` — appended to the workspace's `local.conf`: the hostname
  (`hostname:pn-base-files:forcevariable = "<board>-hailo-2025-2"`), the design's kernel
  arguments (`BSP_EXTRA_BOOTARGS = "cma=1536M xlnx_mixer.connect_drm_bridge=1"`;
  `cma=1000M` on `uzev`) and, on PYNQ-ZU, `SERIAL_CONSOLES` (a login prompt on `ttyPS0`
  only).
* `bblayers-extra.txt` — extra layers: the three `meta-hailo` sublayers from the
  `submodules/meta-hailo` submodule.
* `meta-user/` — the BSP layer: the same `initcams` recipe, device-tree overrides,
  kernel configuration and patches, and `hailo-pci` patch as the PetaLinux BSP, plus the
  image recipe append (`recipes-core/images/edf-linux-disk-image.bbappend`, the package
  list) and `recipes-bsp/u-boot/u-boot-edf-scr_%.bbappend` (kernel arguments, see
  below).

### Kernel command line

In the EDF flow on Zynq UltraScale+, the kernel command line is built by the U-Boot boot
script `boot.scr`: the device tree's `/chosen/bootargs` plus
`root=/dev/mmcblk<N>p3 ro rootwait uio_pdrv_genirq.of_id=generic-uio`. The `APPEND` variable
is not used by this flow. The BSP's `u-boot-edf-scr_%.bbappend` appends
`BSP_EXTRA_BOOTARGS` to that line, so design-specific arguments go into
`BSP_EXTRA_BOOTARGS` in `conf/local.conf.append`.

### Device-tree overrides specific to the Yocto flow

* **`misc_clk_0` / `misc_clk_1` fixed clocks.** `system-user.dtsi` overrides the rates of
  the PL clocks that the device-tree generator calls `misc_clk_N`. The SDT generator used
  by the Yocto flow numbers them the other way round from the PetaLinux generator: in the
  Yocto BSPs `misc_clk_0` is the 250 MHz video clock (`clk_wiz_0/clk_250M`, the input of
  the display Clocking Wizard) and `misc_clk_1` the 100 MHz AXI-Lite clock. The Clocking
  Wizard driver computes its settings from the `misc_clk_0` rate, so a wrong value there
  stops the display at the first mode set. Check the numbering in
  `Yocto/<target>/sdt/pl.dtsi` if you change the clocks of the block design.
* **Ethernet PHY (ZCU104, ZCU106).** The SDT flow does not describe the TI DP83867 PHY of
  the board's Ethernet port; `system-user.dtsi` adds it under `&gem3` with the RGMII delays
  of the official board device tree, and a fixed `local-mac-address`.
* **PYNQ-ZU Wi-Fi.** The WILC3000 power-up sequence (CHIP_EN as a fixed regulator that
  supplies the SDIO slot, RESETN through `mmc-pwrseq-simple`) and the `wifi@0` node on
  `&sdhci1`, using the stock kernel drivers.

### PYNQ-ZU Wi-Fi recipes

The PYNQ-ZU Yocto BSP adds:

* kernel patches `0010-wifi-wilc1000-backport-WILC3000-support.patch` (the in-tree
  `wilc1000` driver of kernel 6.12 recognises only the WILC1000) and
  `0011-wifi-wilc1000-refuse-config-requests-before-the-first-open.patch`, with the driver
  enabled in `bsp.cfg` (`CONFIG_WILC1000_SDIO=m`);
* `recipes-bsp/wilc3000-firmware/` — the WILC3000 firmware from linux-firmware;
* `recipes-connectivity/wifi-sta-config/` — `wpa_supplicant@wlan0` with a DHCP network
  for `wlan0`, the `wifi-sta-setup` helper and a configuration template. No credentials
  are included in the image.

### PYNQ-ZU Si5324 boot script

The PYNQ-ZU Yocto BSP configures the Si5324 (see [board specific notes](pynqzu-notes))
from the U-Boot boot script:

* `recipes-bsp/u-boot/files/pynqzu-si5324-pcie-refclk.cmd` — the same three I2C writes and
  pl_resetn0 pulse as the PetaLinux `fmc_gt_clk_en`, on I2C bus 0 (the EDF U-Boot numbers
  the buses from the System Device Tree aliases, which make `hdmi_axi_iic` `i2c0`);
* `recipes-bsp/u-boot/u-boot-edf-scr_1.0.bbappend` — puts those commands at the start of
  `boot.scr`, before the kernel is loaded;
* `recipes-bsp/u-boot/u-boot-xlnx_%.bbappend` with `files/pynqzu-axi-iic.cfg` — enables the
  U-Boot AXI IIC driver (`CONFIG_SYS_I2C_XILINX_XIIC`).

## Where build outputs land

| Path                                | Contents                                                                       |
|-------------------------------------|--------------------------------------------------------------------------------|
| `Vivado/<target>/`                  | Vivado project. `<bd_name>_wrapper.xsa` is the export.                          |
| `Vivado/<target>/<target>.runs/impl_1/<bd_name>_wrapper.bit` | Bitstream.                                              |
| `Vivado/logs/`                      | Per-target Vivado build logs.                                                   |
| `PetaLinux/<target>/`               | PetaLinux project. All PetaLinux build state lives here, including the assembled `meta-hailo` layer under `project-spec/meta-user/meta-hailo/`. |
| `PetaLinux/<target>/images/linux/`  | `BOOT.BIN`, `image.ub`, `boot.scr`, `rootfs.tar.gz`, etc.                       |
| `PetaLinux/<target>/build/build.log`| PetaLinux build log.                                                            |
| `Yocto/<target>/`                   | Yocto / EDF workspace (sources, `build/`, generated `sdt/`).                    |
| `Yocto/<target>/images/linux/`      | `BOOT.BIN`, `boot.scr`, `Image`, `system.dtb`, `rootfs.wic.xz`, `rootfs.wic.bmap`, `rootfs.tar.gz`. |
| `bootimages/`                       | Per-target zipped boot files.                                                   |

None of these directories are committed to the repository.
