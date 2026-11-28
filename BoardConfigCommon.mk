#
# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Board configuration shared by the Lenovo Tab P11 Pro family (pearl: TB-J706F, TB-J706L).
# Values marked "stock" come from the TB-J706F_S620150_211226_ROW firmware.

COMMON_PATH := device/lenovo/pearl-common

# The vendor partition is built: the stock S620150 blobs (vendor/lenovo/pearl-common) with
# the HALs below the framework matrix and the AOSP/CAF components rebuilt from source.

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
# boot and vendor go together: the vendor modules must come with the kernel they were built
# with. recovery is in the list because the stock package writes no recovery_b. dtbo and vbmeta
# are not updated. Not usable for OTA yet: not tested, and the other slot needs the stock vbmeta
# with verification disabled.
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := \
    boot \
    product \
    recovery \
    system \
    system_ext \
    vendor

# Boot image (stock boot.img header v2, page size 4096, kernel/ramdisk/tags/dtb offsets).
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

# Recovery: the bootloader applies the overlays carried in the recovery image (recovery_dtbo),
# not the dtbo partition; without them it returns to its menu. The stock recovery carries
# the stock dtbo, which is not built from source (the partition itself stays stock).
BOARD_INCLUDE_RECOVERY_DTBO := true
BOARD_PREBUILT_DTBOIMAGE := vendor/lenovo/pearl-common/prebuilt/dtbo.img

# Stock command line, except its trailing "buildvariant=user".
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

# Keep the stock boot image OS version and patch level. Keymaster binds keys to the
# patch level and only moves it forward, so a later date in boot.img would make a return
# to the stock boot image lose them. BOARD_MKBOOTIMG_ARGS comes after the build's own
# --os_version/--os_patch_level, and mkbootimg keeps the last value.
# The release tools rebuild boot.img and recovery.img from the target files with the build's
# own values last (mkbootimg_version_args in misc_info.txt), so those are overridden as well.
override INTERNAL_MKBOOTIMG_VERSION_ARGS := --os_version 11.0.0 --os_patch_level 2021-12
BOARD_MKBOOTIMG_ARGS += $(INTERNAL_MKBOOTIMG_VERSION_ARGS)

# Kernel source (kernel/lenovo/sm6150), built with the default LineageOS kernel toolchain
# (prebuilt AOSP clang with LLVM=1 LLVM_IAS=1).
# Only the base SoC device trees are built; the bootloader picks sdmmagpiep on this SoC
# and applies the stock dtbo on top.
TARGET_KERNEL_DTB := qcom/sdmmagpie.dtb qcom/sdmmagpiep.dtb

# The in-tree modules install to /vendor/lib/modules, where init.target.rc loads them. Their
# file names differ from stock (wlan.ko, not qca_cld3_wlan.ko; X_dlkm.ko, not audio_X.ko), and
# init.target.rc uses the new ones.

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
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4

# Vendor AIDs and file capabilities (stock vendor/etc/passwd, group, fs_config_files)
TARGET_FS_CONFIG_GEN := $(COMMON_PATH)/config.fs

# Super: 12 GiB, groups qti_dynamic_partitions_a/_b of 6,438,256,640 bytes each (stock LP
# metadata). The four images built here share the whole group. Checked by the
# check-all-partition-sizes goal.
BOARD_SUPER_PARTITION_SIZE := 12884901888
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 6438256640
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := product system system_ext vendor
# Images are flashed one by one from fastbootd, which resizes them inside the existing group;
# no super image is produced.
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
# Never above the stock index (1638662400): vbmeta_system stays stock and must remain accepted.
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := 0
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

# Recovery fstab (stock vendor/etc/fstab.qcom without the GSI avb_keys)
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# The stock root has no /dsp, /firmware or /bt_firmware symlinks: the stock fstab mounts those
# partitions under /vendor. /lenovocust is deliberately absent, and init.target.rc does not mount
# the lenovocust partition (stock mounts it read-write there).

# Audio: the stock Lenovo audio module and its CAF feature libraries are shipped as blobs, so
# the CAF audio HAL makefiles must not build their own copies. With no audio directory in the
# device tree, nothing is built from the device-specific audio path.
USE_DEVICE_SPECIFIC_AUDIO := true
# The stock audio module calls the QTI tinycompress extensions (compress_get_metadata,
# compress_set_next_track_param).
AUDIO_FEATURE_ENABLED_EXTENDED_COMPRESS_FORMAT := true

# Display: board flags of the CAF sm8150 display tree (config/display-board.mk), which the
# product does not include. TARGET_USES_HWC2 builds hwcomposer.qcom (hwcomposer.sm6150 on stock).
TARGET_USES_GRALLOC1 := true
TARGET_USES_GRALLOC4 := true
TARGET_USES_DRM_PP := true
TARGET_USES_HWC2 := true
TARGET_USES_QCOM_DISPLAY_BSP := true
TARGET_USES_DISPLAY_RENDER_INTENTS := true
TARGET_USES_QTI_MAPPER_2_0 := true
TARGET_USES_QTI_MAPPER_EXTENSIONS_1_1 := true
TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := true
MAX_VIRTUAL_DISPLAY_DIMENSION := 4096
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3

# Media: the CAF OMX video codecs allocate their buffers through ION (kernel 4.14)
TARGET_USES_ION := true

# Properties
TARGET_VENDOR_PROP += $(COMMON_PATH)/vendor.prop
TARGET_ODM_PROP += $(COMMON_PATH)/odm.prop
TARGET_PRODUCT_PROP += $(COMMON_PATH)/product.prop

# Keep the stock vendor security patch level, for the same reason as the boot image's: the
# stock Keymaster binds keys to it and only moves it forward.
VENDOR_SECURITY_PATCH := 2021-12-05

# VINTF: the device manifest lists the HALs served by blobs; source-built HALs add their own
# fragments. The framework matrix adds HALs of the stock vendor that no LineageOS or QTI
# framework matrix lists.
DEVICE_MANIFEST_FILE := $(COMMON_PATH)/vintf/manifest.xml
ODM_MANIFEST_FILES := $(COMMON_PATH)/vintf/manifest-odm.xml
DEVICE_MATRIX_FILE := hardware/qcom-caf/common/compatibility_matrix.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := \
    $(COMMON_PATH)/framework_compatibility_matrix.xml \
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix.xml

# Wi-Fi (WCN3990, qca_cld3 driver loaded by init.target.rc). hostapd, wpa_supplicant, the
# Wi-Fi HAL service and the QTI Wi-Fi HAL library are built from source.
BOARD_WLAN_DEVICE := qcwcn
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
WIFI_DRIVER_DEFAULT := qca_cld3
WIFI_DRIVER_STATE_CTRL_PARAM := "/dev/wlan"
WIFI_DRIVER_STATE_OFF := "OFF"
WIFI_DRIVER_STATE_ON := "ON"
# One STA with one AP or one P2P interface: without it the HAL reports a single interface and
# the framework stops Wi-Fi to start the hotspot
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WPA_SUPPLICANT_VERSION := VER_0_8_X

# SELinux
TARGET_SEPOLICY_DIR := msmsteppe
include device/qcom/sepolicy_vndr/SEPolicy.mk
BOARD_VENDOR_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/vendor
# Legacy ION ioctls for the stock QSEECom, keymaster and media blobs (see pearl.mk)
include device/lineage/sepolicy/libion/sepolicy.mk

# Boot debugging (PERLEOS_BOOT_DEBUG=true in the environment, userdebug only): SELinux
# permissive, and the boot log of debug/init.perleos-bootlog.rc
ifeq ($(PERLEOS_BOOT_DEBUG)-$(TARGET_BUILD_VARIANT),true-userdebug)
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
endif
