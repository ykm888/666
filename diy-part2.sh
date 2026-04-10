#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
# 获取 Part1 传递的构建目录路径
IMMORTALWRT_BUILD=$(cat "$WORKSPACE/build-dir.txt")

echo "=== [物理审计] 进入构建目录: $IMMORTALWRT_BUILD ==="
cd "$IMMORTALWRT_BUILD"

# =========================================================
# 1. 物理定位 888 配置目录
# =========================================================
CONFIG_DIR=$(find "$WORKSPACE" -maxdepth 3 -type d -name "888" -not -path "*build_dir*" | head -n 1)
if [ -z "$CONFIG_DIR" ]; then
    echo "❌ 致命错误：物理扫描未发现 888 文件夹！"
    exit 1
fi

SRC_DTS="$CONFIG_DIR/mt7981b-sl3000-emmc.dts"
SRC_MK="$CONFIG_DIR/mt7981_sl3000.mk"
SRC_CONF="$CONFIG_DIR/sl3000.config"

# =========================================================
# 2. DTS 救砖基因手术 (修复红灯)
# =========================================================
TARGET_DTS_NAME="mt7981b-sl3000-spi-nor.dts"
DTS_OVERLAY_PATH="target/linux/mediatek/files/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_OVERLAY_PATH"

if [ -f "$SRC_DTS" ]; then
    # 物理克隆并注入 root=/dev/ram0 指令
    cp -vf "$SRC_DTS" "$DTS_OVERLAY_PATH/$TARGET_DTS_NAME"
    sed -i 's/bootargs = ".*"/bootargs = "console=ttyS0,115200n8 earlycon=uart8250,mmio32,0x11002000 root=\/dev\/ram0 rw swiotlb=1"/g' "$DTS_OVERLAY_PATH/$TARGET_DTS_NAME"
    echo "✅ DTS 救砖基因注入完毕。"
fi

# =========================================================
# 3. Makefile 物理修复注入 (解决 missing separator)
# =========================================================
if [ -f "$SRC_MK" ]; then
    echo "🔎 正在执行 Makefile 物理格式化审计..."
    
    # 创建临时处理文件
    TEMP_MK=$(mktemp)
    
    # A. 物理清洗：移除 Windows 换行符 (CRLF -> LF)
    sed 's/\r//g' "$SRC_MK" > "$TEMP_MK"
    
    # B. 格式转换：将 2 个或 4 个前导空格强制转换为 Tab (Makefile 核心要求)
    # 这一步修复 "missing separator" 错误
    sed -i 's/^[ ]\+/	/g' "$TEMP_MK"
    
    # C. 注入到系统 Makefile
    echo "" >> target/linux/mediatek/image/filogic.mk
    cat "$TEMP_MK" >> target/linux/mediatek/image/filogic.mk
    rm -f "$TEMP_MK"
    echo "✅ Makefile 物理注入完成 (已应用 Tab 转换)。"
fi

# =========================================================
# 4. Config 注入与 Initramfs 锁定
# =========================================================
if [ -f "$SRC_CONF" ]; then
    cat "$SRC_CONF" >> .config
    {
        echo "CONFIG_TARGET_ROOTFS_INITRAMFS=y"
        echo "CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y"
        echo "# CONFIG_PACKAGE_kmod-mt76 is not set"
    } >> .config
    make defconfig
fi

# =========================================================
# 5. 物理构建
# =========================================================
echo "=== 开始编译 (j$(nproc)) ==="
make -j"$(nproc)" V=s || {
    echo "❌ 编译中断，请检查上方日志。"
    exit 1
}

# 产物搜集
OUTPUT_DIR="$WORKSPACE/output"
FIRMWARE_DIR="bin/targets/mediatek/filogic"
mkdir -p "$OUTPUT_DIR/firmware"
cp -vf "$FIRMWARE_DIR"/*initramfs-recovery.itb "$OUTPUT_DIR/firmware/" || true
