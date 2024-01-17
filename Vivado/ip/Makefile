# Opsero Electronic Design Inc. 2024
# 
# TODO: This Makefile would ideally be able to build through a list of multiple IPs for the target design.

RM = rm -rf
VIVADO = $(XILINX_VIVADO)/bin/vivado
HLS = vitis_hls

GET_PART_SCRIPT = get_part.tcl
GET_PART_LOG = vivado_$(TARGET).log
GET_PART_JOU = vivado_$(TARGET).jou

# valid targets
zcu104_target := xilinx.com zcu104
zcu102_hpc0_target := xilinx.com zcu102
zcu102_hpc1_target := xilinx.com zcu102
zcu106_hpc0_target := xilinx.com zcu106
pynqzu_target := tul.com.tw pynqzu
genesyszu_target := digilentinc.com gzu_5ev
uzev_target := avnet.com ultrazed_7ev_cc

TARGET_LIST := $(sort $(patsubst %_target,%,$(filter %_target,$(.VARIABLES))))

BOARD_URL = $(word 1,$($(TARGET)_target))
BOARD_NAME = $(word 2,$($(TARGET)_target))

IP_BUILD_DIR = build/$(BOARD_NAME)
SETTINGS_TCL = $(IP_BUILD_DIR)/settings.tcl
DONE_FILE = $(IP_BUILD_DIR)/ip_done.txt

.PHONY: help
help:
	@echo 'Usage:'
	@echo ''
	@echo '  make ip TARGET=<val>'
	@echo '    Generate all IP for target project.'
	@echo ''
	@echo '  make clean TARGET=<val>'
	@echo '    Clean IP for target project.'
	@echo ''
	@echo '  make clean_all'
	@echo '    Same as make clean but for all targets.'
	@echo ''
	@echo 'Parameters:'
	@echo ''
	@echo '  TARGET: Name of the target design, must be one of the following:'
	@$(foreach targ,$(TARGET_LIST),echo "    - $(targ)";)
	@echo ''
	@echo 'Example usage:'
	@echo '  make ip TARGET=$(word 1,$(TARGET_LIST))'
	@echo ''

.PHONY: all
all: ip

$(SETTINGS_TCL):
	$(VIVADO) -mode batch -notrace -source $(GET_PART_SCRIPT) -log $(GET_PART_LOG) -journal $(GET_PART_JOU) -tclargs $(BOARD_URL) $(BOARD_NAME)
	$(RM) $(GET_PART_LOG) $(GET_PART_JOU)

ip: $(SETTINGS_TCL)
	$(HLS) -f isppipeline/run_hls.tcl $(BOARD_NAME)
	touch $(DONE_FILE)

.PHONY: clean
clean: check_target
	@echo 'Cleaning IP for $(TARGET)'
	$(RM) $(IP_BUILD_DIR) *.log

.PHONY: clean_all
clean_all:
	@echo 'Cleaning all IP'
	$(RM) build *.log

check_target:
ifndef $(TARGET)_target
	$(error "Please specify a TARGET. Use 'make help' to see valid targets.")
endif

