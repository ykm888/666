#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
IMMORTALWRT_BUILD=$(cat "$WORKSPACE/build-dir.txt")
cd "$IMMORTALWRT_BUILD"

# 1. 物理定位 888 目录
CONFIG_DIR=$(find "$WORKSPACE" -maxdepth 3 -type d -name "888" -not -path "*build_dir*" | head -n 1)
[ -z "$CONFIG_DIR" ] && { echo "❌ 找不到 888 目录"; exit 1; }

# 2. DTS 救砖基因手术 (修复红灯)
RESCUE_DTS="target/linux/mediatek/files/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-spi-nor.dts"
mkdir -p "$(dirname "$RESCUE_DTS")"
cp -vf "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$RESCUE_DTS"
sed -i 's/bootargs = ".*"/bootargs = "console=ttyS0,115200n8 earlycon=uart8250,mmio32,0x11002000 root=\/dev\/ram0 rw swiotlb=1"/g' "$RESCUE_DTS"

# =========================================================
# 3. 物理清场：彻底删除会导致报错的旧文件
# =========================================================
echo "🧹 正在物理清场旧的 Makefile 碎片..."
# 删除之前注入可能残留的坏文件，防止 include 报错
rm -f target/linux/mediatek/image/mt7981_sl3000.mk
# 清理主 Makefile 中可能存在的 include 引用（针对 part1 的残留）
sed -i '/mt7981_sl3000.mk/d' target/linux/mediatek/image/filogic.mk

# =========================================================
# 4. 物理重构 Makefile (使用 printf 像素级注入)
# =========================================================
echo "🔎 正在执行 Makefile 物理注入 (像素级 Tab 锁定)..."
TARGET_MK="target/linux/mediatek/image/filogic.mk"

# 确保文件末尾有空行
printf "\n" >> "$TARGET_MK"

# 使用 printf 注入。核心：\t 是物理 Tab 键，解决 missing separator 的唯一解
printf "define Device/sl_3000-emmc\n" >> "$TARGET_MK"
printf "\tDEVICE_VENDOR := SL\n" >> "$TARGET_MK"
printf "\tDEVICE_MODEL := 3000 eMMC\n" >> "$TARGET_MK"
printf "\tDEVICE_DTS := mt7981b-sl-3000-emmc\n" >> "$TARGET_MK"
printf "\tDEVICE_DTS_DIR := \$(DTS_DIR)/mediatek\n" >> "$TARGET_MK"
printf "\tSUPPORTED_DEVICES := sl,3000-emmc\n" >> "$TARGET_MK"
printf "\tDEVICE_DRAM_SIZE := 1024M\n" >> "$TARGET_MK"
printf "\tDEVICE_PACKAGES := \$(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils\n" >> "$TARGET_MK"
printf "\tKERNEL_LOADADDR := 0x44000000\n" >> "$TARGET_MK"
printf "\tKERNEL := kernel-bin | lzma | fit lzma \$\$(KDIR)/image-\$\$(firstword \$\$(DEVICE_DTS)).dtb\n" >> "$TARGET_MK"
printf "\tKERNEL_INITRAMFS := kernel-bin | lzma | fit lzma \$\$(KDIR)/image-\$\$(firstword \$\$(DEVICE_DTS)).dtb with-initrd | pad-to 64k\n" >> "$TARGET_MK"
printf "\tKERNEL_INITRAMFS_SUFFIX := -recovery.itb\n" >> "$TARGET_MK"
printf "\tIMAGES := sysupgrade.bin factory.img.gz\n" >> "$TARGET_MK"
printf "\tIMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\n" >> "$TARGET_MK"
printf "\tARTIFACTS := emmc-gpt.bin emmc-preloader.bin emmc-bl31-uboot.fip\n" >> "$TARGET_MK"
printf "\tARTIFACT/emmc-gpt.bin := mt798x-gpt emmc\n" >> "$TARGET_MK"
printf "\tARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3\n" >> "$TARGET_MK"
printf "\tARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3\n" >> "$TARGET_MK"
printf "\tIMAGE/factory.img.gz := mt798x-gpt emmc | pad-to 17k | mt7981-bl2 emmc-ddr3 | pad-to 6656k | mt7981-bl31-uboot emmc-ddr3 | pad-to 64M | append-image squashfs-sysupgrade.itb | gzip\n" >> "$TARGET_MK"
printf "endef\n" >> "$TARGET_MK"
printf "TARGET_DEVICES += sl_3000-emmc\n" >> "$TARGET_MK"

echo "✅ Makefile 物理注入完成。"

# 5. .config 合并
[ -f "$CONFIG_DIR/sl3000.config" ] && cat "$CONFIG_DIR/sl3000.config" >> .config
printf "CONFIG_TARGET_ROOTFS_INITRAMFS=y\n" >> .config
printf "CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y\n" >> .config

make defconfig

# 6. 构建
echo "=== 开始物理构建 ==="
make -j"$(nproc)" V=s
