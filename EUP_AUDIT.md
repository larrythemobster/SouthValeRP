# SouthVale RP EUP audit — 2026-08-31

## Fixed in this package

- Added runtime validation for every EUP component and prop before a preset is applied.
- Invalid drawable/texture combinations are now refused instead of silently producing fallback/wrong clothing.
- Department/search menus mark incompatible presets as disabled.
- Piece-by-piece customizer hides variants that do not exist on the current streamed ped collection.
- Added `/eupaudit` to range-check the complete catalog for the current freemode gender and print details to F8.
- Added `/eupinspect` to print the currently worn collection names/local indexes; these are stable across GTA title updates and are the correct basis for a future-proof catalog.
- Added gender enforcement to the exported outfit setter.
- Quick Actions now save back through `illenium-appearance`, so removed hats/masks/vests/etc. persist.
- Job restriction now fails closed if Qbox/player data is unavailable when restriction is enabled.
- Stopped starting the unused legacy NativeUI EUP resource. `server.cfg` now explicitly starts only `eup-stream`, `southvale_law_eup`, and `eup-ui` in asset-before-UI order.
- The dead legacy `eup_ui.lua` remains in the repository for compatibility/history but is not referenced by the active manifest.
- Simplified `southvale_law_eup` manifest; `stream/` files are streamed automatically.

## Important unresolved asset mapping issue

`data/outfits.json` contains 163 presets from the old EUP 8.1-era catalog. The first LSPD entries exactly match the legacy 2018 preset definitions (for example male long-sleeve top 144:1, pants 36:1, shoes 52:1).

The supplied `southvale_text_files` archive intentionally contains text files only. It does not include the actual EUP `.ydd/.ytd` files, so there is no safe way in this package to determine the correct drawable/texture IDs for the current custom SouthVale law pack.

Do not blindly renumber the catalog. Deploy this package, run `/eupaudit` as both a male and female freemode character, and use the F8 output to identify which old presets are at least out of range. Note that an old global index can still be in range while pointing at the wrong garment on a newer title update. FiveM now recommends collection-based clothing identifiers because custom global indexes shift when Rockstar adds clothing. Use `/eupinspect` on known-good uniforms to capture collection/local identifiers. To fully remap the uniforms, audit the real `stream/` contents (or provide a full EUP resource archive that includes the clothing assets and their filenames/collection metadata).

## Current game build

`server.cfg` currently enforces GTA build 3095. This patch does not change it because changing game build without the real streamed EUP assets can create another clothing-index mismatch.


## Export tooling

The repository text-export scripts now include `.meta` files. FiveM clothing apparel metadata is text and is required to audit addon clothing collections correctly; previous exports silently omitted it.
