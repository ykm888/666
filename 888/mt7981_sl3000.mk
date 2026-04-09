# 888/mt7981_sl3000.mk
# SPI-NOR 救砖专用机型定义（仅生成 initramfs 镜像）

define Device/mt7981_sl3000_spi_rescue
  DEVICE_VENDOR := Siluo
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := 1GB-DDR4-32MB-SPI-Rescue
  DEVICE_DTS := mt7981b-sl3000-spi-nor
  SUPPORTED_DEVICES := sl,3000-spi-nor

  KERNEL_LOADADDR := 0x44000000

  # 只生成 initramfs 镜像（内核 + 内置根文件系统）
  IMAGES := initramfs.bin
  IMAGE/initramfs.bin := append-initramfs

  # 救砖必需工具包
  DEVICE_PACKAGES := \
    uboot-envtools mtd-utils kmod-mtd-rw \
    block-mount kmod-mmc kmod-mmc-mtk \
    kmod-fs-ext4 kmod-fs-f2fs f2fs-tools e2fsprogs \
    ip-full dropbear
endef

TARGET_DEVICES += mt7981_sl3000_spi_rescue
