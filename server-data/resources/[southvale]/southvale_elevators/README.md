# southvale_elevators

Generic multi-floor elevator system. Ships with **zero pre-placed floors** --
world coordinates for specific SouthVale RP interiors can't be authored
without visiting them in-game, so this resource is the *tool* an admin uses
to place them, following the same capture-and-save pattern `ox_lib`'s own
`zoneCreator` uses for `created_zones.lua`.

## Setting up a shaft (admin only, requires ACE `command`)

1. Stand at the ground-floor call point of the building.
   `/elevator addshaft mrpd "Mission Row PD"`
2. Stand at each additional floor's call point and add it to the shaft:
   `/elevator addfloor mrpd "Ground Floor"`
   `/elevator addfloor mrpd "Detective Bureau"`
   `/elevator addfloor mrpd "Roof"`
3. `/elevator list` to review, `/elevator removefloor mrpd "Roof"` /
   `/elevator removeshaft mrpd` to undo.

Every change is written to `data/shafts.json` immediately and pushed live to
all connected clients -- no restart required.

## In-game use

Walking up to any placed floor's call point offers **"Call Elevator"** via
`ox_target`. Selecting it opens a menu of the shaft's other floors; picking
one fades the screen, moves the player to that floor's coordinates, and
fades back in.
