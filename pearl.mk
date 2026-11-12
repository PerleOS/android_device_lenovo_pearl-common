#
# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Product configuration shared by the Lenovo Tab P11 Pro family (pearl).

COMMON_PATH := device/lenovo/pearl-common

$(call inherit-product, hardware/qcom-caf/common/common.mk)

# Shipping level and partitions (stock: ro.product.first_api_level=29, dynamic partitions)
PRODUCT_SHIPPING_API_LEVEL := 29
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_CHARACTERISTICS := tablet
PRODUCT_AAPT_CONFIG := normal large xlarge
PRODUCT_AAPT_PREF_CONFIG := xhdpi

# No super_empty.img: its layout would describe the group without the stock vendor_a.
PRODUCT_BUILD_SUPER_EMPTY_IMAGE := false

# The stock vendor is built against VNDK 30: ship com.android.vndk.v30 in system_ext.
PRODUCT_EXTRA_VNDK_VERSIONS := 30

# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

PRODUCT_PACKAGES += \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

# Audio properties of the stock product partition, which this build replaces
PRODUCT_PRODUCT_PROPERTIES += \
    af.fast_track_multiplier=1 \
    audio.deep_buffer.media=true \
    audio.offload.min.duration.secs=30 \
    audio.offload.video=true \
    audio.sys.mute.latency.factor=2 \
    audio.sys.noisy.broadcast.delay=500 \
    audio.sys.offload.pstimeout.secs=3 \
    audio.sys.routing.latency=0 \
    ro.af.client_heap_size_kbyte=7168

# Speaker layout per display rotation for the stock audio HAL
PRODUCT_PACKAGES += \
    PearlAudioRotation

# First-stage fstab. The bootloader passes androidboot.fstab_suffix=default, and the stock
# ramdisk carries fstab.default; this is the same table without the GSI avb_keys.
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_RAMDISK)/fstab.default

# Input: keyboard pack layout and pen configuration from the stock system partition.
# The vendor partition is not built in phase 1, so they go to /system/usr.
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/keylayout/Vendor_17ef_Product_610b.kl:$(TARGET_COPY_OUT_SYSTEM)/usr/keylayout/Vendor_17ef_Product_610b.kl \
    $(COMMON_PATH)/idc/Vendor_beef_Product_dead.idc:$(TARGET_COPY_OUT_SYSTEM)/usr/idc/Vendor_beef_Product_dead.idc

# Static overlay, compiled into framework-res on system (RRO enforcement is off for this
# product; an enforced RRO from DEVICE_PACKAGE_OVERLAYS would land in the unbuilt vendor).
DEVICE_PACKAGE_OVERLAYS += $(COMMON_PATH)/overlay

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(COMMON_PATH)

# Proprietary files (only used once the vendor partition is built)
$(call inherit-product-if-exists, vendor/lenovo/pearl-common/pearl-common-vendor.mk)
