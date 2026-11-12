#
# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Board configuration shared by the Lenovo Tab P11 Pro family (pearl: TB-J706F, TB-J706L).
# Values marked "stock" come from the TB-J706F_S620150_211226_ROW firmware.

COMMON_PATH := device/lenovo/pearl-common

# Phase 1 keeps the stock vendor partition (Android 11, VNDK 30) and builds only system,
# system_ext and product. BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE stays unset, so no vendor image
# is defined and nothing vendor-side (vendor properties, VINTF manifest, sepolicy) ships.
PEARL_BUILD_VENDOR ?= false
ifeq ($(PEARL_BUILD_VENDOR),true)
$(error PEARL_BUILD_VENDOR: building the vendor partition needs the blob list, VINTF manifest and vendor properties first)
endif

# Without a vendor image, device/lineage/sepolicy/qcom/sepolicy.mk defaults this to true and
# moves its "dynamic" and "system" rules into system_ext. They use eight QTI vendor-side types
# (adsprpcd_file, bt_firmware_file, firmware_file, hal_graphics_composer_default,
# vendor_display_prop, vendor_qdisplay_service, hal_lineage_livedisplay_sysfs,
# vendor_sysfs_graphics) that system_ext cannot see, so the build fails; they also target
# LineageOS HALs the stock vendor does not have. Keep them on the (unbuilt) vendor side.
TARGET_USES_PREBUILT_VENDOR_SEPOLICY := false

# Platform
BOARD_VENDOR := lenovo
TARGET_BOARD_PLATFORM := sm6150
TARGET_BOOTLOADER_BOARD_NAME := sm6150
TARGET_NO_BOOTLOADER := true
BOARD_USES_QCOM_HARDWARE := true

# Architecture (stock: ro.zygote=zygote64_32; Kryo 470 = Cortex-A76 + Cortex-A55)
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# A/B on dynamic partitions; slot B partitions are empty on stock, so no virtual A/B.
# Not usable for OTA while vendor is missing from this list: update_engine recreates the
# target-slot group from the payload only, and that slot would have no vendor.
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := \
    system \
    system_ext \
    product

# Boot image (stock boot.img header v2, page size 4096, kernel/ramdisk/tags/dtb offsets).
# Only built for comparison with stock until phase 1b.
BOARD_BOOT_HEADER_VERSION := 2
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_DTB_OFFSET := 0x01f00000
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)

# Stock command line, except its trailing "buildvariant=user": whether to keep it for a
# userdebug boot image is decided in phase 1b.
BOARD_KERNEL_CMDLINE := \
    console=ttyMSM0,115200n8 \
    androidboot.hardware=qcom \
    androidboot.console=ttyMSM0 \
    androidboot.memcg=1 \
    lpm_levels.sleep_disabled=1 \
    video=vfb:640x400,bpp=32,memsize=3072000 \
    msm_rtb.filter=0x237 \
    service_locator.enable=1 \
    swiotlb=1 \
    androidboot.usbcontroller=a600000.dwc3 \
    earlycon=msm_geni_serial,0x880000 \
    loop.max_part=7

BOARD_KERNEL_IMAGE_NAME := Image.gz
BOARD_INCLUDE_DTB_IN_BOOTIMG := true

# Partitions (stock rawprogram sizes)
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 100663296

BOARD_USES_METADATA_PARTITION := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product
# Also creates the /system/vendor symlink that stock rc files rely on (/system/vendor/bin/...).
TARGET_COPY_OUT_VENDOR := vendor

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4

# Super: 12 GiB, groups qti_dynamic_partitions_a/_b of 6,438,256,640 bytes each (stock LP
# metadata). The stock vendor_a keeps 691,507,200 bytes of the group, so the images built here
# share the remaining 5,746,749,440 bytes. Checked by the check-all-partition-sizes goal.
BOARD_SUPER_PARTITION_SIZE := 12884901888
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 5746749440
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product
# Never produce a super image (see also PRODUCT_BUILD_SUPER_EMPTY_IMAGE in pearl.mk): a super
# layout without vendor would remove vendor_a from the device's LP metadata.
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := false

-include vendor/lineage/config/BoardConfigReservedSize.mk

# AVB. system, system_ext and product are verified through vbmeta_system (stock fstab:
# avb=vbmeta_system). Stock vbmeta (SHA256_RSA4096) chains vbmeta_system with a Lenovo key at
# rollback index location 2 (avbtool info_image of the stock vbmeta.img). With the device's
# vbmeta_a flashed with verification disabled, vbmeta_system is not read at all.
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

# Recovery fstab (stock vendor/etc/fstab.qcom without the GSI avb_keys)
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# The stock root has no /dsp, /firmware or /bt_firmware symlinks: the stock fstab mounts those
# partitions under /vendor. /lenovocust is deliberately absent: its label exists only in the
# stock system_ext policy, and the stock vendor's mount of the lenovocust partition there may
# fail without harm.

# VINTF: HALs of the stock vendor that no LineageOS or QTI framework matrix lists.
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := \
    $(COMMON_PATH)/framework_compatibility_matrix.xml \
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix.xml \
    vendor/lineage/config/device_framework_matrix.xml

# SELinux
TARGET_SEPOLICY_DIR := msmsteppe
include device/qcom/sepolicy_vndr/SEPolicy.mk
# Labels the stock vendor policy lacks; vendor policy is not rebuilt in phase 1.
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/private
