# UMRT CAN Definitions
This package defines the CAN messages used by the University of Manitoba Robotics Team.
Messages are defined in the PCAN symbol format.
PCAN-Symbol Editory 6 can be used to edit the definitions using a GUI, or the definitions can be edited by hand.
This format is selected over the more common DBC format because SYM is substantially more intuitive to understand without using fancy editors.

This package uses Python [cantools](https://cantools.readthedocs.io/en/latest/) to generate C code for working with the CAN messages.
For the host architecture, the generated code is compiled into a static library which can be linked in.
For use with other architectures, such as used embedded devices, the generated source is also included in the compiled package.