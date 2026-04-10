#!/bin/bash
set -euo pipefail

# =========================================================
# 1. 物理路径自探测逻辑
# =========================================================
WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
IMMORTALWRT_BUILD="$WORKSPACE/immortalwrt-build"

echo "🔎 正在全量探测 888 配置目录..."
# 动态寻找 888 文件夹，忽略层级差异
CONFIG_DIR=$(find "$WORKSPACE" -type d -name "888" | head -n 1)

if [ -z "$CONFIG_DIR" ] || [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ 致命错误：在工作区未找到 888 文件夹！"
    echo "当前目录树如下："
    ls -R "$WORKSPACE"
    exit 1
fi

echo "✅ 定位成功: $CONFIG_DIR"

# 定义源文件物理路径
SRC_DTS="$CONFIG_DIR/mt7981b-sl3000-emmc.dts"
SRC_MK="$CONFIG_DIR/mt7981_sl3000.mk"
SRC_CONF="$CONFIG_DIR/sl3000.config"

# =========================================================
# 2. 准备 ImmortalWrt 环境
# =========================================================
echo "=== 准备构建环境 ==="
cd "$WORKSPACE"
rm -rf "$IMMORTALWRT_BUILD"
cp -r "$SOURCE_DIR" "$IMMORTALWRT_BUILD"

cd "$IMMORTALWRT_BUILD"

# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a
make package/symlinks

# =========================================================
# 3. 救砖基因注入 (DTS 手术)
# =========================================================
echo "=== 注入并改造救砖 DTS ==="
# 定义内核物理路径 (兼容 files 覆盖机制)
DTS_FILES_PATH="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS_RAW_PATH="target/linux/mediatek/dts"
RESCUE_DTS_NAME="mt7981b-sl3000-spi-nor.dts"

mkdir -p "$DTS_FILES_PATH" "$DTS_RAW_PATH"

if [ -f "$SRC_DTS" ]; then
    # 物理克隆并更名
    cp -vf "$SRC_DTS" "$DTS_FILES_PATH/$RESCUE_DTS_NAME"
    cp -vf "$SRC_DTS" "$DTS_RAW_PATH/$RESCUE_DTS_NAME"
    
    # 【修复红灯】强制注入 root=/dev/ram0 (RAMDISK 模式)
    # 这将使 1GB 内存承载系统，跳过 eMMC 挂载导致的 Panic
    sed -i 's/bootargs = ".*"/bootargs = "console=ttyS0,115200n8 earlycon=uart8250,mmio32,0x11002000 root=\/dev\/ram0 rw swiotlb=1"/g' "$DTS_FILES_PATH/$RESCUE_DTS_NAME"
    sed -i "s/model = \".*\"/model = \"Siluo SL3000 Rescue (1GB RAM)\"/g" "$DTS_FILES_PATH/$RESCUE_DTS_NAME"
    echo "✅ DTS 救砖补丁已注入。"
else
    echo "❌ 缺失 DTS 文件: $SRC_DTS"
    exit 1
fi

# =========================================================
# 4. 镜像生成逻辑与配置注入
# =========================================================
echo "=== 注入 Makefile 与 Config ==="
[ -f "$SRC_MK" ] && cp -vf "$SRC_MK" target/linux/mediatek/image/
if ! grep -q "mt7981_sl3000.mk" target/linux/mediatek/image/filogic.mk; then
    echo 'include ./mt7981_sl3000.mk' >> target/linux/mediatek/image/filogic.mk
fi

[ -f "$SRC_CONF" ] && cp -vf "$SRC_CONF" .config

# 强制追加救砖必备全局变量
{
    echo "CONFIG_TARGET_ROOTFS_INITRAMFS=y"
    echo "CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA=y"
    echo "# CONFIG_PACKAGE_kmod-mt76 is not set"
} >> .config

# 刷新 .config 依赖
make defconfig

# 保存路径供下一步骤使用
pwd > "$WORKSPACE/build-dir.txt"
echo "=== diy-part1.sh 修复完成 ==="
