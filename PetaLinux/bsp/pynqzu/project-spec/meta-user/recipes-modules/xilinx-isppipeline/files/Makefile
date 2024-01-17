#
# Copyright (c) 2022. Xilinx.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

SRC := $(shell pwd)

obj-m += xilinx-isppipeline.o
##CFLAGS_xilinx-isppipeline.o += -I/usr/src/linux-xilinx-zynqmp-headers-5.15.0-1003/include/

EXTRA_CFLAGS += -I$(KERNEL_SRC)/include/linux
EXTRA_CFLAGS += -I$(KERNEL_SRC)/arch/arm64/include/
EXTRA_CFLAGS += -I$(KERNEL_SRC)/arch/arm64/include/generated/
EXTRA_CFLAGS += -I$(KERNEL_SRC)/arch/arm64/include/generated/uapi/
EXTRA_CFLAGS += -I$(KERNEL_SRC)/arch/arm64/include/uapi/

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) modules

modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules_install

clean:
	rm -f *.o *~ core .depend .*.cmd *.ko *.mod.c
	rm -f Module.markers Module.symvers modules.order modules.builtin
	rm -f */*.ko */*.mod.c */.*.mod.c */.*.cmd */*.o
	rm -f */modules.order */modules.builtin
	rm -rf .tmp_versions Modules.symvers
