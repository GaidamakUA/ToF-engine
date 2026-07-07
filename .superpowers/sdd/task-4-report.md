# Task 4 Implementer Report (Recovered After Context Compaction)

Status: DONE_WITH_CONCERNS

Commit:
- `6285b0cc Move unit lifecycle commands into BoardModel`

What the implementer reported:
- Added `UnitLifecycleCommands` for destruction and turn-start unit replenish.
- Added `CollateralDamageAppliedEvent` and `Events.emit_collateral_damage_applied`.
- Wired lifecycle commands into `BoardModel`.
- Migrated Board combat, cheat kill, and start-turn replenish paths to `BoardModel`.
- Kept public `Board.destroy_unit_on_tile` only as a compatibility wrapper for remaining ability/scripting callers, preserving old no-event semantics to avoid duplicate destroyed events.

Tests the implementer reported:
- Focused lifecycle GUT passed.
- Full GUT passed: 62/62.
- `git diff --check` passed.
- Godot headless load exited 0.

Files the implementer reported changed:
- `scenes/board/logic/commands/unit_lifecycle_commands.gd`
- `scenes/board/logic/events/collateral_damage_applied.gd`
- `scenes/board/logic/events.gd`
- `scenes/board/logic/collateral.gd`
- `scenes/board/board_model.gd`
- `scenes/board/board.gd`
- `tests/unit/board/commands/test_unit_lifecycle_commands.gd`
- `.uid` companions.

Concern reported:
- Public `Board.destroy_unit_on_tile` remains for compatibility. Remaining callers were reported as:
  - `scenes/abilities/hero/active/precision_strike_executor.gd:42`
  - `scenes/board/logic/scripting/outcomes/die.gd:8`
  - `scenes/abilities/unit/heavy_weapon.gd:24`
  - `scenes/abilities/unit/long_range_shell.gd:24`
  - `scenes/abilities/unit/missile.gd:28`

## Review Fix

### What changed

- Routed `Board.destroy_unit_on_tile` through `BoardModel.destroy_unit_on_tile` so the model/service owns both mutation and `UnitDestroyedEvent` emission while keeping `_present_unit_destruction` intact.
- Removed the `emit_event` bypass from `UnitLifecycleCommands.destroy_unit_on_tile`; destruction now always emits exactly one `UnitDestroyedEvent`.
- Updated `heavy_weapon`, `long_range_shell`, and `missile` to stop manually emitting `UnitDestroyedEvent` and instead call the board destruction wrapper with the attacking unit as the source.
- Updated `precision_strike_executor` to use the same destruction wrapper with its source unit, so its destroyed events also come from the lifecycle command path.
- Added focused coverage in `tests/unit/board/test_board.gd` for wrapper routing/presentation preservation and to guard against manual `emit_unit_destroyed` calls returning in the direct-damage abilities.

### Tests run and results

- `GODOT_BIN='/Users/Personal/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot' ./tools/run_gut.sh -gtest=res://tests/unit/board/test_board.gd`
  - Passed. GUT ran the full unit suite: 64/64 tests passed.
- `GODOT_BIN='/Users/Personal/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot' ./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_unit_lifecycle_commands.gd`
  - Passed. GUT again ran the full unit suite: 64/64 tests passed.
- `git diff --check`
  - Passed.
- `rg -n "emit_unit_destroyed\\(" scenes/abilities/unit scenes/abilities/hero/active scenes/board/logic/scripting/outcomes`
  - No matches.
- `rg -n "unit_lifecycle_commands\\.destroy_unit_on_tile\\(" scenes tests`
  - Only remaining match is `scenes/board/board_model.gd`, which is the intended ownership boundary.
- `HOME=/private/tmp '/Users/Personal/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot' --headless --path "$PWD" --quit`
  - Exited 0.

### Files changed

- `scenes/board/board.gd`
- `scenes/board/logic/commands/unit_lifecycle_commands.gd`
- `scenes/abilities/hero/active/precision_strike_executor.gd`
- `scenes/abilities/unit/heavy_weapon.gd`
- `scenes/abilities/unit/long_range_shell.gd`
- `scenes/abilities/unit/missile.gd`
- `tests/unit/board/test_board.gd`

### Any concerns

- GUT and the headless Godot load still report pre-existing orphan/leak warnings on exit, but both commands exited successfully and no new parser/runtime failures were introduced by this fix.
