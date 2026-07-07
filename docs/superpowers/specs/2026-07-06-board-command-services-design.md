# Board Command Services Design

## Goal

Move core gameplay command execution out of `Board` and into model-owned command services, while keeping `Board` as the scene root and view composition object.

This spec follows the completed Board MVC migration in `docs/superpowers/specs/2026-07-05-board-mvc-design.md`. That work introduced `BoardModel`, `BoardController`, `BoardView`, AI model commands, and a headless validation path, but `Board` still acts as the gameplay orchestration surface. This milestone removes that remaining command dependency.

## Non-Goals

This milestone does not replace scene-backed `BaseUnit` and `BaseBuilding` objects with pure model state. Those objects still sit on the current runtime boundary and should be treated as transitional. A later milestone should move unit and building runtime data fully into model-owned state and turn scene nodes into view instances.

This milestone also does not redesign the scene adapter, camera, markers, radial menu, animation, audio, projectile effects, or save format except where small changes are required to preserve command behavior.

## Architecture Boundary

`BoardModel` becomes the only public gameplay command surface. Callers execute game actions through methods such as:

```gdscript
model.move_unit(source_tile, destination_tile)
model.attack_unit(source_tile, target_tile)
model.capture_building(source_tile, target_tile)
model.use_ability(origin_tile, ability, target_tile)
model.end_turn()
```

`BoardModel` owns the state, map access, events, and command services needed to execute those operations. It remains a facade for callers, but it must not delegate core command execution back to `Board`.

Command services are owned by `BoardModel` and split by gameplay responsibility:

- `MovementCommands`
- `CombatCommands`
- `CaptureCommands`
- `AbilityCommands`
- `TurnCommands`
- `UnitLifecycleCommands` for spawn, destruction, replenish, and related unit lifecycle work

Each service should depend on model-owned collaborators such as `State`, map/tile access, `Events`, ability state, scripting hooks that affect gameplay, and collateral logic. Services must not depend on `Board`, `BoardController`, `BoardView`, selection state, markers, camera, radial menus, animation, audio, or other presentation concerns.

## Board Role

`Board` remains as the scene root and view composition object. It may wire the model, controller, view, map scene, UI panels, camera, and scene effects together. It may react to gameplay events and update presentation.

`Board` must stop being a gameplay command API. There should be no compatibility wrappers such as `board.move_unit(...)`, `board.battle(...)`, `board.capture(...)`, or `board.execute_ability_from_tile(...)` that continue the old command surface. Existing callers must be moved to `BoardModel` or its command-facing API.

If a method remains on `Board`, it should be view, scene, input, lifecycle, or composition behavior. Rule execution belongs in `BoardModel` and its command services.

## Events

Command services communicate outward by emitting gameplay events only. They must not call `Board` directly and must not use temporary effects adapters.

Events should carry enough gameplay context for the scene adapter and view layer to animate or present changes after command execution. Required event coverage includes:

- unit moved
- unit attacked
- unit destroyed
- unit spawned
- building captured
- ability used
- AP changed, if the existing event set does not already expose enough AP state
- turn ended and turn started
- collateral damage applied

`Board` and other scene/view objects can observe those events and perform visual work. They should not be required for the command to complete.

## Command Pacing

Command services do not create timers, await animations, wait on unit movement signals, or depend on scene-tree delays. They execute gameplay state changes and emit events.

AI and scene runtime code may still pause between commands, but that pacing must be outside command execution. The pacing object should observe command results or gameplay events rather than owning rules.

The intended shape is:

```gdscript
var result := model.move_unit(source_tile, destination_tile)
await action_pacer.wait_after(result)
```

The headless/test pacer should be no-op or deterministic. The scene runtime pacer may use timers or event completion to preserve current feel, but AI actions must not depend on `Board`, camera state, unit animation signals, selection state, or view APIs to execute gameplay commands.

## Transitional Runtime Boundary

`BaseUnit` and `BaseBuilding` are scene-backed and belong to the view/adapter side in the long-term architecture. This milestone does not remove them yet.

During this milestone, command services may still touch existing map fragments and runtime objects where needed to preserve behavior. New code should avoid increasing scene-node coupling. When a command must read or mutate a `BaseUnit` or `BaseBuilding`, keep that access narrow and local to the service responsible for the command.

The desired direction is:

```text
BoardModel -> CommandServices -> current map/unit/building runtime boundary
```

not:

```text
BoardModel -> Board -> scene/UI command methods
```

## Core Commands In Scope

The milestone covers all core gameplay commands:

- movement
- attack
- capture
- ability use
- AP spend and gain tied to commands
- unit destruction
- unit spawn and replenish behavior
- collateral damage
- turn end and turn start command effects
- gameplay event emission for the above

AI, controller, tests, replay-like flows, and any other gameplay caller should use the same `BoardModel` command API.

## Success Criteria

The milestone is complete only when:

- `BoardModel` can execute movement, attack, capture, ability use, turn changes, AP changes, unit spawn/destruction, and collateral damage without a `Board` instance.
- AI actions call `BoardModel` for gameplay commands and never call `Board`, `BoardController`, selection APIs, or view APIs for core command execution.
- AI pacing between commands is handled by a no-op/deterministic headless pacer or a scene-runtime pacer outside command services.
- The headless validation path no longer needs a fake board host for core commands.
- `Board` no longer exposes core gameplay command methods as its public gameplay surface.
- Scene/view behavior still works by reacting to events and querying model state or snapshots.
- Existing gameplay behavior remains unchanged from the player perspective.

## Testing Requirements

Add focused GUT coverage for each command service:

- movement legality, AP spend, unit relocation, and move events
- attack legality, damage, retaliation, unit destruction, AP spend, and attack/destruction events
- capture legality, building ownership/team updates, AP spend, and capture events
- ability dispatch, cooldown/disabled behavior, AP or state effects, and ability events
- turn switching, AP/resource gain, unit action replenish, AI turn detection, and turn events
- spawn/destruction/collateral lifecycle effects where those rules move out of `Board`

Add headless integration tests that load a fixture or bundled map, execute representative commands through `BoardModel`, and assert final state and emitted events.

Add regression tests proving AI actions and model commands do not call `Board` or controller selection APIs for core command execution.

Add pacing tests proving command services do not wait on timers, animations, scene trees, unit movement signals, or view APIs. Headless command tests should run with a no-op or deterministic pacer.

The implementation plan should include search checks for forbidden dependencies in command service files, including references to `Board`, markers, camera, radial menus, animation, audio, and selection state.

Before each development branch is considered complete, run:

```sh
git diff --check
PERSONAL_PATH_PATTERN='/'"Users/Personal"'|Steam/'"steamapps"'|Godot.'"app"'|Contents/MacOS/'"Godot"
rg -n "$PERSONAL_PATH_PATTERN" .
: "${GODOT_BIN:=godot}"
HOME=/private/tmp "$GODOT_BIN" --headless --path "$PWD" --quit
```

For command service branches, also run the GUT suite.
