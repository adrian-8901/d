#!/bin/bash

#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/liquidprjkt/liquid_kernel_xiaomi_sm8250.git liquid
mv liquid/* .
git clone --depth=1 https://gitlab.com/dakkshesh07/neutron-clang.git -b Neutron-14  clang
git clone https://github.com/sohamxda7/llvm-stable -b gcc64 --depth=1 gcc
git clone https://github.com/sohamxda7/llvm-stable -b gcc32  --depth=1 gcc32
git clone --depth=1 https://github.com/adrian-8901/AnyKernel3 AnyKernel
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%Y%m%d")
START=$(date +"%s")
KERNEL_DIR=$(pwd)
PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_HOST=liquid-ci
export KBUILD_BUILD_USER="P4042"
chat_id="-1001542481275"
priv_chat_id="-1001542481275"
token="5389275341:AAFtB8oBu3KUO2_EY68XwQ-mEwBXPOEp64A"

# Send info plox channel
sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• liquid° Kernel •</b>%0Astarted on: <code>liquidCI</code>%0Adevice: <b>Xiaomi Mi 10</b>%0Abranch: <code>$(git rev-parse --abbrev-ref HEAD)</code>%0Acompiler: <code>${KBUILD_COMPILER_STRING}</code>%0Astart date: <code>$(date)</code>"
}

# Push kernel to channel
push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$priv_chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Xiaomi Mi 10</b>"
}

# Fin Error
finerr() {
    curl -F document=@$(echo *.log) "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {
    make O=out ARCH=arm64 vendor/umi_defconfig
    make -j$(nproc --all) O=out \
                    ARCH=arm64 \
                    CC=clang \
                    CLANG_TRIPLE=aarch64-linux-gnu- \
                    CROSS_COMPILE=aarch64-linux-android- \
                    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
                    V=0 2>&1 | tee build.log
    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 liquid-umi-${TANGGAL}.zip *
    cd ..
}
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
