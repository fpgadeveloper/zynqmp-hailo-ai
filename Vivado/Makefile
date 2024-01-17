# Opsero Electronic Design Inc. 2023
#
# This Makefile can be used to build the Vivado projects.

CP = cp -rf
MKDIR = mkdir -p
RM = rm -rf
ROOT_DIR = $(shell pwd)
VIVADO = $(XILINX_VIVADO)/bin/vivado
BD_NAME = rpi

# defaults
.DEFAULT_GOAL := xsa
TARGET ?= none
JOBS ?= 8

# valid targets
zcu104_target := xilinx.com zcu104
zcu106_hpc0_target := xilinx.com zcu106
pynqzu_target := tul.com.tw pynqzu
genesyszu_target := digilentinc.com gzu_5ev
uzev_target := avnet.com ultrazed_7ev_cc

TARGET_LIST := $(sort $(patsubst %_target,%,$(filter %_target,$(.VARIABLES))))

BOARD_URL = $(word 1,$($(TARGET)_target))
BOARD_NAME = $(word 2,$($(TARGET)_target))

# Vivado paths
VIV_SCRIPT_BD = scripts/build.tcl
VIV_SCRIPT_XSA = scripts/xsa.tcl
VIV_DIR = $(TARGET)
IP_DIR= ./ip
IP_DONE = $(IP_DIR)/build/$(BOARD_NAME)/ip_done.txt

# output files
VIV_XPR = $(VIV_DIR)/$(TARGET).xpr
VIV_XSA = $(VIV_DIR)/$(BD_NAME)_wrapper.xsa
VIV_XPR_LOG = $(TARGET)_xpr.log
VIV_XPR_JOU = $(TARGET)_xpr.jou
VIV_XSA_LOG = $(TARGET)_xsa.log
VIV_XSA_JOU = $(TARGET)_xsa.jou
VIV_BIT = $(VIV_DIR)/$(TARGET).runs/impl_1/$(BD_NAME)_wrapper.bit
VIV_LOCK = $(ROOT_DIR)/.$(TARGET).lock

# Targets with accelerators don't need to run implementation, only synth
SYNTH_ONLY = 1

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make xsa TARGET=<val> JOBS=<n>'
	@echo '    Create the Vivado project and block design, then synthesize'
	@echo '    implement and export to XSA.'
	@echo ''
	@echo '  make project TARGET=<val>'
	@echo '    Create the Vivado project and block design.'
	@echo ''
	@echo '  make clean TARGET=<val>'
	@echo '    Clean runs for target project.'
	@echo ''
	@echo '  make xsa_all JOBS=<n>'
	@echo '    Same as make xsa but for all targets.'
	@echo ''
	@echo '  make project_all'
	@echo '    Same as make project but for all targets.'
	@echo ''
	@echo '  make clean_all'
	@echo '    Same as make clean but for all targets.'
	@echo ''
	@echo 'Parameters:'
	@echo ''
	@echo '  TARGET: Name of the target design, must be one of the following:'
	@$(foreach targ,$(TARGET_LIST),echo "    - $(targ)";)
	@echo ''
	@echo '  JOBS: Optional param to set number of synthesis jobs (default 8)'
	@echo ''
	@echo 'Example usage:'
	@echo '  make xsa TARGET=$(word 1,$(TARGET_LIST))'
	@echo ''

.PHONY: all
all: xsa_all

.PHONY: ip
ip: $(IP_DONE)

$(IP_DONE):
	make -C $(IP_DIR) ip TARGET=$(TARGET)

.PHONY: xsa
xsa:
	@if [ -f $(VIV_LOCK) ]; then \
		echo "$(TARGET) is locked. Skipping..."; \
	else \
		touch $(VIV_LOCK); \
		$(MAKE) xsa_locked TARGET=$(TARGET) JOBS=$(JOBS); \
		rm -f $(VIV_LOCK); \
	fi

xsa_locked: $(VIV_XSA) check_warnings
$(VIV_XSA): $(VIV_XPR)
	$(RM) $(VIV_XSA_LOG) $(VIV_XSA_JOU)
	$(VIVADO) -mode batch -notrace -source $(VIV_SCRIPT_XSA) -log $(VIV_XSA_LOG) -journal $(VIV_XSA_JOU) -tclargs $(TARGET) $(JOBS) $(SYNTH_ONLY)
	$(CP) $(VIV_XSA_LOG) $(VIV_XSA_JOU) $(TARGET)/.
	$(RM) $(VIV_XSA_LOG) $(VIV_XSA_JOU)

check_warnings:
	@grep "CRITICAL WARNING:" $(TARGET)/$(VIV_XSA_LOG) && { \
		echo "Critical warnings found. Exiting."; \
		echo "For details see: $(TARGET)/$(VIV_XSA_LOG)"; \
		exit 1; \
	} || true

.PHONY: xsa_all
xsa_all:
	for targ in $(TARGET_LIST); do \
		$(MAKE) xsa TARGET=$$targ JOBS=$(JOBS); \
	done

.PHONY: project
project: check_target
	@if [ -f $(VIV_LOCK) ]; then \
		echo "$(TARGET) is locked. Skipping..."; \
	else \
		touch $(VIV_LOCK); \
		$(MAKE) project_locked TARGET=$(TARGET) JOBS=$(JOBS); \
		rm -f $(VIV_LOCK); \
	fi

project_locked: $(VIV_XPR)
$(VIV_XPR): $(IP_DONE)
	@echo 'Create Vivado project $(TARGET)'
	$(RM) $(VIV_XPR_LOG) $(VIV_XPR_JOU)
	$(VIVADO) -mode batch -notrace -source $(VIV_SCRIPT_BD) -log $(VIV_XPR_LOG) -journal $(VIV_XPR_JOU) -tclargs $(TARGET)
	$(CP) $(VIV_XPR_LOG) $(VIV_XPR_JOU) $(TARGET)/.
	$(RM) $(VIV_XPR_LOG) $(VIV_XPR_JOU)

.PHONY: project_all
project_all:
	for targ in $(TARGET_LIST); do \
		$(MAKE) project TARGET=$$targ JOBS=$(JOBS); \
	done

.PHONY: clean
clean: check_target
	@echo 'Cleaning project $(TARGET)'
	$(RM) $(VIV_DIR)
	$(MAKE) -C $(IP_DIR) clean TARGET=$(TARGET)

.PHONY: clean_all
clean_all:
	for targ in $(TARGET_LIST); do \
		$(MAKE) clean TARGET=$$targ; \
	done
	$(MAKE) -C $(IP_DIR) clean_all
	$(RM) .Xil vivado*.log vivado*.jou

check_target:
ifndef $(TARGET)_target
	$(error "Please specify a TARGET. Use 'make help' to see valid targets.")
endif


