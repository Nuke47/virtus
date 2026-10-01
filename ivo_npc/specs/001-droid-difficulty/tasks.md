# Tasks 001 — Droid difficulty tiers

Implements: `plan.md`. Check off as completed.

## T0 — Safety
- [x] Back up original `droid_npc/` to `_backup/droid_npc/` (outside `lua/`).

## T1 — Base engine (`npc_droid_base`)
- [x] `shared.lua`: `ENT.Base="base_nextbot"`, `Type`, `IsDroidNPC`, `Spawnable=false`.
- [x] `cl_init.lua`: `Draw()`.
- [x] `init.lua`: `GetDefaultConfig`, `SetupConfig`, `Initialize`, `EquipWeapon`, `GetTFAStats`.
- [x] Targeting: `CanSee`, `FindVisibleTargets`, `PickRandomTarget`, `HasValidEnemy`.
- [x] Squad: `CountNearbyAllies`, `DecideEngagementStyle`.
- [x] Accuracy: `ComputeSpread`.
- [x] Loops: `RunBehaviour`, `ChaseAndFire`, `RangedAttack`, patrol.
- [x] `BodyUpdate`, `OnRemove`.

## T2 — Variants
- [x] `npc_droid_b1` (easy) config + spawn entry.
- [x] `npc_droid_b2` (medium) config + spawn entry.
- [x] `npc_droid_bx` (hard) config + spawn entry.

## T3 — Registration cleanup
- [x] Folder name == class for every variant.
- [x] Remove broken `npc_droide` spawn entry / old `droid_npc` folder from `lua/`.

## T4 — Verification (see /TESTING.md)
- [ ] `glualint` passes (or manual syntax check) — run locally.
- [ ] All 3 spawn with no console errors — run locally.
- [ ] UC-1 random targeting observed — run locally.
- [ ] UC-2 radius detection via setpos points — run locally.
- [ ] UC-3 accuracy degrades with distance, tighter on harder tiers — run locally.
- [ ] UC-5 grouped droids rush — run locally.
- [ ] UC-6 lone droids ~50/50 hold vs run-and-gun — run locally.
