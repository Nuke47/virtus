# Spec 001 — CIS Droid Difficulty Tiers (B1 / B2 / BX)

Status: Draft
Owner: ivo_npc
Target: Garrysmod nextbot SENT (`base_nextbot`)

## 1. Summary

Turn the single hostile droid (`droid_npc`) into three spawnable variants — **B1**, **B2**,
and **BX** — of strictly increasing combat difficulty. Difficulty is expressed through
**pathing quality**, **engagement (fire) range**, and **overall accuracy**. The droids must
acquire **random, currently-visible** targets, degrade accuracy with distance, and coordinate
as squads (rush together when grouped, run-and-gun or hold position when alone).

## 2. Glossary

- **Detection radius** — sphere around the droid in which it looks for players. Derived from the
  client's two reference points:
  - A: `6615.286133  1042.376221  -421.968750`
  - B: `8270.686523  1026.663940  -421.968750`
  - Distance ≈ **1655 units** → baseline detection radius.
- **Fire range** — max distance at which the droid will open fire (≤ detection radius).
- **Visible** — clear line of sight (trace from droid eye to target eye reaches the target).
- **Spread** — bullet cone; lower = more accurate.
- **Ally** — any other droid SENT in this addon (`IsDroidNPC == true`).

## 3. Actors

- **Player** — target. May be alive/dead, may have `FL_NOTARGET`.
- **Droid (B1/B2/BX)** — the nextbot.
- **Allied droids** — nearby droids that may form a squad.

## 4. Use cases

### UC-1 — Acquire a random visible target
**Trigger:** droid has no valid enemy.
**Flow:**
1. Collect every player that is `Alive()`, not `FL_NOTARGET`, within **detection radius**, and **visible** (LOS).
2. If the set is non-empty, pick **one at random** (not the nearest) as the current enemy.
3. If empty, enter Patrol (UC-7).
**Re-evaluation:** every `RetargetInterval` seconds, or immediately if the current enemy dies / leaves radius / becomes permanently unreachable, re-run the pick.
**Acceptance:** with 3 visible players, repeated spawns target different players over time (random, not deterministic nearest).

### UC-2 — Player-in-radius check
**Trigger:** continuous.
**Flow:** droid reports whether at least one valid+visible player is within detection radius.
**Acceptance:** standing a player at point A while the droid is within ~1655 u and has LOS makes the droid engage; moving the player beyond the radius (or breaking LOS by ducking behind geometry) drops detection.

### UC-3 — Distance-based accuracy
**Trigger:** droid fires.
**Flow:**
1. Compute `frac = clamp(distanceToEnemy / FireRange, 0, 1)`.
2. If `frac <= AccurateFraction` (default **0.5**, "over 50% of the visible field"): use `BaseSpread`.
3. Else lerp spread from `BaseSpread` → `MaxSpread` across the remaining range.
4. Apply spread to the shot (bullet `Spread`, or angular jitter for projectiles).
**Acceptance:** shots inside 50% of fire range are tight; shots near max range visibly scatter. Harder tiers scatter less.

### UC-4 — Difficulty scaling (B1 < B2 < BX)
Each tier overrides a config table. Required monotonic ordering:

| Field            | B1 (easy) | B2 (medium) | BX (hard) | Effect |
|------------------|-----------|-------------|-----------|--------|
| Health           | 80        | 160         | 300       | survivability |
| DetectRadius     | 1655      | 1900        | 2400      | sees farther |
| FireRange        | 900       | 1300        | 1900      | shoots farther |
| BaseSpread       | 0.085     | 0.045       | 0.018     | close accuracy |
| MaxSpread        | 0.22      | 0.13        | 0.06      | far accuracy |
| FireRateMult     | 1.35      | 1.0         | 0.7       | ×TFA delay (lower = faster) |
| DamageMult       | 0.9       | 1.0         | 1.25      | damage |
| WalkSpeed        | 70        | 90          | 110       | move while firing |
| RunSpeed         | 150       | 190         | 240       | reposition speed |
| RepathInterval   | 0.5       | 0.3         | 0.15      | pathing smartness |
| LookAhead        | 200       | 300         | 420       | corner smoothing |

**Acceptance:** values are inherited/merged from a base; spawning each tier shows the expected
behavioral gradient.

### UC-5 — Squad rush
**Trigger:** droid has an enemy AND `nearbyAllies >= SquadMin` within `SquadRadius`.
**Flow:** path **directly and aggressively** toward the enemy at `RushSpeed`, tighter goal
tolerance; keep firing when in range/LOS. Re-evaluated ~1×/sec so the style changes if allies die.
**Acceptance:** 3 droids spawned together converge and push the player as a group.

### UC-6 — Lone behavior (50/50)
**Trigger:** droid has an enemy AND fewer than `SquadMin` allies nearby.
**Flow:** decide **once per engagement** (re-rolled when style is recomputed):
- **Run-and-gun** (50%): keep moving toward/around the target while firing.
- **Hold position** (50%): stop and fire from current spot; only reposition if LOS is lost or it gets stuck.
**Acceptance:** repeated lone engagements show roughly half holding and half advancing.

### UC-7 — Patrol (no target)
**Trigger:** no valid visible target.
**Flow:** wander to a random nearby position, idle briefly, retry acquisition.

### UC-8 — Spawning
**Flow:** each variant appears in the **NPCs → Star Wars** spawn menu and spawns by a class whose
name **matches its folder**. (Fixes the original `droid_npc` folder vs `npc_droide` class mismatch.)
**Acceptance:** all three spawn without console errors.

## 5. Non-functional / constraints

- Server-authoritative behavior (logic in `init.lua`); client only draws.
- Reuse TFA weapon stats via `weapons.GetStored` (`tfa_sw_blaster_e5_upgrade` by default), with safe fallbacks.
- No errors if the weapon/model/attachment is missing (graceful degradation, as today).
- Clean up the held weapon prop on removal.
- Avoid per-frame allocations in the tight loops where reasonable.

## 6. Out of scope

- New models/animations/sounds (reuse existing).
- Cover-finding / navmesh authoring (relies on the map's existing navmesh).
- Networked HUD or scoreboards.

## 7. Open questions / assumptions

- **A1:** Detection radius baseline = 1655 u (the A↔B distance); tiers scale up from there. ✔ assumed.
- **A2:** "Over 50% of the visible field" = accuracy is flat within 50% of *fire range*, then degrades. ✔ assumed.
- **A3:** "Allies" = any droid from this addon, regardless of tier. ✔ assumed.
- **A4:** Squad threshold `SquadMin = 2` allies (i.e., 3+ droids total). ✔ assumed; tweakable in config.
