#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#

import os
import struct
import sys
from functools import partial

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixup_remove,
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)
from extract_utils.tools import patchelf_version_path_map
from extract_utils.utils import run_cmd

# patchelf 0.9 can damage binaries when adding a needed library
PATCHELF_VERSION = '0_17_2'

namespace_imports = [
    'device/lenovo/pearl-common',
    'hardware/qcom-caf/sm8150',
    'hardware/qcom-caf/wlan',
    'vendor/qcom/opensource/commonsys/display',
    'vendor/qcom/opensource/commonsys-intf/display',
    'vendor/qcom/opensource/dataservices',
    'vendor/qcom/opensource/display',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}-vendor' if partition == 'vendor' else None


def lib_fixup_vendor_remove(lib: str, partition: str, *args, **kwargs):
    return lib_fixup_remove(lib) if partition == 'vendor' else None


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        'com.qualcomm.qti.dpm.api@1.0',
        'vendor.qti.imsrtpservice@3.0',
    ): lib_fixup_vendor_suffix,
    'libwpa_client': lib_fixup_vendor_remove,
}


def patchelf(*patchelf_args: str):
    # Always through patchelf, as the bash helpers did: replace_needed() edits the string in
    # place when the new name is not longer
    def impl(ctx, file, file_path, *args, **kwargs):
        run_cmd([patchelf_version_path_map[PATCHELF_VERSION], *patchelf_args, file_path])

    return partial(impl)


blob_fixups: blob_fixups_user_type = {
    ('vendor/lib/hw/audio.primary.sm6150.so', 'vendor/lib64/hw/audio.primary.sm6150.so'): blob_fixup()
        # mixer_update_ctls() came from Qualcomm's libtinyalsa VNDK extension
        .patchelf_version(PATCHELF_VERSION)
        .add_needed('libtinyalsa_shim.so'),
    'vendor/etc/init/hw/init.qcom.rc': blob_fixup()
        # The stock wpa_supplicant service declares only the HIDL interfaces and, parsed first,
        # would hide the source-built AIDL service of the same name.
        # qti-testscripts runs /product/etc/init.qcom.testscripts.sh, which no build ships.
        .regex_replace(r'(?m)^service wpa_supplicant [^\n]*\n(?:[^\n]+\n)*\n', '')
        .regex_replace(r'(?m)^service qti-testscripts [^\n]*\n(?:[^\n]+\n)*\n', '')
        .regex_replace(r'(?m)^    start qti-testscripts\n', ''),
    ('vendor/etc/init/hw/init.qcom.usb.rc', 'vendor/etc/init/hw/init.qti.ufs.rc'): blob_fixup()
        # The QTI debug scripts run in vendor-qti-testscripts, a domain the vendor policy
        # defines only on userdebug and eng builds; on user builds init aborts the exec
        .regex_replace(r'(?m)^[^\n]*exec u:r:vendor-qti-testscripts:s0 [^\n]*\n', ''),
    'vendor/bin/hw/android.hardware.lights-service.qti': blob_fixup()
        # The _platform suffix of NDK AIDL libraries was dropped in Android 13
        .call(patchelf('--replace-needed', 'android.hardware.light-V1-ndk_platform.so',
                       'android.hardware.light-V1-ndk.so')),
    (
        'vendor/lib/mediadrm/libwvdrmengine.so',
        'vendor/lib64/mediadrm/libwvdrmengine.so',
        'vendor/lib64/libwvhidl.so',
    ): blob_fixup()
        # CBS_init, inline in later BoringSSL versions
        .patchelf_version(PATCHELF_VERSION)
        .add_needed('libcrypto_shim.so'),
    'vendor/etc/wifi/wpa_supplicant_overlay.conf': blob_fixup()
        # The supplicant template forces RSN overriding on; the driver builds the association
        # request (no WPA_DRIVER_FLAGS_SME) without the RSN selection element, so access points
        # in WPA2/WPA3 transition mode with RSNE override reject EAPOL-Key 2/4. Read after
        # wpa_supplicant.conf, the overlay turns it off.
        .add_line_if_missing('rsn_overriding=0'),
    'vendor/lib64/hw/fingerprint.default.so': blob_fixup()
        # Goodix ships it with DT_SONAME libfingerprint.default.so; it is only loaded by path
        .call(patchelf('--set-soname', 'fingerprint.default.so')),
    'vendor/lib64/libvendor.goodix.hardware.biometrics.fingerprint@2.1.so': blob_fixup()
        # gBnConstructorMap, no longer exported by libhidlbase
        .patchelf_version(PATCHELF_VERSION)
        .add_needed('libhidlbase_shim.so'),
}  # fmt: skip

module = ExtractUtilsModule(
    'pearl-common',
    'lenovo',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    # Blobs come only from an unpacked stock TB-J706F_S620150_211226_ROW dump, never from a
    # connected device (which may run another firmware) or another model.
    positional = [a for a in sys.argv[1:] if not a.startswith('-')]
    if '--regenerate_makefiles' not in sys.argv and (not positional or 'adb' in positional):
        sys.exit(f'Usage: {sys.argv[0]} [options] <path to the unpacked stock S620150 ROW partitions>')

    utils = ExtractUtils.device(module)
    utils.run()

    # The stock dtbo, which the recovery image carries as recovery_dtbo
    # (BOARD_INCLUDE_RECOVERY_DTBO), cut to the size in its DT table header, as the stock
    # recovery embeds it. Taken from dtbo.img next to the unpacked partitions.
    if positional:
        src = os.path.join(positional[0], 'dtbo.img')
        if not os.path.isfile(src):
            sys.exit(f'{src} missing: copy the stock dtbo.img next to the unpacked partitions')
        with open(src, 'rb') as f:
            data = f.read()
        magic, total_size = struct.unpack('>II', data[:8])
        if magic != 0xD7B7AB1E:
            sys.exit(f'{src}: not a DT table image')
        dst = os.path.join(module.vendor_path, 'prebuilt', 'dtbo.img')
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(data[:total_size])
