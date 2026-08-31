# sv_identity

SouthVale RP presentation layer for Qbox character selection, registration, first appearance, and spawn selection.

## Ownership boundaries

`sv_identity` does **not** create or persist player rows itself. It delegates character listing, creation, login, deletion, slot enforcement, citizen-id generation, starter items, and ownership checks to the installed `qbx_core` callbacks.

The resource also reuses:

- `qbx_core` preview skin callback for stored character appearance.
- `illenium-appearance` for first-character customization and appearance persistence.
- `qbx_properties` when Qbox starter apartments are enabled.
- `qbx_spawn` callbacks/configuration for existing-character spawn destinations and safe public destinations when starter apartments are disabled.

## Qbox integration

`qbx_core.config.client.characters.useExternalCharacters` is enabled so the stock ox_lib multicharacter presentation does not race the SouthVale NUI.

SouthVale disables Qbox starter apartments. New-character flow is therefore:

1. SouthVale identity registration.
2. `qbx_core:server:createCharacter` (server-owned slot/citizen ID/starter data).
3. `illenium-appearance` first-character customization and save.
4. SouthVale public spawn selection from `qbx_spawn`; no property is granted.
5. Normal Qbox `OnPlayerLoaded` lifecycle.

New characters are offered only the public destinations already configured in `qbx_spawn`; they do not receive Last Location or owned-property choices on their first spawn. Housing is obtained later through the normal `qbx_properties` purchase/rental flow.

## Small upstream changes

Two narrow compatibility changes are intentionally included:

- `qbx_core/server/character.lua` strengthens the authoritative create callback by validating gender, ISO birth date/range, control characters, and configured nationalities.
- `illenium-appearance/client/framework/qb/main.lua` does not reopen first-character customization if a saved appearance already exists. This prevents any later appearance handoff from showing first-character customization twice after SouthVale completes appearance first.
