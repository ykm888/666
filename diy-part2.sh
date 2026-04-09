#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
OUTPUT_DIR="$WORKSPACE/output"
IMMORTALWRT_BUILD="$(cat "$WORKSPACE/build-dir.txt")"

ATF_DIR="$WORKSPACE/atf-src"
UBOOT_DIR="$WORKSPACE/uboot-src"

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

echo "=== 进入 ImmortalWrt 构建目录 ==="
cd "$IMMORTALWRT_BUILD"

echo "=== 删除 mt76（救砖不需要） ==="
rm -rf package/kernel/mt76 || true

echo "=== 构建 initramfs 救砖固件 ==="
make -j"$(nproc)" V=s

FIRMWARE_DIR="bin/targets/mediatek/filogic"
mkdir -p "$OUTPUT_DIR/firmware"
cp -vf "$FIRMWARE_DIR"/* "$OUTPUT_DIR/firmware/" || true

echo "=== 拉取 ATF / U-Boot 源 ==="
mkdir -p "$ATF_DIR" "$UBOOT_DIR" "$OUTPUT_DIR/atf" "$OUTPUT_DIR/uboot"

git clone -b mtksoc-20260123 https://github.com/mtk-openwrt/arm-trusted-firmware.git "$ATF_DIR"
git clone -b mtksoc-20250711 https://github.com/mtk-openwrt/u-boot.git "$UBOOT_DIR"

tar -czf "$OUTPUT_DIR/atf/arm-trusted-firmware-mtksoc-20260123-src.tar.gz" -C "$ATF_DIR" .
tar -czf "$OUTPUT_DIR/uboot/u-boot-mtksoc-20250711-src.tar.gz" -C "$UBOOT_DIR" .

echo "=== diy-part2.sh 完成 ==="
