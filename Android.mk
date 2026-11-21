#
# SPDX-FileCopyrightText: 2020-2024 The LineageOS Project
# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifneq ($(filter j706f j706l,$(TARGET_DEVICE)),)

# Mount points of the modem, bluetooth and dsp partitions (fstab.qcom), empty directories in
# the stock vendor image. Without them init's mount_all --early (init.target.rc) mounts none
# of the three, and no
# remote processor (ADSP, CDSP, modem/Wi-Fi, video) finds its firmware. The vendor image is
# read-only, so they are created at build time. As in LineageOS
# android_device_xiaomi_sm6150-common (lineage-21, 6d916c791d80) Android.mk.
FIRMWARE_MOUNT_POINT := $(TARGET_OUT_VENDOR)/firmware_mnt
$(FIRMWARE_MOUNT_POINT):
	@echo "Creating $(FIRMWARE_MOUNT_POINT)"
	@mkdir -p $(FIRMWARE_MOUNT_POINT)

BT_FIRMWARE_MOUNT_POINT := $(TARGET_OUT_VENDOR)/bt_firmware
$(BT_FIRMWARE_MOUNT_POINT):
	@echo "Creating $(BT_FIRMWARE_MOUNT_POINT)"
	@mkdir -p $(BT_FIRMWARE_MOUNT_POINT)

DSP_MOUNT_POINT := $(TARGET_OUT_VENDOR)/dsp
$(DSP_MOUNT_POINT):
	@echo "Creating $(DSP_MOUNT_POINT)"
	@mkdir -p $(DSP_MOUNT_POINT)

ALL_DEFAULT_INSTALLED_MODULES += $(FIRMWARE_MOUNT_POINT) $(BT_FIRMWARE_MOUNT_POINT) $(DSP_MOUNT_POINT)

endif
