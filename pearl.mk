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

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(COMMON_PATH)

# Proprietary files (only used once the vendor partition is built)
$(call inherit-product-if-exists, vendor/lenovo/pearl-common/pearl-common-vendor.mk)
