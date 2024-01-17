# Opsero Electronic Design Inc. 2024
# ----------------------------------
# This script must be run with Vivado batch mode. The script is passed the board URL 
# and board name and it uses that information to get the device part for that board. The script then 
# creates a Tcl file that will later be called by the run_hls.tcl script to build the IP for that board.

# Add Xilinx board store to the repo paths
set_param board.repoPaths [get_property LOCAL_ROOT_DIR [xhub::get_xstores xilinx_board_store]]

# Board url and name must be fed as command line arguments
set board_url [lindex $argv 0]
set board_name [lindex $argv 1]

# Get the part name from the board URL and board name
set proj_board [get_board_parts "$board_url:$board_name:*" -latest_file_version]
# Check if the board files are installed, if not, install them
if { $proj_board == "" } {
    puts "Failed to find board files for $board_name. Installing board files..."
    xhub::refresh_catalog [xhub::get_xstores xilinx_board_store]
    xhub::install [xhub::get_xitems $board_url:xilinx_board_store:$board_name*]
    set proj_board [get_board_parts "$board_url:$board_name:*" -latest_file_version]
} else {
    puts "Board files found for $board_name"
}

set XPART [get_property PART_NAME [get_board_parts $proj_board]]

# Create the Tcl script that run_hls.tcl will call

# Set the directory and file names
set directory "build/$board_name"

# Check if the directory exists, create if it does not
if { ![file exists $directory] } {
    file mkdir $directory
}

set filename "settings.tcl"
set filepath "$directory/$filename"
set file [open $filepath "w"]
puts $file "set XPART $XPART"
puts $file ""
close $file

