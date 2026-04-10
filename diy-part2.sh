#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
IMMORTALWRT_BUILD=$(cat "$WORKSPACE/build-dir.txt")
cd "$IMMORTALWRT_BUILD"

# 1. 物理定位 888 目录
CONFIG_DIR=$(find "$WORKSPACE" -maxdepth 3 -type d -name "888" -not -path "*build_dir*" | head -n 1)
[ -z "$CONFIG_DIR" ] && { echo "❌ 找不到 888 目录"; exit 1; }

# 2. DTS 救砖基因手术 (修复红灯)
# 物理路径对齐：注入到内核覆盖层，确保编译器绝对能抓到
RESCUE_DTS="target/linux/mediatek/files/arch/arm64/boot/dts/mediatek/mt7981b-sl3000-spi-nor.dts"
mkdir -p "$(dirname "$RESCUE_DTS")"
cp -vf "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$RESCUE_DTS"
# 强制注入 root=/dev/ram0 指令，将 1GB 内存转为启动盘
sed -i 's/bootargs = ".*"/bootargs = "console=ttyS0,115200n8 earlycon=uart8250,mmio32,0x11002000 root=\/dev\/ram0 rw swiotlb=1"/g' "$RESCUE_DTS"

# =========================================================
# 3. 物理重构 Makefile (禁用 EOF，改用 printf 像素级注入)
# =========================================================
echo "🔎 正在执行 Makefile 物理重写 (No-EOF Mode)..."
TARGET_MK="target/linux/mediatek/image/filogic.mk"

# 确保文件末尾有空行
printf "\n" >> "$TARGET_MK"

# 使用 printf 逐行注入，\t 代表物理 Tab，这是解决 missing separator 的终极方案
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

echo "✅ Makefile 物理重写成功 (强制 Tab 校验通过)。"

# 4. Config 注入与 Initramfs 锁定
[ -f "$CONFIG_DIR/sl3000.config" ] && cat "$CONFIG_DIR/sl3000.config" >> .config
printf "CONFIG_TARGET_ROOTFS_INITRAMFS=y\n" >> .config
printf "CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y\n" >> .config

make defconfig

# 5. 执行最终构建
echo "=== 开始最终物理构建 ==="
make -j"$(nproc)" V=s
