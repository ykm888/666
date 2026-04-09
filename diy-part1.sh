#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
MAIN_DIR="$WORKSPACE/main-repo"
OUTPUT_DIR="$WORKSPACE/output"
IMMORTALWRT_BUILD="$WORKSPACE/immortalwrt-build"
CONFIG_DIR="$MAIN_DIR/888"

DTS_PATH_NEW="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
IMAGE_888_DIR="target/linux/mediatek/image/888"
FILOGIC_MK="target/linux/mediatek/image/filogic.mk"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/atf" "$OUTPUT_DIR/uboot" "$OUTPUT_DIR/firmware"

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

echo "=== 验证 888 三件套 ==="
if [ ! -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ]; then
  echo "❌ 缺少 $CONFIG_DIR/mt7981b-sl3000-emmc.dts"
  exit 1
fi
if [ ! -f "$CONFIG_DIR/mt7981_sl3000.mk" ]; then
  echo "❌ 缺少 $CONFIG_DIR/mt7981_sl3000.mk"
  exit 1
fi
if [ ! -f "$CONFIG_DIR/sl3000.config" ]; then
  echo "❌ 缺少 $CONFIG_DIR/sl3000.config"
  exit 1
fi
echo "✅ 888 三件套齐全"

echo "=== 准备 ImmortalWrt 源码 ==="
cd "$WORKSPACE"
rm -rf "$IMMORTALWRT_BUILD"
cp -r "$SOURCE_DIR/immortalwrt" "$IMMORTALWRT_BUILD"
cd "$IMMORTALWRT_BUILD"

# 禁用 telephony feed（避免无关包）
sed -i 's/^src-git telephony/#src-git telephony/g' feeds.conf.default || true

./scripts/feeds update -a
./scripts/feeds install -a
make package/symlinks

echo "=== 注册 DTS 与 image mk ==="
mkdir -p "$DTS_PATH_NEW"
mkdir -p "$IMAGE_888_DIR"

cp -vf "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$DTS_PATH_NEW/"

cp -vf "$CONFIG_DIR/mt7981_sl3000.mk" "$IMAGE_888_DIR/"

if ! grep -q "image/888/mt7981_sl3000.mk" "$FILOGIC_MK"; then
  echo 'include ./image/888/mt7981_sl3000.mk' >> "$FILOGIC_MK"
  echo "✅ 已在 filogic.mk 中注册 888/mt7981_sl3000.mk"
else
  echo "ℹ️ filogic.mk 已包含 888/mt7981_sl3000.mk"
fi

echo "=== 注入救砖配置 .config ==="
cp -vf "$CONFIG_DIR/sl3000.config" .config
make defconfig

pwd > "$WORKSPACE/build-dir.txt"

echo "✅ diy-part1.sh 完成"
