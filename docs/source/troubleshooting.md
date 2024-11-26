# Troubleshooting

## Build failures

Check the following if the project fails to build or generate a bitstream:

1. **Are you using the correct version of Vivado for this version of the repository?**   
   Check the version specified in the Requirements section of the README.md file.

2. **Did you follow the** [build instructions](build_instructions) **?**   
   If it still doesn't build, please let us know and provide details of your setup and the error message(s).

## Monitor resolution limited to 1080p

If using a 2K resolution DisplayPort monitor with the UltraZed EV carrier, you may find that
it can only be used at 1080p or less resolution. This is due to the fact that the UltraZed EV
carrier has only a single lane connected to the DisplayPort connector, and not all DisplayPort
monitors are able to support resolutions of 1080p and higher over a single lane.
