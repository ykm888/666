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

echo "=== 清理不必要的无线驱动（救砖不需要） ==="
if [ -d package/kernel/mt76 ]; then
  rm -rf package/kernel/mt76
  echo "✅ 已删除 mt76"
fi

echo "=== 开始构建救砖固件（initramfs） ==="
make -j"$(nproc)" V=s

FIRMWARE_DIR="bin/targets/mediatek/filogic"
if [ -d "$FIRMWARE_DIR" ]; then
  mkdir -p "$OUTPUT_DIR/firmware"
  cp -vf "$FIRMWARE_DIR"/* "$OUTPUT_DIR/firmware/" || true
  echo "✅ 已复制固件到 output/firmware"
else
  echo "❌ 未找到固件目录：$FIRMWARE_DIR"
fi

echo "=== 拉取并打包 ATF / U-Boot 源（使用你指定的底层仓库） ==="
mkdir -p "$ATF_DIR" "$UBOOT_DIR" "$OUTPUT_DIR/atf" "$OUTPUT_DIR/uboot"

if [ ! -d "$ATF_DIR/.git" ]; then
  git clone -b mtksoc-20260123 https://github.com/mtk-openwrt/arm-trusted-firmware.git "$ATF_DIR"
fi

if [ ! -d "$UBOOT_DIR/.git" ]; then
  git clone -b mtksoc-20250711 https://github.com/mtk-openwrt/u-boot.git "$UBOOT_DIR"
fi

tar -czf "$OUTPUT_DIR/atf/arm-trusted-firmware-mtksoc-20260123-src.tar.gz" -C "$ATF_DIR" .
tar -czf "$OUTPUT_DIR/uboot/u-boot-mtksoc-20250711-src.tar.gz" -C "$UBOOT_DIR" .

echo "✅ 已打包 ATF / U-Boot 源到 output/atf 与 output/uboot"

echo "=== diy-part2.sh 完成 ==="
