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

# Images are flashed one by one from fastbootd; no super_empty.img.
PRODUCT_BUILD_SUPER_EMPTY_IMAGE := false

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

# Bluetooth: since Android 13 the profiles are enabled by these properties instead of the
# Bluetooth app's config.xml; the stock Android 11 Bluetooth configuration predates them. The
# WCN3990 controller runs HCI 4.2, so the LE Audio profiles stay off. Class of device: Networking,
# Object Transfer and Audio services (0x32), major class Computer (1), minor class Tablet
# (7 << 2); optional, so that a device tree can set its own.
PRODUCT_PRODUCT_PROPERTIES += \
    bluetooth.device.class_of_device?=50,1,28 \
    bluetooth.profile.a2dp.source.enabled=true \
    bluetooth.profile.asha.central.enabled=true \
    bluetooth.profile.avrcp.target.enabled=true \
    bluetooth.profile.bas.client.enabled=true \
    bluetooth.profile.gatt.enabled=true \
    bluetooth.profile.hfp.ag.enabled=true \
    bluetooth.profile.hid.device.enabled=true \
    bluetooth.profile.hid.host.enabled=true \
    bluetooth.profile.opp.enabled=true \
    bluetooth.profile.pan.nap.enabled=true \
    bluetooth.profile.pan.panu.enabled=true \
    bluetooth.profile.pbap.server.enabled=true

# Speaker layout per display rotation for the stock audio HAL
PRODUCT_PACKAGES += \
    PearlAudioRotation

# Fstab. The bootloader passes androidboot.fstab_suffix=default; the stock vendor carries the
# same table as fstab.default and fstab.qcom. This is the stock table without the GSI avb_keys.
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_RAMDISK)/fstab.default \
    $(COMMON_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.default \
    $(COMMON_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.qcom

# Init: the stock init.target.rc without the services whose binaries are not shipped. It also
# loads the audio, Cirrus amplifier and Wi-Fi kernel modules.
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/rootdir/etc/init.target.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.target.rc

# Input: keyboard pack layout and pen configuration from the stock system partition.
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/keylayout/Vendor_17ef_Product_610b.kl:$(TARGET_COPY_OUT_SYSTEM)/usr/keylayout/Vendor_17ef_Product_610b.kl \
    $(COMMON_PATH)/idc/Vendor_beef_Product_dead.idc:$(TARGET_COPY_OUT_SYSTEM)/usr/idc/Vendor_beef_Product_dead.idc

# Static overlay, compiled into framework-res on system (RRO enforcement is off for this
# product).
DEVICE_PACKAGE_OVERLAYS += $(COMMON_PATH)/overlay

# Audio: Lenovo's audio module (audio.primary.sm6150, with the Cirrus CS35L41 calibration and
# protection) and its feature libraries stay stock; the AOSP HIDL 6.0 wrapper loads it.
# No sound trigger HAL: the stock sound_trigger.primary implements device API 1.0, while the
# sound trigger 2.3 wrapper, the lowest version the FCM 7 matrix accepts, needs API 1.3. It
# closes the device on open, which leaves the library in a state that aborts the audio
# module. Without the library the audio module skips sound trigger.
PRODUCT_PACKAGES += \
    android.hardware.audio.service \
    android.hardware.audio@6.0-impl \
    android.hardware.audio.effect@6.0-impl \
    android.hardware.bluetooth.audio-impl \
    audio.bluetooth.default \
    audio.r_submix.default \
    audio.usb.default \
    libaudiopreprocessing \
    libbundlewrapper \
    libdownmix \
    libdynproc \
    libeffectproxy \
    libldnhncr \
    libqti_vndfwk_detect.vendor \
    libreverbwrapper \
    libvisualizer

# Boot control
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl-qti \
    android.hardware.boot@1.2-impl-qti.recovery \
    android.hardware.boot@1.2-service

# Camera: the AOSP provider wrapper around the stock camera HAL
PRODUCT_PACKAGES += \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service_64

# Display (CAF sm8150 display HAL, as on the LineageOS sm6150 devices)
PRODUCT_PACKAGES += \
    android.hardware.graphics.composer@2.4-service \
    android.hardware.graphics.mapper@3.0-impl-qti-display \
    android.hardware.graphics.mapper@4.0-impl-qti-display \
    gralloc.sm6150 \
    hwcomposer.sm6150 \
    lights.sm6150 \
    vendor.qti.hardware.display.allocator-service \
    vendor.qti.hardware.memtrack-service

# The AOSP base vendor adds the configstore HAL for shipping API level 29. It is deprecated
# (absent from the FCM 7 matrix), the stock vendor did not ship it, and SurfaceFlinger reads
# its settings from system properties.
PRODUCT_PACKAGES += \
    disable_configstore

# Fingerprint: the AOSP 2.1 service loads Goodix's fingerprint.default module (blob)
PRODUCT_PACKAGES += \
    android.hardware.biometrics.fingerprint@2.1-service

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.qti \
    android.hardware.health-service.qti_recovery

# Media: CAF OMX core and video components; the stock Codec2 service and OMX audio encoders stay
PRODUCT_PACKAGES += \
    android.hardware.cas@1.2-service \
    android.hardware.media.omx@1.0-service \
    libc2dcolorconvert \
    libOmxCore \
    libOmxVdec \
    libOmxVenc \
    libplatformconfig \
    libstagefrighthw

# Power (QTI AIDL power HAL over the stock perf HAL)
PRODUCT_PACKAGES += \
    android.hardware.power-service-qti

# RenderScript
PRODUCT_PACKAGES += \
    android.hardware.renderscript@1.0-impl

# Sensors: AOSP multi-HAL over the stock sensors.ssc sub-HAL
PRODUCT_PACKAGES += \
    android.hardware.sensors@2.0-service.multihal

# Trace
PRODUCT_PACKAGES += \
    android.hardware.atrace@1.0-service

# USB
PRODUCT_PACKAGES += \
    android.hardware.usb@1.0-service

# Vibrator
PRODUCT_PACKAGES += \
    vendor.qti.hardware.vibrator.service

# Wi-Fi: the HAL service, hostapd and wpa_supplicant from source, over the source
# libwifi-hal-qcom. The stock HAL 1.4 service was built against the Android 11 wifi_hal_fn
# table, which the current libwifi-hal overruns. The AIDL service declares its own manifest
# fragment.
# libwpa_client is linked by the stock lowi-server and mutualex; mutualex also links the HIDL
# hostapd and supplicant 1.0 libraries. Both use DISABLE_DEPS, so these are listed here.
PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    android.hardware.wifi.hostapd@1.0.vendor \
    android.hardware.wifi.supplicant@1.0.vendor \
    firmware_WCNSS_qcom_cfg.ini_symlink \
    firmware_wlan_mac.bin_symlink \
    firmware_wlanmdsp.otaupdate_symlink \
    hostapd \
    ipacm \
    IPACM_cfg.xml \
    libwifi-hal-qcom \
    libwpa_client \
    wpa_supplicant \
    wpa_supplicant.conf

# Feature files of the stock vendor. handheld_core_hardware.xml replaces Lenovo's Android 11
# copy with the current AOSP one.
PRODUCT_COPY_FILES += \
    $(foreach f, \
        android.hardware.audio.low_latency.xml \
        android.hardware.audio.pro.xml \
        android.hardware.bluetooth.xml \
        android.hardware.bluetooth_le.xml \
        android.hardware.camera.flash-autofocus.xml \
        android.hardware.camera.front.xml \
        android.hardware.camera.full.xml \
        android.hardware.camera.raw.xml \
        android.hardware.fingerprint.xml \
        android.hardware.location.gps.xml \
        android.hardware.opengles.aep.xml \
        android.hardware.sensor.accelerometer.xml \
        android.hardware.sensor.compass.xml \
        android.hardware.sensor.gyroscope.xml \
        android.hardware.sensor.light.xml \
        android.hardware.sensor.proximity.xml \
        android.hardware.sensor.stepcounter.xml \
        android.hardware.sensor.stepdetector.xml \
        android.hardware.touchscreen.multitouch.jazzhand.xml \
        android.hardware.usb.accessory.xml \
        android.hardware.usb.host.xml \
        android.hardware.vulkan.compute-0.xml \
        android.hardware.vulkan.level-1.xml \
        android.hardware.vulkan.version-1_1.xml \
        android.hardware.wifi.aware.xml \
        android.hardware.wifi.direct.xml \
        android.hardware.wifi.passpoint.xml \
        android.hardware.wifi.rtt.xml \
        android.hardware.wifi.xml \
        android.software.ipsec_tunnels.xml \
        android.software.midi.xml \
        android.software.sip.voip.xml \
        android.software.verified_boot.xml \
        handheld_core_hardware.xml, \
        frameworks/native/data/etc/$(f):$(TARGET_COPY_OUT_VENDOR)/etc/permissions/$(f))

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(COMMON_PATH)

# Proprietary files
$(call inherit-product, vendor/lenovo/pearl-common/pearl-common-vendor.mk)
