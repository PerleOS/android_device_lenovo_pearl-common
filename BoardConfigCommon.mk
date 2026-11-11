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

