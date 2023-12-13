# wsusoffline-release
This repository contains wsusoffline package (Windows Update Pack) for supported Windows and Office versions

See the [releases](https://github.com/LizenzFass78851/wsusoffline-release/releases) to download the releases

| Product | Link |
|:------------------:|:--------------:|
| Windows Server 2012 (x64) | [w62-x64](https://github.com/LizenzFass78851/wsusoffline-release/releases/tag/w62-x64) |
| Windows 8.1 (x86) | [w63](https://github.com/LizenzFass78851/wsusoffline-release/releases/tag/w63) |
| Windows 8.1 / Windows Server 2012 R2 (x64) | [w63-x64](https://github.com/LizenzFass78851/wsusoffline-release/releases/tag/w63-x64) |
| Office 2013 (x86/x64) | [o2k13](https://github.com/LizenzFass78851/wsusoffline-release/releases/tag/o2k13) |
| Office 2016 (x86/x64) | [o2k16](https://github.com/LizenzFass78851/wsusoffline-release/releases/tag/o2k16) |

### Why is Windows 10 and newer not supported?
Because from Windows 10 and its server variants it may be easier to get this appropriate cromulative update, which contains all the changes for the corresponding Windows 10 version or newer.
These cromulative updates for Windows 10 and newer can be found under the Microsoft update catalog:
https://www.catalog.update.microsoft.com (example search term: `2023-11 Update for Windows 10 22h2`)

### Build state: 
[![generate_products](https://github.com/LizenzFass78851/wsusoffline-release/actions/workflows/generate_products.yml/badge.svg?branch=main)](https://github.com/LizenzFass78851/wsusoffline-release/actions/workflows/generate_products.yml)

### Notes:
The ISOs published there are split into 1.9 GB files each.
Put these back together under Linux using the cut command.
On Windows this is possible with 7zip, but the files that follow with .aa .ab and so on can be renamed to .001 .002 and so on.
