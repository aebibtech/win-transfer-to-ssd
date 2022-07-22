# Transfer Windows to new SSD
Transfers an existing Windows installation to an empty SSD. This is useful for people who are adding a Solid State Disk with an existing HDD.

## Usage
1. Clone this repo. Put it in your WinPE boot disk (or Windows Install USB disk).
2. Boot into WinPE. For a Windows Install USB disk, press `Shift F10` at the same time when the Windows install screen appears.
3. Run `main.cmd`.

## What do these scripts do?
1. Create an image of an existing Windows install.
2. **User Shell Folders (Desktop, Documents, Downloads, etc.)** are excluded from the image.
3. Initialize an empty disk. (Disks with partition style of RAW)
4. Apply the image that was previously created to the empty disk.
5. Run `bcdboot.exe`.

## Notes
You can customize what directories are to be excluded from the image by modifying the `wimscript.ini` file. Refer to Microsoft's [documentation](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-configuration-list-and-wimscriptini-files-winnext?view=windows-11).
