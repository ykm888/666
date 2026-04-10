#!/bin/bash
set -euo pipefail

# =========================================================
# 环境变量与路径定义
# =========================================================
WORKSPACE="$GITHUB_WORKSPACE"
OUTPUT_DIR="$WORKSPACE/output"
# 从文件中读取之前的构建目录名
IMMORTALWRT_BUILD="$(cat "$WORKSPACE/build-dir.txt")"

# 仓库三件套在你的仓库中的相对路径
SRC_DTS="888/mt7981b-sl3000-emmc.dts"
SRC_MK="888/mt7981_sl3000.mk"
SRC_CONF="888/sl3000.config"

ATF_DIR="$WORKSPACE/atf-src"
UBOOT_DIR="$WORKSPACE/uboot-src"

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

echo "=== 进入 ImmortalWrt 构建目录: $IMMORTALWRT_BUILD ==="
cd "$IMMORTALWRT_BUILD"

# =========================================================
# 核心修复层：物理植入三件套
# =========================================================
echo "🔎 开始像素级注入私有配置..."

# 1. 修复 DTS 缺失与红灯问题
if [ -f "$WORKSPACE/$SRC_DTS" ]; then
    echo "✅ 发现源 DTS，正在进行救砖基因改造..."
    # 物理路径：存放到系统预期的路径名
    RESCUE_DTS_NAME="mt7981b-sl3000-spi-nor.dts"
    TARGET_DTS_PATH="target/linux/mediatek/dts/$RESCUE_DTS_NAME"
    
    cp -v "$WORKSPACE/$SRC_DTS" "$TARGET_DTS_PATH"
    
    # 【救砖核心】强制注入 root=/dev/ram0，跳过 eMMC 挂载，彻底修复红灯常亮
    sed -i 's/bootargs = ".*"/bootargs = "console=ttyS0,115200n8 earlycon=uart8250,mmio32,0x11002000 root=\/dev\/ram0 rw swiotlb=1"/g' "$TARGET_DTS_PATH"
    
    # 修改 Model 名以便在串口中识别
    sed -i "s/model = \".*\"/model = \"Siluo SL3000 Rescue (1GB RAM)\"/g" "$TARGET_DTS_PATH"

    # 同步到内核覆盖层（Files 机制），确保编译器 cc1 绝对能找到它
    OVERLAY_DIR="target/linux/mediatek/files/arch/arm64/boot/dts/mediatek"
    mkdir -p "$OVERLAY_DIR"
    cp -v "$TARGET_DTS_PATH" "$OVERLAY_DIR/"
else
    echo "❌ 致命错误：在 $WORKSPACE/$SRC_DTS 未找到源文件！"
    exit 1
fi

# 2. 注入 Makefile (MK) 配置
if [ -f "$WORKSPACE/$SRC_MK" ]; then
    echo "✅ 注入自定义镜像生成逻辑 (MK)..."
    cat "$WORKSPACE/$SRC_MK" >> target/linux/mediatek/image/filogic.mk
fi

# 3. 注入并强制修正 .config
if [ -f "$WORKSPACE/$SRC_CONF" ]; then
    echo "✅ 注入并合并 .config..."
    cat "$WORKSPACE/$SRC_CONF" >> .config
    # 强制开启 Initramfs 模式
    echo "CONFIG_TARGET_ROOTFS_INITRAMFS=y" >> .config
    echo "CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y" >> .config
    # 刷新配置并同步依赖
    make defconfig
fi

# =========================================================
# 构建阶段
# =========================================================
echo "=== 删除 mt76（减少编译体积，救砖不需要无线） ==="
rm -rf package/kernel/mt76 || true

echo "=== 开始执行物理构建 (Rescue ITB) ==="
# 使用 V=s 捕捉详细错误，如果失败则打印最后 50 行日志
make -j"$(nproc)" V=s || {
    echo "❌ 编译失败，查看错误上下文："
    tail -n 50 "$IMMORTALWRT_BUILD/logs/build.log" || true
    exit 1
}

# 搜集编译出的固件
FIRMWARE_DIR="bin/targets/mediatek/filogic"
mkdir -p "$OUTPUT_DIR/firmware"
cp -vf "$FIRMWARE_DIR"/*initramfs-recovery.itb "$OUTPUT_DIR/firmware/" || true
cp -vf "$FIRMWARE_DIR"/*.bin "$OUTPUT_DIR/firmware/" || true

# =========================================================
# ATF / U-Boot 源码拉取 (保持原逻辑)
# =========================================================
echo "=== 拉取 ATF / U-Boot 源并备份 ==="
mkdir -p "$ATF_DIR" "$UBOOT_DIR" "$OUTPUT_DIR/atf" "$OUTPUT_DIR/uboot"

git clone --depth 1 -b mtksoc-20260123 https://github.com/mtk-openwrt/arm-trusted-firmware.git "$ATF_DIR"
git clone --depth 1 -b mtksoc-20250711 https://github.com/mtk-openwrt/u-boot.git "$UBOOT_DIR"

tar -czf "$OUTPUT_DIR/atf/atf-src.tar.gz" -C "$ATF_DIR" .
tar -czf "$OUTPUT_DIR/uboot/uboot-src.tar.gz" -C "$UBOOT_DIR" .

echo "=== 脚本执行完毕，救砖包已生成在 $OUTPUT_DIR/firmware ==="
