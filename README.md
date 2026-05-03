# IceNET.AI

### Development System ###

Description:	Ubuntu 22.04.5 LTS
Release:		22.04
Codename:		jammy

### System Requirements ###

1. Get and decompress Design resources

https://www.infineon.com/evaluation-board/cyusb3kit-003#design-resources

ezusbfx3sdk_1.3.5_Linux_x32-x64.tar.gz
infineon-first-fx3-app-developmenttools-en.zip
infineon-superspeed-explorer-kit-hardware-files-pcbdesigndata-en.zip

2. Link downloaded ARM compiler via bash.bashrc (replace the <path> with your path to the decompressed ARM_GCC.tar.gz file)

export PATH="<path>/arm-2013.11/bin:$PATH"

3. copy "cyusb.conf" from cyusb_linux_1.0.5.tar.gz into /etc/

cp cyusb_linux_1.0.5/configs/cyusb.conf /etc/

5. Use relative paths 

export PATH="<path>/arm-2013.11/bin:$PATH"

export PATH=/home/marek/code.lab/fx3/arm-2013.11/bin:$PATH
export FX3_INSTALL_PATH="/home/marek/code.lab/fx3/ezusbfx3sdk_1.3.5_Linux_x32-x64/cyfx3sdk"
export FX3SDKVERSION="1_3_5"

export CYUSB_ROOT=/home/marek/code.lab/fx3/ezusbfx3sdk_1.3.5_Linux_x32-x64/cyusb_linux_1.0.5
export LD_LIBRARY_PATH=$CYUSB_ROOT/lib:$LD_LIBRARY_PATH
export PATH=$CYUSB_ROOT/bin:$PATH

### Author ###

Marek Funtowicz 

