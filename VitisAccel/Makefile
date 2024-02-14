# Opsero Electronic Design Inc. 2023
#
# This Makefile builds the PL kernels and links them into the hw platform.

DIR_PRJ = $(shell pwd)
RM = rm -rf
VIVADO_ROOT := $(XILINX_VIVADO)
VIVADO:=${VIVADO_ROOT}/bin/vivado
XBU = xclbinutil
XBU_FLAGS = --remove-section BITSTREAM --force
XSCT = $(XILINX_VITIS)/bin/xsct
BD_NAME = rpi

# defaults
.DEFAULT_GOAL := all
TARGET ?= none
JOBS ?= 8

# valid targets
zcu104_target := 0
zcu106_hpc0_target := 0
zcu106_target := 0
uzev_target := 0

TARGET_LIST := $(sort $(patsubst %_target,%,$(filter %_target,$(.VARIABLES))))

# Kernel name
KERNEL_DIR = kernels
KERNEL = v_multi_scaler
KERNEL_SUBDIR = $(KERNEL_DIR)/build/$(TARGET)/$(KERNEL)
KERNEL_XO = $(KERNEL_SUBDIR)/$(KERNEL).xo
TARGET_OPT = hw

# Vivado
VIV_DIR = $(DIR_PRJ)/../Vivado
VIV_PRJ_DIR = $(VIV_DIR)/$(TARGET)
VIV_XSA = $(VIV_PRJ_DIR)/$(BD_NAME)_wrapper.xsa

# Vitis
VIT_SCRIPT_PFM = $(DIR_PRJ)/tcl/pfm.tcl

# Platform
PFM_WORKSPACE = $(TARGET)_workspace
PFM_FILE = $(DIR_PRJ)/$(PFM_WORKSPACE)/$(TARGET)/export/$(TARGET)/$(TARGET).xpfm
# PFM_FILE = $(DIR_PRJ)/../Vitis/$(TARGET)_accel_ws/$(TARGET)/export/$(TARGET)/$(TARGET).xpfm

# Outputs
CONTAINER_DIR = $(TARGET)_container
XCLBIN_FILE = $(CONTAINER_DIR)/dpu.xclbin
LOGS_DIR = $(CONTAINER_DIR)/logs
IP_CACHE_DIR = $(CONTAINER_DIR)/ip_cache
SD_CARD_DIR = $(CONTAINER_DIR)/sd_card

#---------------------------------------------------------------------
# vitis common setup
.PHONY: help
help::
	@echo ''
	@echo 'Usage:'
	@echo ''
	@echo '  make xclbin TARGET=<val> JOBS=<val>'
	@echo '    Generate the xclbin and bitstream for the target design.'
	@echo ''
	@echo '  make all JOBS=<val>'
	@echo '    Generate xclbin and bitstream for all targets.'
	@echo ''
	@echo '  make clean TARGET=<target design>'
	@echo '    Delete all build products for target design.'
	@echo ''
	@echo '  make clean_all'
	@echo '    Delete build products for all targets.'
	@echo ''
	@echo 'Parameters:'
	@echo ''
	@echo '  TARGET: Name of the target design, must be one of the following:'
	@$(foreach targ,$(TARGET_LIST),echo "    - $(targ)";)
	@echo ''
	@echo '  JOBS: Optional param to set number of synthesis jobs (default 8)'
	@echo ''
	@echo 'Example usage:'
	@echo '  make xclbin TARGET=$(word 1,$(TARGET_LIST))'
	@echo ''

# # v++ flags
VPP ?= v++

XOCC_OPTS = -t ${TARGET_OPT} --platform ${PFM_FILE} --save-temps --config ${DIR_PRJ}/prj_conf/prj_config --xp param:compiler.userPostSysLinkOverlayTcl=${DIR_PRJ}/prj_conf/strip_interconnects.tcl

.PHONY: all xclbin clean package

all:
	@{ \
	for targ in $(TARGET_LIST); do \
		$(MAKE) --no-print-directory xclbin TARGET=$${targ} JOBS=$(JOBS); \
	done; \
	}

xclbin: check_target $(XCLBIN_FILE) package

$(XCLBIN_FILE): $(KERNEL_XO)
	$(VPP) $(XOCC_OPTS) -l --temp_dir $(CONTAINER_DIR) --log_dir $(LOGS_DIR) --remote_ip_cache $(IP_CACHE_DIR) -o "$@" $(+)
	$(XBU) $(XBU_FLAGS) --input $@ --output strip.xclbin
	@mv strip.xclbin $@

.PHONY: kernel
kernel: $(KERNEL_XO)
$(KERNEL_XO): $(PFM_FILE)
	$(MAKE) -C $(KERNEL_DIR) all PLATFORM_FILE=$(PFM_FILE) TARGET=$(TARGET)

$(PFM_FILE): $(VIV_XSA)
	$(XSCT) $(VIT_SCRIPT_PFM) -xsa $(VIV_XSA) -targ $(TARGET)

$(VIV_XSA):
	$(MAKE) -C $(VIV_DIR) xsa TARGET=$(TARGET) JOBS=$(JOBS)

package:
	-@mkdir -p $(SD_CARD_DIR)
	cp $(CONTAINER_DIR)/link/vivado/vpl/prj/prj*/sources_1/bd/*/hw_handoff/*.hwh $(SD_CARD_DIR)
	cp $(CONTAINER_DIR)/link/vivado/vpl/prj/prj.runs/impl_1/*.bit $(SD_CARD_DIR)
	cp $(CONTAINER_DIR)/*.xclbin $(SD_CARD_DIR)

.PHONY: clean
clean: check_target
	-$(RM) $(CONTAINER_DIR)
	-$(RM) $(PFM_WORKSPACE)
	$(MAKE) -C $(KERNEL_DIR) clean TARGET=$(TARGET)

.PHONY: clean_all
clean_all: 
	@{ \
	for targ in $(TARGET_LIST); do \
		$(MAKE) --no-print-directory clean TARGET=$${targ}; \
	done; \
	}
	$(MAKE) -C $(KERNEL_DIR) clean_all
	-$(RM) *.log _x *.jou v++* *.xclbin *.ini *.xsa .Xil
	-$(RM) packaged* tmp_*

check_target:
ifndef $(TARGET)_target
	$(error "Please specify a TARGET. Use 'make help' to see valid targets.")
endif


