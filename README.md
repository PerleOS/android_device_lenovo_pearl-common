<!--
SPDX-FileCopyrightText: The PerleOS Project
SPDX-License-Identifier: Apache-2.0
-->

# Lenovo Tab P11 Pro common tree (pearl)

Common PerleOS device tree for the Lenovo Tab P11 Pro family (codename `pearl`): TB-J706F (Wi-Fi), with the TB-J706L (LTE) prepared later. PerleOS is based on LineageOS 21 (`lineage-21.0`). It is not affiliated with Lenovo or LineageOS.

| Device | Tree |
|---|---|
| TB-J706F | [`android_device_lenovo_j706f`](https://github.com/PerleOS/android_device_lenovo_j706f) |

## Current phase

The trees build `system`, `system_ext` and `product` only. The stock vendor, kernel, DTB and DTBO of the TB-J706F firmware `S620150_211226_ROW` stay on the device. These images are written to `system_a`, `system_ext_a` and `product_a`. Never use `fastboot update`, `flashall` or `update-super` with them: their super layout has no `vendor`, so those commands would remove `vendor_a` from the device.

## Rules for contributors

- Proprietary files come only from the stock TB-J706F S620150 ROW firmware. Never use files from another model (TB-J716F, TB-J606F, TB-Q706F, TB-132FU, YT-J706F) or from another release.
- No device-unique data: no `persist` content, serial numbers or MAC addresses.
- Do not write to calibration or security partitions (`persist`, `modemst1/2`, `fsg`, `devinfo`, `xbl*`, `abl`, GPT…). Do not relock the bootloader.
- New files carry `SPDX-FileCopyrightText: The PerleOS Project` and `SPDX-License-Identifier: Apache-2.0`. Keep upstream headers as they are.

## Licence

Apache-2.0, see `LICENSE`, except `rootdir/etc/fstab.qcom`, which keeps its BSD-3-Clause header from The Linux Foundation.
