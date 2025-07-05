#!/bin/bash
#  ██████╗ ██████╗ ██╗   ██╗██████╗ 
# ██╔════╝ ██╔══██╗██║   ██║██╔══██╗
# ██║  ███╗██████╔╝██║   ██║██████╔╝
# ██║   ██║██╔══██╗██║   ██║██╔══██╗
# ╚██████╔╝██║  ██║╚██████╔╝██████╔╝
#  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ 

set -euo pipefail                            

git clone https://github.com/vinceliuice/Elegant-grub2-themes
cd Elegant-grub2-themes
sudo ./install.sh -b -t mojave -i right
rm -rf Elegant-grub2-themes