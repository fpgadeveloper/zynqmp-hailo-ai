# (C) Copyright 2020 - 2022 Xilinx, Inc.
# SPDX-License-Identifier: Apache-2.0

# Help function
proc help_proc { } {
  puts "Usage: xsct -sdx pfm.tcl -xsa <file>"
  puts "-xsa  <file>       xsa file location"
  puts "-proc <processor>  processor (default: psu_cortexa53)"
  puts "-targ <target>     target design name"
  puts "-help              this text"
}

# Set defaults
set platform "default"
set proc "psu_cortexa53"

# Parse arguments
for { set i 0 } { $i < $argc } { incr i } {
  # xsa file
  if { [lindex $argv $i] == "-xsa" } {
    incr i
    set xsafile [lindex $argv $i]
  # processor
  } elseif { [lindex $argv $i] == "-proc" } {
    incr i
    set proc [lindex $argv $i]
  # target
  } elseif { [lindex $argv $i] == "-targ" } {
    incr i
    set target [lindex $argv $i]
  # help
  } elseif { [lindex $argv $i] == "-help" } {
    help_proc
    exit
  # invalid argument
  } else {
    puts "[lindex $argv $i] is an invalid argument"
    exit
  }
}

# helper variables
set ws "${target}_workspace"
set platform $target
set imagedir "$ws/image"
file mkdir $imagedir
set bootdir "$ws/boot"
file mkdir $bootdir
set biffile "$ws/linux.bif"
set f [open $biffile a]
close $f

# Set workspace
setws $ws

# Create platform
platform create \
	-name $platform \
	-hw $xsafile

# Create domain
domain create \
	-name smp_linux \
	-os linux \
	-proc $proc

# Configure domain
domain config -sd-dir $imagedir
domain config -boot $bootdir
domain config -bif $biffile

# Configure platform
platform config -remove-boot-bsp

# Generate platform
platform -generate
