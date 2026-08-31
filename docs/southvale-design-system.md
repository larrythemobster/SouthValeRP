# SouthVale RP — Design System

Canonical source of truth: `server-data/resources/[southvale]/sv_identity/web/style.css` (`:root`).
sv_identity (character select / creation) was already built to this system; every other
player-facing surface should converge on the same tokens instead of inventing new ones.

## Tokens

```css
:root {
    /* Accent (gold) — selection, primary actions, focus, highlights only */
    --accent: #d8c85a;
    --accent-hover: #e5d76d;
    --accent-glow: rgba(216, 200, 90, 0.28);

    /* Surfaces — dark charcoal, not navy/neon */
    --bg-glass: rgba(12, 15, 18, 0.86);        /* page/background */
    --bg-glass-card: rgba(20, 24, 28, 0.76);   /* panel */
    --bg-glass-card-hover: rgba(255, 255, 255, 0.08);
    --bg-glass-card-selected: rgba(216, 200, 90, 0.12);
    --surface-stat: rgba(255, 255, 255, 0.035); /* elevated panel */

    /* Borders */
    --line: rgba(255, 255, 255, 0.10);
    --line-active: rgba(216, 200, 90, 0.55);

    /* Text hierarchy */
    --text: #f5f5f1;                     /* primary text (off-white) */
    --muted: rgba(245, 245, 241, 0.60);  /* secondary text */
    --muted-dim: rgba(245, 245, 241, 0.40); /* metadata/tertiary */

    /* Status */
    --danger: #e05353;
    --danger-hover: #eb6868;
    /* success/warning follow the same saturation/lightness family as danger:
       success ~ #4ade80 / warning ~ #f5a623 where a resource needs them */

    /* Shape & elevation */
    --shadow: 0 16px 48px -8px rgba(0, 0, 0, 0.65), 0 0 0 1px rgba(255, 255, 255, 0.05);
    --shadow-card: 0 4px 16px rgba(0, 0, 0, 0.35);
    --radius-lg: 16px;
    --radius-md: 12px;
    --radius-sm: 8px;
}
```

Spacing scale: 4 / 8 / 12 / 16 / 20 / 24 / 32px (see sv_identity `.field-grid`, `.actions`, `.panel`
gap/padding usage — no ad-hoc values outside this scale in new work).

Transitions: 120–200ms `ease`/`ease-out` only. No bounce, no infinite pulsing, no animated gradients
(see repo rule: `sv_identity` explicitly avoids `backdrop-filter` — FiveM's CEF renders it as a solid
black rectangle instead of a blur; never reintroduce it).

Typography: system font stack (`-apple-system, "Segoe UI", Roboto, ...`) or `Inter` where already
loaded (southvale_mdt). Do not add a second web font family per-resource.

## Applying the tokens where NUI can't share a CSS file

Every custom SouthVale NUI resource (`southvale_mdt`, `sv_identity`, future ones) ships as an
isolated `nui://` origin, so a single shared stylesheet can't be `<link>`ed across resources without
extra plumbing. Until/unless that's built, copy the token block above verbatim into each resource's
root stylesheet rather than re-deriving new hex values — this is why `southvale_mdt/html/style.css`
now uses the literal `#d8c85a` / `#e5d76d` / `rgba(216,200,90,*)` values from this table instead of a
locally-invented blue-replacement color.

## Vendor (ox_lib) theming

`ox_lib`'s NUI (context menus, alert/input dialogs, notifications, progress, radial, textUI) is a
Mantine app whose only supported runtime override is two convars read in
`[ox]/ox_lib/resource/client.lua`:

```
setr ox:primaryColor yellow   # server-data/ox.cfg — closest Mantine named palette to SouthVale gold
setr ox:primaryShade 5        # muted, not neon
```

Mantine only accepts a palette name registered in its theme (`dark, gray, red, ..., yellow, orange`),
not an arbitrary hex, via this convar — `yellow` at shade 5 is the closest available match to
`--accent`. If exact-hex parity is required later, it needs a custom Mantine theme file compiled into
`ox_lib`'s bundle (an upstream-file change, see Update Risk in the final report), not a convar.

## Status colors (do not replace with gold)

Success / warning / danger keep their own hues everywhere (durability bars, MDT tags/toasts, HUD
health/stress). Gold is reserved for selection, primary actions, focus rings, and brand marks — see
Section 6 of the design brief ("gold should not fill every slot").
