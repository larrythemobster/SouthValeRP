# sv_first_appearance

SouthVale-owned first-character appearance editor.

## Scope

- Used only during the new-character handoff from `sv_identity`.
- Normal Illenium clothing stores, barber shops, tattoo shops, surgeon shops, outfit menus, and admin ped menus are unchanged.
- Uses Illenium's public appearance exports for live ped changes.
- Saves through `illenium-appearance:server:saveAppearance`, so the existing `playerskins` persistence path remains authoritative.
- Uses Illenium's routing-bucket events while the first-character editor is open.

## Categories

1. Heritage
2. Face
3. Hair / eyes
4. Skin details and overlays
5. Clothing
6. Accessories

The identity-selected gender determines the freemode ped model and is intentionally not changeable in this UI.
