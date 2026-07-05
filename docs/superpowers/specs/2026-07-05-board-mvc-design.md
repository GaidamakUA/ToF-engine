# Board MVC Design

## Goal

Separate board gameplay from the current interface so Tanks of Freedom II can run a match without the existing 3D/UI view, while preserving current gameplay behavior. The first migration should introduce clear `BoardModel`, `BoardController`, and `BoardView` responsibilities without attempting a full rewrite of all scene-backed game objects.

The design is pragmatic MVC:

- `BoardModel` owns game truth, rules, legal operations, and gameplay events.
- `BoardController` owns interaction state and translates client intent into model calls.
- `BoardView` owns presentation, raw input capture, camera, audio, UI, markers, and animation.

## Current Context

`scenes/board/board.gd` currently combines all three roles:

- It owns game state objects such as `State`, `Events`, `Scripting`, `Ai`, `Abilities`, and `Collateral`.
- It performs rule operations such as movement, battle, capture, ability execution, AP changes, turn switching, and save restoration.
- It stores interaction state such as `selected_tile`, `active_ability`, and `active_ability_origin_tile`.
- It coordinates view concerns such as radial menus, movement markers, path markers, ability markers, explosions, projectiles, sound, camera movement, panels, and turn cards.

AI actions currently call through UI-like selection flows such as `board.select_tile(...)`. This makes AI depend on interaction behavior and blocks a clean headless command API.

## Responsibilities

### BoardModel

`BoardModel` is the headless game/session model. It owns the canonical board state and exposes explicit game operations.

It owns:

- `State`: active player, turn number, AP, teams, alive players, heroes.
- `MapModel` and tile contents.
- Runtime unit and building state.
- Rule operations: move, attack, capture, spawn, use ability, end turn, destroy unit, apply collateral damage, gain AP, replenish unit actions.
- Legal-action queries: movement costs, reachable tiles, interaction targets, ability target tiles, affordability, current player permissions.
- Gameplay event emission.
- Save/load state for gameplay data.
- Scripting/objective state when it affects gameplay.

It does not own:

- Selected tile.
- Active ability targeting mode.
- Mouse, keyboard, controller, or network input interpretation.
- Radial menu state.
- Camera state, panel state, marker nodes, animations, sounds, or visual effects.

Representative API shape:

```gdscript
var model := BoardModel.new()

model.setup_from_match(match_setup)
model.restore_from_save(save_data)

model.get_current_player()
model.get_current_ap()
model.get_tile(position)
model.get_snapshot()

model.get_legal_moves(from)
model.get_legal_interactions(from)
model.get_legal_ability_targets(source, ability)

model.can_move_unit(from, to)
model.move_unit(from, to)
model.can_attack_unit(from, target)
model.attack_unit(from, target)
model.can_capture_building(from, target)
model.capture_building(from, target)
model.can_use_ability(source, ability, target)
model.use_ability(source, ability, target)
model.end_turn()
```

The model API should use explicit positions, units, buildings, and abilities. It should not require a selected tile or active targeting state to play the game.

### BoardController

`BoardController` is an intent translator. It owns state that only exists because a player or view is interacting with the board.

It owns:

- `selected_tile`.
- `active_ability`.
- `active_ability_origin_tile`.
- Cancel/confirm interaction flow.
- Click/tap/accept interpretation.
- "Press same tile again opens abilities" behavior.
- End-turn confirmation and hold-to-end-turn behavior.
- UI-driven undo intent, if undo remains interaction-scoped.

It does not:

- Mutate units or buildings directly.
- Spend AP directly.
- Calculate combat damage directly.
- Decide whether a move, attack, capture, or ability is legal except by querying `BoardModel`.
- Play animations or sounds.

Representative API shape:

```gdscript
var controller := BoardController.new(model)

controller.press_tile(position)
controller.cancel()
controller.open_context_for_position(position)
controller.start_ability_targeting(source_position, ability)
controller.confirm_end_turn()
controller.abort_end_turn_confirmation()
controller.clear_selection()
```

`press_tile(position)` may choose between `model.move_unit(...)`, `model.attack_unit(...)`, `model.capture_building(...)`, `model.use_ability(...)`, `model.end_turn()`, or selection changes. The controller chooses which model operation matches the current interaction state, but the model validates and executes the operation.

Headless clients, tests, replay systems, and long-term AI should be able to bypass `BoardController` and call `BoardModel` directly.

### BoardView

`BoardView` is the presentation layer for the current scene-backed board. It owns visuals and effects.

It owns:

- Current 3D board scene nodes.
- UI panels, radial menu, AP display, objectives, summaries, saves/settings panels.
- Movement, path, interaction, selected-tile, and ability markers.
- Hover highlight and tile preview rendering.
- Camera movement and camera pause state.
- Audio.
- Animations, projectiles, explosions, smoke, heal/bless effects.
- Raw input capture and forwarding to `BoardController`.

It does not:

- Execute game rules directly.
- Store canonical game state.
- Decide legal actions except by asking `BoardModel` or `BoardController`.

The current `Board` scene can initially act as the composition root and concrete `BoardView` host while its responsibilities are extracted.

## Data Flow

Human play:

```text
BoardView -> BoardController -> BoardModel -> gameplay events -> BoardView
```

Headless play:

```text
AI/tests/replay -> BoardModel -> gameplay events
```

Optional human-like automation:

```text
AI/replay -> BoardController -> BoardModel
```

The preferred long-term AI path is direct `BoardModel` commands. AI should not need to simulate selection clicks.

## Events

Existing event classes under `scenes/board/logic/events` are a useful starting point. Events should become the bridge from model changes to views and scripts.

Needed event categories include:

- Turn started and turn ended.
- AP changed.
- Unit moved.
- Unit attacked.
- Unit destroyed.
- Unit spawned.
- Building captured.
- Ability used.
- Game ended.
- Tile damaged or collateral damage applied.

Events should carry enough game data for views to animate results without querying stale state, but they should not require view nodes to exist.

## Migration Plan

### Phase 0: Add GUT Test Harness

Add GUT as a separate tooling step before the MVC extraction begins. This keeps test setup risk out of the architecture refactor and gives the later phases a stable place to add focused regression tests.

Initial goal:

- Install/configure GUT for headless execution in this Godot project.
- Add a project-level test command or documented command that runs GUT headlessly.
- Add one or two smoke tests that prove the harness works.
- Start with low-dependency tests for existing logic such as `State` player switching, AP clamping/spending, alive-player skipping, and team lookup.

Do not try to heavily test the current full `Board` scene. It mixes rules with UI, camera, animations, timers, and scene effects, so broad scene tests would be brittle before the extraction.

### Phase 1: Introduce BoardModel Around Existing State

Create `BoardModel` as a wrapper around the existing `State`, `MapModel`, `Events`, `Abilities`, `Scripting`, and core rule methods. Do not immediately remove every dependency on scene-backed unit/building objects.

Initial goal:

- The existing board still plays the same.
- Core game operations are reachable through `BoardModel`.
- Existing `Board` methods delegate to `BoardModel` where practical.

### Phase 2: Extract BoardController Interaction State

Move selection and targeting fields out of `Board`:

- `selected_tile`
- `active_ability`
- `active_ability_origin_tile`

Move tile press, cancel, and targeting interpretation into `BoardController`. `BoardController` calls explicit `BoardModel` operations.

Initial goal:

- UI input no longer directly performs movement, combat, capture, or ability execution.
- Controller state can be reset independently of model state.
- Headless model commands do not depend on selection.

### Phase 3: Treat Current Board Scene as BoardView

Move view-only responsibilities behind `BoardView` methods or a concrete scene-backed adapter:

- marker drawing/reset
- AP display updates
- radial menu population
- unit stats panels
- camera moves
- explosions/projectiles/smoke
- audio cues
- turn start/end cards

Initial goal:

- Gameplay operations emit events.
- View reacts to model/controller state and events.
- A null view can ignore visual effects.

### Phase 4: Move AI to BoardModel Commands

Update AI actions so they no longer perform actions by calling `board.select_tile(...)`.

Initial goal:

- AI gathers actions using model queries.
- AI executes actions using explicit model commands.
- Delays and camera movement remain optional view concerns.

### Phase 5: Add Headless Validation Path

Add GUT tests or a small headless runner path that can:

- Load a bundled map.
- Create a `BoardModel`.
- Run setup and one or more turns.
- Execute representative commands without a UI scene.
- Assert gameplay events and final state.

This should complement the existing Godot headless load validation.

## Compatibility Rules

- Gameplay must remain the same after each phase.
- The current board scene should continue to work during migration.
- Avoid broad rewrites of units, buildings, abilities, and map templates in the same change.
- Static data/resource migration remains separate from this architecture work.
- Damaged/destroyed city/decor templates stay as scene templates unless explicitly migrated later.
- Scene-backed units/buildings may remain in `BoardModel` during early phases. The important boundary is that model operations do not require the current UI/view.

## Testing and Validation

Use GUT for unit and small integration coverage around the extracted model/rule code. Keep the existing Godot headless project load as a smoke check for resource and parser health.

For non-trivial implementation changes:

- Run `git diff --check`.
- Run the Godot headless load command from `AGENTS.md`.
- Run the GUT headless test command once configured.
- Add targeted GUT tests for model operations as they become scene-independent.
- Exercise at least movement, attack, capture, ability use, end turn, save/restore, and AI action execution through the new API.

The first useful GUT target is `State`, because it is already scene-independent and central to turns/AP/player flow. The first useful architecture target is parity: perform an action through the old board flow and through the new model/controller path, then compare state and emitted events.

Recommended early GUT coverage:

- `State` AP add/use/clamp behavior.
- `State` player switching, including skipping dead players.
- `State` team and side lookup.
- `BoardModel` movement once `BoardModel` exists.
- `BoardModel` attack/capture/ability/end-turn behavior as those operations move behind the model API.
- Legal-action query behavior for movement, interaction, and ability targets.

## Implementation Defaults

- Add `BoardModel` in `scenes/board/board_model.gd`.
- Add `BoardController` in `scenes/board/board_controller.gd`.
- Put tests under `tests/` unless the chosen GUT setup strongly prefers another standard project-local path.
- Keep `scenes/board/board.gd` as the scene host during early phases. It can act as the first concrete `BoardView` before any rename or scene split.
- Start `BoardModel` as `RefCounted` unless a concrete Godot node lifecycle need appears during implementation.
- Allow `BoardModel` to hold references to existing scene-backed map/unit/building objects during phase 1, but do not expose UI nodes or require selection state in its public API.
- Keep existing marker classes as `BoardView` renderers at first. Extract pure query helpers only when needed to make model legal-action queries independent.
- Treat undo as controller-level interaction state unless headless undo becomes an explicit gameplay requirement.
