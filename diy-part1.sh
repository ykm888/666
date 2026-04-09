#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
MAIN_DIR="$WORKSPACE/main-repo"
CONFIG_DIR="$MAIN_DIR/888"
OUTPUT_DIR="$WORKSPACE/output"
IMMORTALWRT_BUILD="$WORKSPACE/immortalwrt-build"

DTS_PATH_NEW="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
IMAGE_DIR="target/linux/mediatek/image"
FILOGIC_MK="$IMAGE_DIR/filogic.mk"

mkdir -p "$OUTPUT_DIR" "$OUTPUT_DIR/atf" "$OUTPUT_DIR/uboot" "$OUTPUT_DIR/firmware"

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

echo "=== [CHECK] 888 三件套 ==="
ls -la "$CONFIG_DIR"

[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] || exit 1
[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ]        || exit 1
[ -f "$CONFIG_DIR/sl3000.config" ]           || exit 1

echo "=== 准备 ImmortalWrt 24.10 ==="
cd "$WORKSPACE"
rm -rf "$IMMORTALWRT_BUILD"
cp -r "$SOURCE_DIR" "$IMMORTALWRT_BUILD"

cd "$IMMORTALWRT_BUILD"

sed -i 's/^src-git telephony/#src-git telephony/g' feeds.conf.default || true

./scripts/feeds update -a
./scripts/feeds install -a
make package/symlinks

echo "=== 注入 DTS ==="
mkdir -p "$DTS_PATH_NEW"
cp -vf "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$DTS_PATH_NEW/"

echo "=== 注入 image mk ==="
cp -vf "$CONFIG_DIR/mt7981_sl3000.mk" "$IMAGE_DIR/"

if ! grep -q "mt7981_sl3000.mk" "$FILOGIC_MK"; then
  echo 'include ./mt7981_sl3000.mk' >> "$FILOGIC_MK"
  echo "已写入 filogic.mk include"
fi

echo "=== 注入救砖 config ==="
cp -vf "$CONFIG_DIR/sl3000.config" .config
make defconfig

pwd > "$WORKSPACE/build-dir.txt"

echo "=== diy-part1.sh 完成 ==="
