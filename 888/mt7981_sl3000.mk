# 888/mt7981_sl3000.mk
# SPI-NOR 救砖专用机型定义（ImmortalWrt 24.10 / 内核 6.6）
# 只用于生成 kernel / initramfs，不定义任何升级固件镜像

define Device/mt7981_sl3000_spi_rescue
  DEVICE_VENDOR := Siluo
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := 1GB-DDR4-32MB-SPI-Rescue
  DEVICE_DTS := mt7981b-sl3000-spi-nor
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-spi-nor

  # 1GB DRAM，loadaddr 对齐 MT7981 平台
  DEVICE_DRAM_SIZE := 1024M
  KERNEL_LOADADDR := 0x44000000

  # 救砖专用：不在这里声明任何镜像规则
  # 不定义 IMAGE_SIZE，不定义 IMAGES，不定义 IMAGE/*
  # 具体“只构建 kernel+initramfs、不构建 sysupgrade/factory”
  # 由 .config 中的：
  #   CONFIG_TARGET_IMAGES=n
  #   CONFIG_TARGET_ROOTFS_INITRAMFS=y
  # 来控制

  # 可选：如果你想让 initramfs 自带基础救砖工具，可以在这里挂包
  # DEVICE_PACKAGES := mtd-utils uboot-envtools mmc-utils kmod-mtd-rw
endef

TARGET_DEVICES += mt7981_sl3000_spi_rescue
