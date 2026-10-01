# Testing the CIS droids locally

There is no real unit-test runtime for in-game nextbot behavior — you verify it by running
Garry's Mod, spawning the droids, and watching them. This guide gives you a repeatable way to do
that, mapped to the use cases in `specs/001-droid-difficulty/spec.md`.

## 0. Prerequisites

- Garry's Mod installed.
- The TFA base + the weapon `tfa_sw_blaster_e5_upgrade` installed (the droids read their stats).
- The droid/blaster models (`models/b1/...`, `models/kuro/...`) installed.
  If a model is missing you'll see an ERROR model but the logic still runs.

## 1. Load the addon

Make the game see this folder. Pick one:

- **Copy:** copy the whole `ivo_npc` folder into
  `steamapps/common/GarrysMod/garrysmod/addons/ivo_npc`.
- **Symlink (recommended, no re-copying while you edit)** — run in an **admin** PowerShell:

```powershell
New-Item -ItemType SymbolicLink `
  -Path "C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\addons\ivo_npc" `
  -Target "D:\personal\mod\ivo_npc"
```

The `_backup/`, `specs/` and `*.md` files are ignored via `addon.json`, so they won't be mounted.

## 2. Launch a test session

1. Start GMod → **New Game** → pick a map **with a navmesh** so pathfinding works
   (e.g. `gm_construct` usually has one; many SWRP maps do).
2. Open the console (`~`). If it's disabled: Options → Keyboard → Advanced → enable developer console.
3. Enable cheats + dev visuals:

```
sv_cheats 1
developer 1
```

4. If the map has **no navmesh**, build a quick one (slow but works):

```
nav_generate
```

The droids still chase/shoot without a navmesh (they fall back to a direct approach), but pathing
quality only shows with one.

## 3. Spawn droids

Two ways:

- **Spawn menu:** hold `Q` → **NPCs** tab → **Star Wars** category → `Droide B1/B2/BX`.
- **Test console commands** (from `lua/autorun/server/droid_test.lua`, superadmin/listen host):

```
droid_spawn b1 3      // spawn 3 B1s in front of you
droid_spawn bx 1      // spawn 1 BX
droid_debug 1         // floating overlay: tier, style, allies, target, dist, spread, HP
droid_clear           // remove all droids
```

`droid_debug 1` draws each droid's **detection sphere** and live state — this is the fastest way to
see what the AI is "thinking".

## 4. Verify each use case

Reference points from the client (use `setpos`/`setang` to teleport yourself):

```
setpos 6615.286133 1042.376221 -421.968750;setang 0.132005 -0.443113 0.000000
setpos 8270.686523 1026.663940 -421.968750;setang 88.735992 0.612887 0.000000
```

These two points are ~1655 units apart — the B1 detection radius baseline.

| Use case | How to test | Pass condition |
|---|---|---|
| UC-2 radius/visibility | Spawn a B1 at point A. Stand at point B (~1655u, with LOS). Then step a bit further / break LOS behind a wall. | Engages with LOS in range; drops you when out of radius or LOS. The `droid_debug` sphere shows the radius. |
| UC-1 random target | `bind` nothing; get 2-3 players (or use bots: `bot` x3). Spawn several B1s. | Over a few seconds droids pick *different* visible players, not always the closest. |
| UC-3 accuracy vs distance | Stand close, watch tracers; back away toward max range. Compare B1 vs BX. | Tight grouping < 50% range, scatters near max range; BX scatters far less than B1. The overlay's `spread` value rises with distance. |
| UC-4 difficulty gradient | Spawn one of each, fight them. | BX tankier, hits harder/faster/farther/more accurately than B2 than B1. |
| UC-5 squad rush | `droid_spawn b1 4` close together, then expose yourself. | They converge and push you as a group (overlay style = `rush`, allies ≥ 2). |
| UC-6 lone hold/run | `droid_spawn b1 1` repeatedly (or far apart). | Style is `hold` ~half the time (stands and shoots) and `rungun` ~half (advances while shooting). |
| UC-7 patrol | Spawn with no valid target (notarget yourself: `notarget`). | Droid wanders idly. |
| UC-8 spawning | Spawn each tier from the menu and via `droid_spawn`. | No red Lua errors in console. |

Helpful while testing:

```
notarget         // toggle: make yourself untargetable to test acquisition/loss
bot              // add an AI player as an extra target (repeat for more)
host_timescale 0.25   // slow-mo to watch spread/movement (set back to 1)
```

## 5. Catching Lua errors

- Watch the console while spawning. Lua errors print in red with the file + line.
- After any edit, fully reload: easiest is to restart the map (`map <name>`) or the game, since
  cached SENT files don't always hot-reload cleanly.
- Optional static check before launching — install **glualint**
  (<https://github.com/FPtje/GLuaFixer>) and run from the addon root:

```
glualint lua
```

This catches syntax mistakes without starting the game. (GMod uses LuaJIT, so a plain `luac`
syntax pass will reject GMod globals — `glualint` is the right tool.)

## 6. Tuning

All balance lives in two places:

- Shared defaults: `lua/entities/npc_droid_base/init.lua` → `GetDefaultConfig()`.
- Per-tier overrides: `lua/entities/npc_droid_<b1|b2|bx>/shared.lua` → `ENT.DroidConfig`.

Change a number, restart the map, re-test. The difficulty ordering table is documented in
`specs/001-droid-difficulty/spec.md` (UC-4).
