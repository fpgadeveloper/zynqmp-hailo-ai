# Opsero Electronic Design Inc. 2024
#

CURR_DIR = $(shell pwd)
KERNEL_NAME = v_multi_scaler
MULTISCALER_DIR = $(CURR_DIR)/$(KERNEL_NAME)
MULTISCALER_SRC = $(MULTISCALER_DIR)/src
MULTISCALER_HLS = $(MULTISCALER_SRC)/hls
MULTISCALER_DEPS = $(MULTISCALER_SRC)/v_multi_scaler.cpp $(MULTISCALER_SRC)/v_hresampler.cpp $(MULTISCALER_SRC)/v_hscaler.cpp $(MULTISCALER_SRC)/v_dma.cpp $(MULTISCALER_SRC)/v_csc.cpp $(MULTISCALER_SRC)/v_vresampler.cpp $(MULTISCALER_SRC)/v_vscaler.cpp

# Build collateral for all kernels for the specified target should go into BUILD_DIR
BUILD_DIR = $(CURR_DIR)/build
BUILD_TARGET_DIR = $(BUILD_DIR)/$(TARGET)
BUILD_KERNEL_DIR = $(BUILD_TARGET_DIR)/$(KERNEL_NAME)

TARGET_OPT := hw

XOCCFLAGS := --platform $(PLATFORM_FILE) -t $(TARGET_OPT) -s 

MULTISCALER_FLAGS := --kernel v_multi_scaler -I$(MULTISCALER_DIR) -I$(MULTISCALER_HLS)

# valid targets
zcu104_target := 0
zcu102_hpc0_target := 0
zcu102_hpc1_target := 0
zcu106_hpc0_target := 0
pynqzu_target := 0
genesyszu_target := 0
uzev_target := 0

TARGET_LIST := $(sort $(patsubst %_target,%,$(filter %_target,$(.VARIABLES))))

.PHONY: help
help::
	@echo ''
	@echo 'Usage:'
	@echo ''
	@echo '  make all PLATFORM_FILE=<val> TARGET=<val>'
	@echo '    Generate the kernels for the given target.'
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

all: v_multi_scaler.xo

v_multi_scaler.xo: $(MULTISCALER_DEPS)
	mkdir -p $(BUILD_KERNEL_DIR)
	cd $(BUILD_KERNEL_DIR) && v++ $(XOCCFLAGS) $(MULTISCALER_FLAGS) -c -o $@ $^

.PHONY: clean_all
clean_all:
	$(RM) -rf $(BUILD_DIR)

.PHONY: clean
clean: check_target
	$(RM) -rf $(BUILD_TARGET_DIR)

check_target:
ifndef $(TARGET)_target
	$(error "Please specify a TARGET. Use 'make help' to see valid targets.")
endif


