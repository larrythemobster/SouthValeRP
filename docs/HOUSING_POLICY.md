# SouthVale Housing Policy

New characters do not receive a free apartment or house. `qbx_core` has `startingApartment = false`, and `qbx_properties` rejects the legacy starter-apartment claim event server-side.

New characters use the public locations configured in `qbx_spawn`. Existing characters can use owned-property spawn choices only for properties they already own or have keys to.

Properties for sale are created through the existing `qbx_properties` realtor flow and are purchased with the normal `Buy` action. The server validates proximity, ownership state, and removes the configured price from cash or bank before assigning ownership.

## Existing legacy starter apartments

This change does not delete any property rows that were granted before the policy changed. Deleting or transferring existing player property is intentionally not automated. Before any cleanup, back up the live `qbox` database and review candidate rows. A useful read-only audit is:

```sql
SELECT id, property_name, owner, price, coords, interior
FROM properties
WHERE owner IS NOT NULL
  AND price = 0
  AND (
    property_name LIKE 'Del Perro Heights Apt %' OR
    property_name LIKE '4 Integrity Way Apt %' OR
    property_name LIKE 'Richard Majestic Apt %' OR
    property_name LIKE 'Tinsel Towers Apt %'
  )
ORDER BY id;
```

Do not delete those rows blindly; a database backup and ownership review should come first.
