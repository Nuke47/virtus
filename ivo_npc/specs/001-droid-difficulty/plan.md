# Plan 001 — Implementation plan for droid difficulty tiers

Implements: `spec.md`

## Architecture

Refactor from one entity into a **base engine + 3 config-only variants**, using GMod SENT
inheritance (`ENT.Base`).

```
lua/entities/
  npc_droid_base/      -- NOT spawnable. All behavior lives here.
    init.lua           -- server: behavior + GetDefaultConfig()
    cl_init.lua        -- client: Draw()
    shared.lua         -- ENT.Base="base_nextbot", ENT.Type, shared flags
  npc_droid_b1/        -- thin: ENT.Base="npc_droid_base" + DroidConfig overrides + spawn entry
  npc_droid_b2/
  npc_droid_bx/
```

- Base sets `ENT.IsDroidNPC = true` so allies can be found via `ents.FindInSphere`.
- Each variant's `shared.lua` sets `ENT.DroidConfig = { ...overrides }` and registers itself in the
  `NPC` spawn list with `Class == folder name`.
- `Initialize()` (inherited) merges `GetDefaultConfig()` with `self.DroidConfig` into `self.Cfg`.

## Config merge

`self.Cfg = table.Merge(self:GetDefaultConfig(), self.DroidConfig or {})`. Variants only specify
fields that differ. Defaults double as the B1-ish baseline + tunables (`AccurateFraction`,
`SquadRadius`, `SquadMin`, `RushSpeed`, `RetargetInterval`, `WeaponModel`, `WeaponClass`).

## Key functions (on base, server)

- `GetDefaultConfig()` → table of defaults.
- `Initialize()` → model/health/solid + `SetupConfig()` + `EquipWeapon()`.
- `EquipWeapon()` → port of `EquiparArmaPersonalizada` (attachment → bone → fallback), prop cleanup in `OnRemove`.
- `GetTFAStats(class)` → port of `ObtenerDatosTFA`.
- `CanSee(target)` → eye-to-eye `util.TraceLine`, returns bool.
- `FindVisibleTargets()` → players, alive, !notarget, within `DetectRadius`, `CanSee` → list.
- `PickRandomTarget()` → random element of `FindVisibleTargets()`.
- `HasValidEnemy()` → enemy valid/alive/!notarget/within `DetectRadius`.
- `CountNearbyAllies()` → `ents.FindInSphere(SquadRadius)` filtered by `IsDroidNPC`.
- `DecideEngagementStyle()` → `"rush"` if allies≥SquadMin else random `"rungun"`/`"hold"`.
- `ComputeSpread(dist)` → flat `BaseSpread` ≤ AccurateFraction, lerp to `MaxSpread` beyond.
- `RunBehaviour()` → acquire/retarget loop + patrol.
- `ChaseAndFire()` → path + style-driven movement + fire gating (range + LOS) + animation/speed.
- `RangedAttack()` → port of `AtacarADistancia`, now using `ComputeSpread`, `DamageMult`, `FireRateMult`, projectile spread jitter.
- `BodyUpdate()` / `OnRemove()` → ported.

## Behavior loop changes vs original

1. Targeting: nearest-visible → **random-visible** (`PickRandomTarget`) + periodic retarget.
2. Detection: hard-coded `3000` scan + `1200` fire → config `DetectRadius` / `FireRange`.
3. Accuracy: fixed `Spread(0.04)` → `ComputeSpread(distance)` per tier.
4. Movement: fixed walk/run speeds → config; add `rush` / `hold` / `rungun` styles.
5. Squads: new ally count + style selection, recomputed ~1×/sec inside `ChaseAndFire`.

## Risks / mitigations

- **No navmesh on map** → pathing fails; mitigate by falling back to `loco:SetDesiredSpeed` +
  `FaceTowards` + direct `MoveToPos` toward enemy when `Path:IsValid()` is false (still shoots on LOS).
- **Projectile weapons ignore bullet spread** → apply angular jitter to projectile direction.
- **Variant config not merging** → merge explicitly in `Initialize` (don't rely on nested table inheritance).
- **Class/folder mismatch** (original bug) → folder name == registered class.

## Rollback

Original entity preserved at `_backup/droid_npc/` (outside `lua/`, not loaded by GMod).
