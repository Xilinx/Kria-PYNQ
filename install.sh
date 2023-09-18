#!/bin/bash

# Copyright (C) 2021 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

set -e

GRAY='\033[1;30m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]
  then echo -e "${RED}Please run as root${NC}"
  exit
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#    Input Arguments
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
USAGE="${RED} usage: ${NC}  sudo ./install -b '{KV260 | KR260 | KD240}'"

if [ "$#" -ne 2 ]; then
   echo -e $USAGE
   exit 0 
fi

while getopts b: flag
do
    case "${flag}" in
        b) board=${OPTARG};;
        *) echo -e $USAGE; exit 0;;
    esac
done

case $board in
	"KV260") echo -e ;;
	"KR260") echo -e ;;
	"KD240") echo -e ;;
	*) echo -e $USAGE; exit 0;;
esac
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

source /etc/lsb-release
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#    Check ubuntu version 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
case $DISTRIB_RELEASE in
        20.04)
                echo -e "${RED}This version of Kria-PYNQ is not compatible with Ubuntu 20.04 please checkout tag v1.0 with the command${NC}"
                echo -e "\n\t\tgit checkout tags/v1.0\n"
                exit 1
                ;;
        22.04)
                echo -e "${GREEN}Ubuntu version 22.04 and Kria-PYNQ v3.0 version match${NC}"
                ;;
        *)
                echo -e "${RED}Incompatible version of Ubuntu with Kria-PYNQ. Or unable to determine distribution version from /etc/lsb-release${NC}"
                exit 1
                ;;
esac


echo -e "${GREEN}Installing PYNQ, this process takes around 25 minutes ${NC}"

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#    Autorestart services
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

echo -e "${YELLOW} Extracting archive pynq-v3.0-binaries.tar.gz${NC}"
# Get the pynq binaries
wget https://www.xilinx.com/bin/public/openDownload?filename=pynq-v3.0-binaries.tar.gz -O /tmp/pynq-v3.0-binaries.tar.gz
pushd /tmp
if [ $(file --mime-type -b pynq-v3.0-binaries.tar.gz) != "application/gzip" ]; then
  echo -e "${RED}Could not extract pynq binaries, is the tarball named correctly?${NC}\n"
  exit
fi
tar -xvf pynq-v3.0-binaries.tar.gz
popd

ARCH=aarch64
HOME=/root
PYNQ_JUPYTER_NOTEBOOKS=/home/$LOGNAME/jupyter_notebooks
BOARD=$board
PYNQ_VENV=/usr/local/share/pynq-venv

# Get PYNQ SDbuild Packages
git config --global --add safe.directory $(pwd)
git config --global --add safe.directory $(pwd)/pynq
if [ -d ".git/" ]
then
  git submodule init && git submodule update
else
  rm -rf pynq/
  git clone https://github.com/Xilinx/PYNQ.git --branch v3.0.1 --depth 1 pynq
fi


# Stop unattended upgrades to prevent apt install from failing
systemctl stop unattended-upgrades.service

# Wait for Ubuntu to finish unattended upgrades
while [[ $(lsof -w /var/lib/dpkg/lock-frontend) ]] || [[ $(lsof -w /var/lib/apt/lists/lock) ]]
do
  echo -e "${YELLOW}Waiting for Ubuntu unattended upgrades to finish ${NC}"
  sleep 20s
done

# Install Required Debian Packages
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 \
	        --verbose 803DDF595EA7B6644F9B96B752150A179A9E84C9
echo "deb http://ppa.launchpad.net/ubuntu-xilinx/updates/ubuntu jammy main" > /etc/apt/sources.list.d/xilinx-gstreamer.list
apt update 

apt-get -o DPkg::Lock::Timeout=10 update && \
apt-get install -y python3.10-venv python3-cffi libssl-dev libcurl4-openssl-dev \
  portaudio19-dev libcairo2-dev libdrm-xlnx-dev libopencv-dev python3-opencv graphviz i2c-tools \
  fswebcam libboost-all-dev python3-dev python3-pip

# Install PYNQ Virtual Environment 
pushd pynq/sdbuild/packages/python_packages_jammy
mkdir -p $PYNQ_VENV
cat > $PYNQ_VENV/pip.conf <<EOT
[install]
no-build-isolation = yes
EOT
./pre.sh
./qemu.sh
popd

# PYNQ VENV Activate Updates
echo "export PYNQ_JUPYTER_NOTEBOOKS=${PYNQ_JUPYTER_NOTEBOOKS}" >> /etc/profile.d/pynq_venv.sh
echo "export BOARD=$BOARD" >> /etc/profile.d/pynq_venv.sh
echo "export XILINX_XRT=/usr" >> /etc/profile.d/pynq_venv.sh
source /etc/profile.d/pynq_venv.sh

# Check to makesure that we are in the venv before proceeding.
if [[ "$VIRTUAL_ENV" == "" ]]
then
        echo "ERROR: could not enter the Pynq venv, stopping the installation"
        exit 1
fi

# Installing PYNQ-Metadata
python3 -m pip install pynqmetadata==0.1.2 

# Install PYNQ-Utils
python3 -m pip install pynqutils==0.1.1 

# PYNQ JUPYTER
pushd pynq/sdbuild/packages/jupyter
./pre.sh
./qemu.sh
popd

# PYNQ Allocator
pushd pynq/sdbuild/packages/libsds
./pre.sh
./qemu.sh
popd

# Install PYNQ-3.0.1
python3 -m pip install pynq==3.0.1

## GCC-MB and XCLBINUTILS
pushd /tmp

cp -r /tmp/pynq-v3.0-binaries/gcc-mb/microblazeel-xilinx-elf /usr/local/share/pynq-venv/bin/
echo "export PATH=\$PATH:/usr/local/share/pynq-venv/bin/microblazeel-xilinx-elf/bin/" >> /etc/profile.d/pynq_venv.sh

cp /tmp/pynq-v3.0-binaries/xrt/xclbinutil /usr/local/share/pynq-venv/bin/
chmod +x /usr/local/share/pynq-venv/bin/xclbinutil
popd

# define the name of the platform
echo "$BOARD" > /etc/xocl.txt

# Compile pynq device tree overlay and insert it by default
pushd dts/
make
mkdir -p /usr/local/share/pynq-venv/pynq-dts/
cp insert_dtbo.py pynq.dtbo /usr/local/share/pynq-venv/pynq-dts/
echo "python3 /usr/local/share/pynq-venv/pynq-dts/insert_dtbo.py" >> /etc/profile.d/pynq_venv.sh

source /etc/profile.d/pynq_venv.sh
popd

# =================== Notebooks ===========================
# Install example notebooks using the board 
# flag to determine which packages are loaded 
# onto which board.
# =========================================================

if [[ "$board" == "KV260" ]]
then
	echo "KV260 notebooks"
	#Install PYNQ-HelloWorld
	python3 -m pip install pynq_helloworld --no-build-isolation 

	#Install base overlay
	python3 -m pip install .
	
	# Install composable overlays
	pushd /tmp
	rm -rf ./PYNQ_Composable_Pipeline
	git clone https://github.com/Xilinx/PYNQ_Composable_Pipeline.git -b v1.1.0-dev
	#git clone https://github.com/Xilinx/PYNQ_Composable_Pipeline.git 
	python3 -m pip install PYNQ_Composable_Pipeline/ --no-use-pep517
	popd

	# Install Pynq Peripherals
	python3 -m pip install git+https://github.com/Xilinx/PYNQ_Peripherals.git

	# Install DPU-PYNQ
	yes Y | apt remove --purge vitis-ai-runtime
	python3 -m pip install pynq-dpu==2.5 --no-build-isolation
fi

if [[ "$board" == "KR260" ]]
then
	echo "KR260 notebooks"
	#Install PYNQ-HelloWorld
	python3 -m pip install pynq_helloworld --no-build-isolation 

	# Install DPU-PYNQ
	yes Y | apt remove --purge vitis-ai-runtime
	python3 -m pip install pynq-dpu==2.5 --no-build-isolation
fi

if [[ "$board" == "KD240" ]]
then
      python3 -m pip install IPython # I'm not sure if this is required?
      git clone https://github.com/MakarenaLabs/DPU-PYNQ.git
      pushd DPU-PYNQ
      pip3 install -e . --no-build-isolation
      
      # copy the notebooks
      cp -r pynq_dpu/kd240_notebooks /home/root/jupyter_notebooks/
      cp pynq_dpu/kd240_notebooks/dpu.* /usr/lib
      popd
fi

# Deliver all notebooks
yes Y | pynq-get-notebooks -p $PYNQ_JUPYTER_NOTEBOOKS -f

# Copy additional notebooks from pynq
cp pynq/pynq/notebooks/common/ -r $PYNQ_JUPYTER_NOTEBOOKS

# =========================================================

# Patch notebooks
sed -i "s/\/home\/xilinx\/jupyter_notebooks\/common/\./g" $PYNQ_JUPYTER_NOTEBOOKS/common/python_random.ipynb
sed -i "s/\/home\/xilinx\/jupyter_notebooks\/common/\./g" $PYNQ_JUPYTER_NOTEBOOKS/common/usb_webcam.ipynb


for notebook in $PYNQ_JUPYTER_NOTEBOOKS/common/*.ipynb; do
    sed -i "s/pynq.overlays.base/kv260/g" $notebook
    sed -i "s/PMODB/PMODA/g" $notebook
done

if [[ "$board" == "KV260" ]]
then
	for notebook in $PYNQ_JUPYTER_NOTEBOOKS/pynq_peripherals/*/*.ipynb; do
	    sed -i "s/pynq.overlays.base/kv260/g" $notebook
	    sed -i "s/PMODB/PMODA/g" $notebook
	done
fi

sed -i 's/Specifically a RALink WiFi dongle commonly used with \\n//g' $PYNQ_JUPYTER_NOTEBOOKS/common/wifi.ipynb
sed -i 's/Raspberry Pi kits is connected into the board.//g' $PYNQ_JUPYTER_NOTEBOOKS/common/wifi.ipynb

# Patch microblaze to use virtualenv libraries
sed -i "s/opt\/microblaze/usr\/local\/share\/pynq-venv\/bin/g" /usr/local/share/pynq-venv/lib/python3.10/site-packages/pynq/lib/pynqmicroblaze/rpc.py

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Remove unnecessary notebooks
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

if [[ "$board" == "KV260" ]]
then
	rm -rf $PYNQ_JUPYTER_NOTEBOOKS/pynq_peripherals/app* $PYNQ_JUPYTER_NOTEBOOKS/pynq_peripherals/grove_joystick
fi

if [[ "$board" == "KR260" ]]
then
	rm -rf $PYNQ_JUPYTER_NOTEBOOKS/common/zynq_clocks.ipynb	
	rm -rf $PYNQ_JUPYTER_NOTEBOOKS/common/overlay_download.ipynb	
fi
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# Change notebooks folder ownership and permissions
chown $LOGNAME:$LOGNAME -R $PYNQ_JUPYTER_NOTEBOOKS
chmod ugo+rw -R $PYNQ_JUPYTER_NOTEBOOKS

# Start Jupyter services 
systemctl start jupyter.service

# Start the service for clearing the statefile on boot
cp pynq/sdbuild/packages/clear_pl_statefile/clear_pl_statefile.sh /usr/local/bin
cp pynq/sdbuild/packages/clear_pl_statefile/clear_pl_statefile.service /lib/systemd/system
systemctl enable clear_pl_statefile

# OpenCV
python3 -m pip install opencv-python
apt-get install ffmpeg libsm6 libxext6 -y

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#    Selftest generation
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
python3 -m pip install pytest

echo "#!/bin/bash" > selftest.sh
echo "if [ \"\$EUID\" -ne 0 ]" >> selftest.sh
echo "  then echo -e \"\${RED}Please run as root\${NC}\"" >> selftest.sh
echo "  exit" >> selftest.sh
echo "fi" >> selftest.sh
echo "source /etc/profile.d/pynq_venv.sh" >> selftest.sh

if [[ "$board" == "KV260" ]]
then
	echo "pushd /usr/local/share/pynq-venv/lib/python3.10/site-packages/pynq_composable/runtime_tests" >> selftest.sh
	echo "python3 -m pytest test_apps.py" >> selftest.sh
	echo "python3 -m pytest test_composable.py" >> selftest.sh
	echo "python3 -m pytest test_mmio_partial_bitstreams.py" >> selftest.sh
	echo "popd" >> selftest.sh
	echo "python3 -m pytest /usr/local/share/pynq-venv/lib/python3.10/site-packages/pynq_dpu/tests" >> selftest.sh
fi

if [[ "$board" == "KR260" ]]
then
	echo "python3 -m pytest /usr/local/share/pynq-venv/lib/python3.10/site-packages/pynq_dpu/tests" >> selftest.sh
fi
chmod a+x ./selftest.sh
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Ask to connect to Jupyter
ip_addr=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo -e "${GREEN}PYNQ Installation completed.${NC}\n"
echo -e "\n${YELLOW}To continue with the PYNQ experience, connect to JupyterLab via a web browser using this url: ${ip_addr}:9090/lab or $(hostname):9090/lab - The password is xilinx${NC}\n"
