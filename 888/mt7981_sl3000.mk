Include ./common/common.mk

define Device/mt7981_sl3000_spi_rescue
  DEVICE_VENDOR := Siluo
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := 1GB-DDR4-32MB-SPI-Rescue
  
  # 关键点1：DTS 必须匹配 SPI-NOR 分区定义
  # 如果没有专用 nor dts，编译时会沿用 emmc 定义导致挂载失败
  DEVICE_DTS := mt7981b-sl3000-spi-nor
  SUPPORTED_DEVICES := siluo,sl3000-spi-nor,sl3000-emmc

  SOC := mt7981
  UBOOTENV_IN_FLASH := 1
  KERNEL_IN_UBI := 0

  # 关键点2：内存加载地址对齐
  # 1GB RAM 建议使用更高位地址，防止被内核解压覆盖
  KERNEL_LOADADDR := 0x46000000

  # 关键点3：构建救砖专属镜像 (initramfs)
  # 救砖包必须将 rootfs 塞进内核，这样即使 eMMC 坏了也能通过串口/SSH 登录
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  IMAGES := rescue.itb
  IMAGE/rescue.itb := append-kernel | pad-to 64k | append-initramfs | check-size 28672k

  # 救砖全家桶必备工具包
  DEVICE_PACKAGES := \
    uboot-envtools mtd-utils kmod-mtd-rw \
    kmod-usb3 kmod-usb-dwc3-mtk \
    kmod-fs-ext4 kmod-fs-f2fs f2fs-tools \
    kmod-mmc kmod-mmc-mtk \
    lsblk fdisk block-mount \
    ip-full dropbear luci-proto-ipv6
endef

TARGET_DEVICES += mt7981_sl3000_spi_rescue
