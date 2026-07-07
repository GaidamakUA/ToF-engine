What you implemented

- Added `CombatCommands` as a new board command service and wired it into `BoardModel`.
- Added `BoardModel.attack_unit(source_tile, target_tile) -> CommandResult` as the public combat facade.
- Moved combat gameplay mutation out of `Board.battle()` into `CombatCommands`: attacker move/attack spend, AP spend, defender damage, retaliation eligibility and retaliation move spend, `UnitAttackedEvent` emission, and destroyed-unit cleanup through `UnitLifecycleCommands.destroy_unit_on_tile()`.
- Kept `Board` on presentation duty by converting `battle()` into a command call plus `_present_attack_result(...)`, driven from command-result metadata instead of direct gameplay mutation.
- Extended `UnitAttackedEvent`/`Events.emit_unit_attacked(...)` with tile context used by presentation and downstream consumers.
- Added focused combat command tests and a headless attack-action test covering attack execution without a live `Board` scene.

Tests run and results

- `git diff --check`: PASS
- `./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_combat_commands.gd`: BLOCKED, local Godot 4 executable unavailable (`Set GODOT_BIN to a Godot 4.7 executable or add godot/godot4 to PATH.`)
- Full focused/headless and full GUT validation: NOT RUN for the same environment reason

TDD evidence, including RED/GREEN if you added failing tests first

- RED: Added `tests/unit/board/commands/test_combat_commands.gd` and the new headless attack test before implementing command code.
- RED verification attempt: blocked by missing local Godot binary, so I could not capture the expected initial failing run.
- GREEN: Implemented the production changes after the tests were in place.
- GREEN verification: blocked by the same missing Godot binary, so runtime confirmation is still required.

Files changed

- `scenes/board/logic/commands/combat_commands.gd`
- `scenes/board/board_model.gd`
- `scenes/board/board.gd`
- `scenes/board/logic/events.gd`
- `scenes/board/logic/events/unit_attacked.gd`
- `tests/unit/board/commands/test_combat_commands.gd`
- `tests/unit/board/test_headless_validation.gd`
- `tests/unit/board/test_board.gd`
- `tests/unit/board/test_board_model.gd`

Self-review findings

- Combat state mutation is now isolated from `Board`, and AP is spent only once inside combat commands.
- Destroyed-unit events flow through `UnitLifecycleCommands`, so destroyed-event construction is not duplicated.
- Presentation now depends on attack-step metadata because lethal combat clears the tile before `Board` animates destruction.
- The patch is narrowly scoped to combat command routing, event shape, and direct tests.

Concerns/follow-ups

- Runtime verification is still outstanding because there is no usable local Godot 4.7 binary in this environment.
- The new script and test were added without generated `.uid` companions because Godot could not be run locally to produce them.
- If project conventions require `.uid` files for every new script, opening/saving the project in Godot should generate them before merge.

## Review Fix

Changes

- Restored legacy combat event ordering in `CombatCommands`: AP change still lands first, but when retaliation occurs and both units survive, the retaliation `UnitAttackedEvent` is emitted before the original attacker's `UnitAttackedEvent`.
- Kept combat mutation inside command services: no AP double-spend, no gameplay move back into `Board`, and destroyed-unit handling still routes through `UnitLifecycleCommands`.
- Renamed `UnitAttackedEvent.unit_tile` to `defender_tile` and updated `Events.emit_unit_attacked(...)` plus focused test coverage to match the task brief.

Tests

- `git diff --check`: PASS
- `GODOT_BIN="$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" ./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_combat_commands.gd`: PASS
- `HOME=/private/tmp "$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" --headless --path "$PWD" --quit`: exit 0 with known shutdown leak/resource warnings only

Concerns

- The focused GUT run still reports an existing orphan in `res://tests/unit/board/ai/test_ai_actions.gd`, and the headless quit still prints the repository's known shutdown leak/resource warnings. Neither was introduced by this patch.

## Review Fix 2

Changes

- Restored legacy attack-event semantics in `CombatCommands`: after retaliation resolves, the original attacker to defender `UnitAttackedEvent` now always emits when the defender survived the initial hit, even if retaliation killed the attacker.
- Kept existing event ordering for the both-survive case: AP change first, retaliation `UnitAttackedEvent` second, original attack `UnitAttackedEvent` third.
- Added a focused combat regression proving lethal retaliation still leaves the original attack event in the command result and observer stream.

Tests

- `git diff --check`: PASS
- `GODOT_BIN="$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" ./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_combat_commands.gd`: PASS
- `HOME=/private/tmp "$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" --headless --path "$PWD" --quit`: exit 0 with known shutdown leak/resource warnings

Concerns

- Focused GUT still reports the pre-existing orphan in `res://tests/unit/board/ai/test_ai_actions.gd`.
- Headless Godot still prints the repository's known shutdown leak/resource warnings on exit.
