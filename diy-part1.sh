#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
MAIN_DIR="$WORKSPACE/main-repo"
CONFIG_DIR="$MAIN_DIR/888"
OUTPUT_DIR="$WORKSPACE/output"
IMMORTALWRT_BUILD="$WORKSPACE/immortalwrt-build"

# 【关键点 1】改用通用的 files 路径，并兼容 6.6 内核
DTS_BASE="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
# 底层构建可能直接在 dts 目录找，我们也放一份备份
DTS_RAW="target/linux/mediatek/dts"
IMAGE_DIR="target/linux/mediatek/image"
FILOGIC_MK="$IMAGE_DIR/filogic.mk"

mkdir -p "$OUTPUT_DIR" "$OUTPUT_DIR/atf" "$OUTPUT_DIR/uboot" "$OUTPUT_DIR/firmware"

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

echo "=== [CHECK] 888 三件套 ==="
ls -la "$CONFIG_DIR"

# 严格物理校验
[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] || { echo "❌ 缺失 DTS"; exit 1; }
[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ]        || { echo "❌ 缺失 MK"; exit 1; }
[ -f "$CONFIG_DIR/sl3000.config" ]           || { echo "❌ 缺失 Config"; exit 1; }

echo "=== 准备 ImmortalWrt 24.10 ==="
cd "$WORKSPACE"
rm -rf "$IMMORTALWRT_BUILD"
cp -r "$SOURCE_DIR" "$IMMORTALWRT_BUILD"

cd "$IMMORTALWRT_BUILD"

# 屏蔽不必要的 feeds
sed -i 's/^src-git telephony/#src-git telephony/g' feeds.conf.default || true

./scripts/feeds update -a
./scripts/feeds install -a
make package/symlinks

# =========================================================
# 【核心修改】注入 DTS 并进行“救砖手术”
# =========================================================
echo "=== 注入并改造救砖 DTS ==="
mkdir -p "$DTS_BASE" "$DTS_RAW"

# 1. 物理克隆并更名为系统预期的 spi-nor 名称 (解决 cc1 报错)
RESCUE_DTS="mt7981b-sl3000-spi-nor.dts"
cp -vf "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$DTS_BASE/$RESCUE_DTS"
cp -vf "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$DTS_RAW/$RESCUE_DTS"

# 2. 【物理级修复红灯】修改 bootargs 强制使用 RAMDISK
# 将 root=/dev/mmcblk... 或其他挂载目标强行改为 root=/dev/ram0
sed -i 's/bootargs = ".*"/bootargs = "console=ttyS0,115200n8 earlycon=uart8250,mmio32,0x11002000 root=\/dev\/ram0 rw swiotlb=1"/g' "$DTS_BASE/$RESCUE_DTS"
sed -i 's/model = ".*"/model = "Siluo SL3000 Rescue (1GB DDR4)"/g' "$DTS_BASE/$RESCUE_DTS"

# =========================================================

echo "=== 注入 image mk ==="
cp -vf "$CONFIG_DIR/mt7981_sl3000.mk" "$IMAGE_DIR/"

if ! grep -q "mt7981_sl3000.mk" "$FILOGIC_MK"; then
  echo 'include ./mt7981_sl3000.mk' >> "$FILOGIC_MK"
  echo "✅ 已写入 filogic.mk include"
fi

echo "=== 注入救砖 config ==="
cp -vf "$CONFIG_DIR/sl3000.config" .config
# 强制开启 INITRAMFS 救砖模式，不依赖 eMMC
echo "CONFIG_TARGET_ROOTFS_INITRAMFS=y" >> .config
echo "CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y" >> .config

# 禁用 mt76 减小体积，提升救砖成功率
echo "# CONFIG_PACKAGE_kmod-mt76 is not set" >> .config

make defconfig

pwd > "$WORKSPACE/build-dir.txt"

echo "=== diy-part1.sh 修复完成 ==="
