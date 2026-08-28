# EUP UI (Emergency Uniforms Pack Wardrobe)

Modern, lightweight, and high-performance Emergency Uniforms Pack (EUP) wardrobe management resource built with `ox_lib` for SouthVale RP.

## Features

- **900+ Standard Outfits**: Pre-configured presets for all emergency departments (LSPD, BCSO, SASP, SAHP, LSSD, LSFD, BCFD, LSCoFD, SanFire, Medical Services, FIB, USMS, IAA, NOOSE, Lifeguard, etc.).
- **Zero Overhead**: Built on `ox_lib` context menus instead of legacy NativeUI (0.00ms idle).
- **Auto Gender Filtering**: Automatically displays Male or Female uniforms based on the player ped model (`mp_m_freemode_01` / `mp_f_freemode_01`).
- **Quick Uniform Actions**: Easily toggle hats, helmets, masks, glasses, body armor/vests, and bags.
- **illenium-appearance Integration**: Automatically syncs and saves outfits to `illenium-appearance` if present.
- **Permissions Support**: Configurable ACE permission check and/or Qbox job checks.

## Commands

- `/eup` - Opens the EUP Wardrobe menu.

## Exports

### Client
```lua
exports['eup-ui']:OpenEUPMenu()
exports['eup-ui']:SetOutfit(outfitData)
exports['eup-ui']:GetOutfits()
exports['eup-ui']:GetCategorizedOutfits()
```
