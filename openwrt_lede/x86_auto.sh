#!/bin/bash
###
 # @Author: 
 # @Date: 2024-01-16 19:15:38
 # @LastEditTime: 2024-01-23 20:16:55
 # @LastEditors:
 # @Description: 
 # @FilePath: \openwrt\ax86_auto.sh
###
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev \
libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
libssl-dev libtool lrzsz mkisofs msmtp ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 \
python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion swig texinfo \
uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
cd ..
cd ..
git clone https://github.com/findnr/x86_64.git
sudo chmod 777 /mnt
cd /mnt
file_path='x86'

if [ -e "$file_path" ]; then
    echo "x86 file exits"
else
    git clone https://github.com/coolsnowwolf/lede.git x86
fi
cd x86

rm -rf .config tmp
git restore package/base-files/files/bin/config_generate
git restore feeds.conf.default
git pull
# cd package/small-package
# git pull
# cd ..
# cd ..
sed -i '$a src-git istore https://github.com/linkease/istore;main' feeds.conf.default
sed -i '$a src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main' feeds.conf.default
#sed -i '$a src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main' feeds.conf.default
sed -i '$a src-git passwall2 https://github.com/xiaorouji/openwrt-passwall2.git;main' feeds.conf.default
sed -i '$a src-git helloworld https://github.com/fw876/helloworld.git' feeds.conf.default
# sed -i '$a src-git smpackage https://github.com/kenzok8/small-package' feeds.conf.default
./scripts/feeds uninstall -a
./scripts/feeds update -a
./scripts/feeds install -a
# 修改默认IP为 192.168.1.180
sed -i 's/192.168.1.1/192.168.1.181/g' package/base-files/files/bin/config_generate
sed -i "/set network.\$1.proto='static'/{s/$/\n\t\t\t\tset network.\$1.gateway='192.168.1.1'/}" package/base-files/files/bin/config_generate
sed -i "/set network.\$1.proto='static'/{s/$/\n\t\t\t\tset network.\$1.dns='223.5.5.5 192.168.1.1'/}" package/base-files/files/bin/config_generate
# 修改默认主机名
sed -i '/uci commit system/i\uci set system.@system[0].hostname='cym-router'' package/lean/default-settings/files/zzz-default-settings
# # 加入编译者信息
sed -i "s/OpenWrt /Cymrouter build $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt /g" package/lean/default-settings/files/zzz-default-settings
# 修改默认主题
#sed -i "s/luci-theme-bootstrap/luci-theme-argon/g" feeds/luci/collections/luci/Makefile

cat /home/runner/work/actions_os/x86_64/x86.conf > ./.config
# cat ../x86.conf > ./.config

sed -i 's/^[ \t]*//g' ./.config

make defconfig
# make menuconfig
make -j 4 V=s
