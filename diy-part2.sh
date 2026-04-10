#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
# 获取 Part1 传递的构建目录路径
IMMORTALWRT_BUILD=$(cat "$WORKSPACE/build-dir.txt")

echo "=== [物理审计] 进入构建目录: $IMMORTALWRT_BUILD ==="
cd "$IMMORTALWRT_BUILD"

# =========================================================
# 1. 物理定位：自动搜索 888 配置目录 (解决层级偏移)
# =========================================================
echo "🔎 正在全量扫描物理磁盘锁定 888 文件夹..."
# 在整个工作区内探测 888 目录，排除 build_dir 干扰
CONFIG_DIR=$(find "$WORKSPACE" -maxdepth 3 -type d -name "888" -not -path "*build_dir*" | head -n 1)

if [ -z "$CONFIG_DIR" ] || [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ 致命错误：物理扫描未发现 888 文件夹！"
    echo "🔍 打印当前目录结构 (Depth 2) 以供调试:"
    ls -R "$WORKSPACE" | grep ":$" | head -n 20
    exit 1
fi

echo "✅ 物理锁定成功: $CONFIG_DIR"

# 定义三件套源文件
SRC_DTS="$CONFIG_DIR/mt7981b-sl3000-emmc.dts"
SRC_MK="$CONFIG_DIR/mt7981_sl3000.mk"
SRC_CONF="$CONFIG_DIR/sl3000.config"

# =========================================================
# 2. 救砖基因注入 (解决编译报错与红灯)
# =========================================================
echo "🔧 注入私有配置与救砖基因手术..."

# 定义系统预期的目标文件名 (解决 cc1 找不到 spi-nor.dts 的报错)
TARGET_DTS_NAME="mt7981b-sl3000-spi-nor.dts"
# 物理覆盖路径
DTS_TARGET_PATH="target/linux/mediatek/dts/$TARGET_DTS_NAME"
DTS_OVERLAY_PATH="target/linux/mediatek/files/arch/arm64/boot/dts/mediatek"

mkdir -p "$(dirname "$DTS_TARGET_PATH")"
mkdir -p "$DTS_OVERLAY_PATH"

if [ -f "$SRC_DTS" ]; then
    # 物理注入 DTS
    cp -vf "$SRC_DTS" "$DTS_TARGET_PATH"
    
    # 【救砖手术】强制修改 Bootargs。关键：root=/dev/ram0
    # 作用：让 1GB 内存直接承载 rootfs，跳过物理 eMMC 检测，修复红灯 Panic
    sed -i 's/bootargs = ".*"/bootargs = "console=ttyS0,115200n8 earlycon=uart8250,mmio32,0x11002000 root=\/dev\/ram0 rw swiotlb=1"/g' "$DTS_TARGET_PATH"
    
    # 同步至覆盖层 (OpenWrt 编译时优先级最高)
    cp -vf "$DTS_TARGET_PATH" "$DTS_OVERLAY_PATH/"
    echo "✅ DTS 物理补丁已植入。"
else
    echo "❌ 缺失 DTS 源文件: $SRC_DTS"
    exit 1
fi

# 3. 追加 Makefile (MK) 逻辑
if [ -f "$SRC_MK" ]; then
    cat "$SRC_MK" >> target/linux/mediatek/image/filogic.mk
    echo "✅ Makefile 配置已追加。"
fi

# 4. 强制锁定 .config 为救砖模式
if [ -f "$SRC_CONF" ]; then
    cat "$SRC_CONF" >> .config
    {
        echo "CONFIG_TARGET_ROOTFS_INITRAMFS=y"
        echo "CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y"
        echo "# CONFIG_PACKAGE_kmod-mt76 is not set"
    } >> .config
    # 应用配置
    make defconfig
fi

# =========================================================
# 3. 物理构建阶段
# =========================================================
echo "=== 开始物理构建 (Generation: SL3000 Rescue Pack) ==="
# 使用 V=s 捕捉实时日志，j$(nproc) 加速
make -j"$(nproc)" V=s || {
    echo "❌ 编译中断，截取最后 50 行日志："
    tail -n 50 "$IMMORTALWRT_BUILD/logs/build.log" || true
    exit 1
}

# =========================================================
# 4. 产物搜集
# =========================================================
OUTPUT_DIR="$WORKSPACE/output"
FIRMWARE_DIR="bin/targets/mediatek/filogic"
mkdir -p "$OUTPUT_DIR/firmware"

echo "🚚 搜集固件产物至 output 目录..."
cp -vf "$FIRMWARE_DIR"/*initramfs-recovery.itb "$OUTPUT_DIR/firmware/" || true
cp -vf "$FIRMWARE_DIR"/*.bin "$OUTPUT_DIR/firmware/" || true

echo "✅ 物理构建流程已完整执行！"
