#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

# If XML files don't have comments before the XML header, use this flag
# Can still be used with broken XML files by using blob_fixup
export TARGET_DISABLE_XML_FIXING=true

# Package libraries and binaries as Soong prebuilts with their dependencies checked
export TARGET_ENABLE_CHECKELF=true

# patchelf 0.9 can damage binaries when adding a needed library
export PATCHELF_VERSION=0_17_2

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_FIRMWARE=
ONLY_TARGET=
KANG=
SECTION=
CARRIER_SKIP_FILES=()

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-common)
            ONLY_COMMON=true
            ;;
        --only-firmware)
            ONLY_FIRMWARE=true
            ;;
        --only-target)
            ONLY_TARGET=true
            ;;
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

# Blobs come only from an unpacked stock TB-J706F_S620150_211226_ROW dump, never from a
# connected device (which may run another firmware) or another model.
if [ -z "${SRC}" ] || [ "${SRC}" = "adb" ]; then
    echo "Usage: ${0} [options] <path to the unpacked stock S620150 ROW partitions>"
    exit 1
fi

function blob_fixup() {
    case "${1}" in
        vendor/lib/hw/audio.primary.sm6150.so | vendor/lib64/hw/audio.primary.sm6150.so)
            # mixer_update_ctls() came from Qualcomm's libtinyalsa VNDK extension
            [ "$2" = "" ] && return 0
            grep -q "libtinyalsa_shim.so" "${2}" || "${PATCHELF}" --add-needed "libtinyalsa_shim.so" "${2}"
            ;;
        vendor/etc/init/hw/init.qcom.rc)
            # The stock wpa_supplicant service declares only the HIDL interfaces and, parsed first,
            # would hide the source-built AIDL service of the same name.
            # qti-testscripts runs /product/etc/init.qcom.testscripts.sh, which no build ships.
            [ "$2" = "" ] && return 0
            sed -i -e '/^service wpa_supplicant /,/^$/d' -e '/^service qti-testscripts /,/^$/d' \
                -e '/^    start qti-testscripts$/d' "${2}"
            ;;
        vendor/etc/init/hw/init.qcom.usb.rc|vendor/etc/init/hw/init.qti.ufs.rc)
            # The QTI debug scripts run in vendor-qti-testscripts, a domain the vendor policy
            # defines only on userdebug and eng builds; on user builds init aborts the exec
            [ "$2" = "" ] && return 0
            sed -i '/exec u:r:vendor-qti-testscripts:s0 /d' "${2}"
            ;;
        vendor/bin/hw/android.hardware.lights-service.qti)
            # The _platform suffix of NDK AIDL libraries was dropped in Android 13
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.hardware.light-V1-ndk_platform.so" "android.hardware.light-V1-ndk.so" "${2}"
            ;;
        vendor/lib64/hw/fingerprint.default.so)
            # Goodix ships it with DT_SONAME libfingerprint.default.so; it is only loaded by path
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --set-soname "fingerprint.default.so" "${2}"
            ;;
        vendor/lib64/libvendor.goodix.hardware.biometrics.fingerprint@2.1.so)
            # gBnConstructorMap, no longer exported by libhidlbase
            [ "$2" = "" ] && return 0
            grep -q "libhidlbase_shim.so" "${2}" || "${PATCHELF}" --add-needed "libhidlbase_shim.so" "${2}"
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

if [ -z "${ONLY_FIRMWARE}" ] && [ -z "${ONLY_TARGET}" ]; then
    # Initialize the helper for common device
    setup_vendor "${DEVICE_COMMON}" "${VENDOR_COMMON:-$VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${ONLY_COMMON}" ] && [ -s "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../../${VENDOR}/${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

    if [ -z "${ONLY_FIRMWARE}" ]; then
        extract "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
    fi

    if [ -z "${SECTION}" ] && [ -f "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-firmware.txt" ]; then
        extract_firmware "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-firmware.txt" "${SRC}"
    fi
fi

"${MY_DIR}/setup-makefiles.sh"
