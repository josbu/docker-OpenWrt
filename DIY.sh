#!/bin/bash

CUSTOM_SOURCE_ARCH=
CUSTOM_IPK_ARCH=
ARCH=

if [ "$TARGET" = "x86_64" ]; then
    CUSTOM_IPK_ARCH=x86_64
    CUSTOM_SOURCE_ARCH="x86/64"
    ARCH=amd64
elif [ "$TARGET" = "rockchip" ]; then
    ARCH=armv8
    CUSTOM_IPK_ARCH=aarch64_generic
    CUSTOM_SOURCE_ARCH="rockchip/armv8"
elif [ "$TARGET" = "ar71xx_nand" ]; then
    ARCH=mips-softfloat
    CUSTOM_IPK_ARCH=mips_24kc
    CUSTOM_SOURCE_ARCH="ar71xx/nand"

    cp config/wireless files/etc/config/wireless

fi

echo "src/gz simonsmh https://github.com/simonsmh/openwrt-dist/raw/packages/${CUSTOM_SOURCE_ARCH}" >> ./repositories.conf
echo "src/gz passwall https://gh-proxy.imciel.com/https://github.com/${PASSWALL_SOURCE}/blob/19.07.7/packages/${CUSTOM_SOURCE_ARCH}" >> ./repositories.conf

cp custom/keys/* keys

# https://github.com/Dreamacro/clash/releases/tag/premium
CLASH_TUN_RELEASE_DATE=2021.04.08
# https://github.com/comzyh/clash/releases
CLASH_GAME_RELEASE_DATE=20210310
# https://github.com/Dreamacro/clash/releases
CLASH_VERSION=1.5.0

work_dir=$(pwd)

# Add third-party package


cd $work_dir

sudo -E apt-get -qq install gzip

cd files/etc/clash/

function download_clash_binaries() {
    local url=$1
    local binaryname=$2
    local dist=$3
    wget $url

    if [ "$dist" != "" ];then
        mkdir -p $dist
        pushd $dist
    fi
    
    local filename="${url##*/}"
    gunzip -c $filename > $binaryname
    chmod +x $binaryname

    if [ "$dist" != "" ];then
        popd
    fi

    rm $filename
}

function download_xray() {
    mkdir /tmp/download_xray
    pushd /tmp/download_xray

    url=https://github.com/XTLS/Xray-core/releases/download/v1.4.2/Xray-linux-64.zip
    wget $url
    local filename="${url##*/}"
    unzip $filename
    mkdir -p /home/build/openwrt/files/usr/bin/xray
    cp xray /home/build/openwrt/files/usr/bin/xray
    mkdir -p /home/build/openwrt/files/usr/share/xray/
    cp geosite.dat /home/build/openwrt/files/usr/share/xray/
    cp geoip.dat /home/build/openwrt/files/usr/share/xray/
    popd
}

# rm -rf *

# download_clash_binaries https://github.com/Dreamacro/clash/releases/download/v${CLASH_VERSION}/clash-linux-${ARCH}-v${CLASH_VERSION}.gz clash
# if [ "$TARGET" != "ar71xx_nand" ]; then
#     download_clash_binaries https://github.com/Dreamacro/clash/releases/download/premium/clash-linux-${ARCH}-${CLASH_TUN_RELEASE_DATE}.gz clash ./dtun/
#     download_clash_binaries https://github.com/comzyh/clash/releases/download/${CLASH_GAME_RELEASE_DATE}/clash-linux-${ARCH}-${CLASH_GAME_RELEASE_DATE}.gz clash ./clashtun/
# fi

download_xray

cd $work_dir

function download_missing_ipks() {
    local url=$1
    local binaryname=$2
    wget $url
    
    local filename="${url##*/}"

    cp $filename ./packages/$filename
    rm $filename
}


if [ "$OPENWRT_VERSION" = "19.07" ]; then
    download_missing_ipks https://downloads.openwrt.org/releases/packages-21.02/${CUSTOM_IPK_ARCH}/packages/libcap_2.43-1_${CUSTOM_IPK_ARCH}.ipk
    download_missing_ipks https://downloads.openwrt.org/releases/packages-21.02/${CUSTOM_IPK_ARCH}/packages/libcap-bin_2.43-1_${CUSTOM_IPK_ARCH}.ipk
    download_missing_ipks https://github.com/jerrykuku/luci-theme-argon/releases/download/v2.2.5/luci-theme-argon_2.2.5-20200914_all.ipk
fi

cat system-custom.tpl  | sed "s/CUSTOM_PPPOE_USERNAME/$CUSTOM_PPPOE_USERNAME/g" | sed "s/CUSTOM_PPPOE_PASSWORD/$CUSTOM_PPPOE_PASSWORD/g" | sed "s/CUSTOM_LAN_IP/$CUSTOM_LAN_IP/g" | sed "s~CUSTOM_CLASH_CONFIG_URL~$CUSTOM_CLASH_CONFIG_URL~g" | sed "s~CUSTOM_PASSWALL_SUBSCRIBE_URL~$CUSTOM_PASSWALL_SUBSCRIBE_URL~g" >  files/etc/uci-defaults/system-custom

mkdir packages
cp custom_packages/* ./packages/
ls ./packages/
