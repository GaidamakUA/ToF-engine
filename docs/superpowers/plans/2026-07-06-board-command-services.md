# Board Command Services Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move all core gameplay command execution from `Board` into model-owned command services so `BoardModel` can execute commands without a `Board` instance.

**Architecture:** `BoardModel` remains the public gameplay facade and owns focused services for movement, combat, capture, ability, turn, and unit lifecycle commands. Services emit gameplay events and return command results; view pacing and visual effects stay outside command execution.

**Tech Stack:** Godot 4, GDScript, GUT, existing `MapTile`, `MapModel`, `State`, `Events`, `Ability`, `BaseUnit`, and `BaseBuilding` runtime objects.

---

## Scope And Sequencing

Implement this in small branches. Each task below should leave the game runnable and the GUT suite passing. Do not begin implementation from a dirty tree.

Start implementation with:

```sh
git switch master
git pull --ff-only
git switch -c codex/board-command-services-task-1
```

Use the local Godot validation command from `AGENTS.md`:

```sh
: "${GODOT_BIN:=godot}"
HOME=/private/tmp "$GODOT_BIN" --headless --path "$PWD" --quit
```

For GUT:

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh
```

## File Structure

Create a new command package under `scenes/board/logic/commands/`:

- `command_result.gd`: small value object returned by command services for pacing and tests.
- `action_pacer.gd`: abstract pacing interface for AI/runtime command pauses.
- `no_op_action_pacer.gd`: deterministic headless pacer.
- `board_command_context.gd`: model-owned dependency object passed to command services.
- `movement_commands.gd`: movement command execution and movement legality helpers that do not touch markers or animation.
- `unit_lifecycle_commands.gd`: unit destruction, spawn bookkeeping, replenish, hero state cleanup, and lifecycle events.
- `combat_commands.gd`: attack, retaliation, damage, and combat event emission.
- `capture_commands.gd`: building ownership changes, crew retaliation rule, AP spend, capture event emission.
- `turn_commands.gd`: end/start turn state changes, AP gain, unit replenish, turn event emission.
- `ability_commands.gd`: model-side ability dispatch, cooldown/AP spend, and ability event emission.

Modify existing files:

- `scenes/board/board_model.gd`: own map access, command services, public command facade, and pacer.
- `scenes/board/board.gd`: remove gameplay command methods after callers move to model; keep scene, UI, input, event presentation, and composition methods.
- `scenes/board/logic/ai/actions/*.gd`: remove direct animation/timer waits and use a pacer outside command execution.
- `scenes/board/logic/ai/ai.gd`: own or receive an `ActionPacer`; AI still selects actions but commands execute through `BoardModel`.
- `scenes/abilities/abilities.gd`: remove typed `Board` constructor dependency and use `State` for passive hero lookups.
- `scenes/abilities/ability.gd`, `scenes/abilities/ability_state.gd`, and concrete ability scripts: migrate gameplay effects from `Board` to `BoardModel`/command services or emitted events.
- `tests/unit/board/headless_board_scenario.gd`: remove fake board host once `BoardModel` owns core commands directly.
- `tests/unit/board/test_headless_validation.gd`: expand the headless fixture tests to cover every command without `Board`.

Create or extend tests:

- `tests/unit/board/commands/test_command_scaffolding.gd`
- `tests/unit/board/commands/test_movement_commands.gd`
- `tests/unit/board/commands/test_turn_commands.gd`
- `tests/unit/board/commands/test_unit_lifecycle_commands.gd`
- `tests/unit/board/commands/test_combat_commands.gd`
- `tests/unit/board/commands/test_capture_commands.gd`
- `tests/unit/board/commands/test_ability_commands.gd`
- `tests/unit/board/ai/test_ai_action_pacing.gd`
- `tests/unit/board/test_board_command_boundary.gd`

---

### Task 1: Command Infrastructure And Model Ownership

**Files:**
- Create: `scenes/board/logic/commands/command_result.gd`
- Create: `scenes/board/logic/commands/action_pacer.gd`
- Create: `scenes/board/logic/commands/no_op_action_pacer.gd`
- Create: `scenes/board/logic/commands/board_command_context.gd`
- Modify: `scenes/board/board_model.gd`
- Test: `tests/unit/board/commands/test_command_scaffolding.gd`
- Modify: `tests/unit/board/test_board_model.gd`

- [ ] **Step 1: Write the failing scaffolding test**

Create `tests/unit/board/commands/test_command_scaffolding.gd`:

```gdscript
extends GutTest


func test_command_result_collects_events_and_delay() -> void:
	var result := CommandResult.new("move_unit")
	var event := UnitMovedEvent.new()

	result.add_event(event)
	result.delay = 0.25

	assert_eq(result.command_name, "move_unit")
	assert_eq(result.events, [event])
	assert_eq(result.delay, 0.25)


func test_no_op_pacer_returns_without_tree_or_board() -> void:
	var pacer := NoOpActionPacer.new()
	var result := CommandResult.new("move_unit")

	await pacer.wait_after(result)

	assert_true(true)


func test_board_model_can_own_map_model_without_board() -> void:
	var model := BoardModel.new()
	var map_model := MapModel.new()
	var tile := MapTile.new(1, 2)
	map_model.tiles[tile.position] = tile

	model.set_map_model(map_model)

	assert_same(model.get_tile_at(Vector2i(1, 2)), tile)
	assert_null(model.board)
	assert_not_null(model.command_context)
	assert_same(model.command_context.state, model.state)
	assert_same(model.command_context.map_model, map_model)
	assert_same(model.command_context.events, model.events)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_command_scaffolding.gd
```

Expected: FAIL because `CommandResult`, `NoOpActionPacer`, `BoardCommandContext`, and `BoardModel.set_map_model()` do not exist.

- [ ] **Step 3: Add command result and pacer classes**

Create `scenes/board/logic/commands/command_result.gd`:

```gdscript
class_name CommandResult
extends RefCounted


var command_name: String = ""
var events: Array[BaseEvent] = []
var delay: float = 0.0
var metadata: Dictionary[String, Variant] = {}


func _init(new_command_name: String = "") -> void:
	self.command_name = new_command_name


func add_event(event: BaseEvent) -> void:
	self.events.append(event)
```

Create `scenes/board/logic/commands/action_pacer.gd`:

```gdscript
class_name ActionPacer
extends RefCounted


func wait_after(_result: CommandResult) -> void:
	return
```

Create `scenes/board/logic/commands/no_op_action_pacer.gd`:

```gdscript
class_name NoOpActionPacer
extends ActionPacer


func wait_after(_result: CommandResult) -> void:
	return
```

- [ ] **Step 4: Add command context**

Create `scenes/board/logic/commands/board_command_context.gd`:

```gdscript
class_name BoardCommandContext
extends RefCounted


var state: State
var map_model: MapModel
var events: Events
var scripting: Scripting
var abilities: Abilities
var collateral: Collateral


func _init(
	state_object: State,
	map_model_object: MapModel,
	events_object: Events,
	scripting_object: Scripting,
	abilities_object: Abilities = null,
	collateral_object: Collateral = null
) -> void:
	self.state = state_object
	self.map_model = map_model_object
	self.events = events_object
	self.scripting = scripting_object
	self.abilities = abilities_object
	self.collateral = collateral_object
```

- [ ] **Step 5: Modify BoardModel ownership**

In `scenes/board/board_model.gd`, add properties near existing collaborators:

```gdscript
var map_model: MapModel = null
var command_context: BoardCommandContext = null
var action_pacer: ActionPacer = NoOpActionPacer.new()
```

Add methods:

```gdscript
func set_map_model(new_map_model: MapModel) -> void:
	self.map_model = new_map_model
	self._rebuild_command_context()


func set_action_pacer(new_pacer: ActionPacer) -> void:
	if new_pacer == null:
		self.action_pacer = NoOpActionPacer.new()
	else:
		self.action_pacer = new_pacer


func _rebuild_command_context() -> void:
	self.command_context = BoardCommandContext.new(
		self.state,
		self.map_model,
		self.events,
		self.scripting,
		self.abilities,
		self.collateral
	)
```

Change `attach_board(board_host)` so it sets `map_model` but does not make command execution depend on `board`:

```gdscript
func attach_board(board_host: Variant) -> void:
	self.board = board_host
	if board_host != null and board_host.map != null:
		self.map_model = board_host.map.model
	self.abilities = Abilities.new(self.state)
	self.observers = Observers.new(board_host)
	self.ai = Ai.new(board_host)
	self.collateral = Collateral.new(self)
	self._rebuild_command_context()
```

Replace `get_tile_at` with:

```gdscript
func get_tile_at(tile_position: Vector2i) -> MapTile:
	assert(self.map_model != null)
	return self.map_model.get_tile(tile_position)
```

Keep `board` temporarily for view/query methods until later tasks remove command usage.

- [ ] **Step 6: Refactor Abilities and Collateral constructors enough for context creation**

Modify `scenes/abilities/abilities.gd`:

```gdscript
class_name Abilities
var state: State

func _init(state_object: State) -> void:
	self.state = state_object
```

Replace `_get_passives_for_source` hero lookup:

```gdscript
func _get_passives_for_source(source: Variant) -> Array[PassiveAbility]:
	if source.side == "neutral":
		return []

	var abilities: Array[PassiveAbility] = []
	var heroes: Array[HeroUnit] = self.state.get_heroes_for_side(source.side)

	for hero: HeroUnit in heroes:
		if hero.has_passive_ability():
			abilities.append(hero.passive_ability)

	return abilities
```

Modify `scenes/board/logic/collateral.gd` constructor shape:

```gdscript
var model: BoardModel

func _init(model_object: BoardModel) -> void:
	self.model = model_object
```

Do not migrate collateral internals yet; Task 5 handles that.

- [ ] **Step 7: Update BoardModel tests**

Modify `tests/unit/board/test_board_model.gd`:

```gdscript
func test_new_model_owns_headless_gameplay_collaborators() -> void:
	var model := BoardModel.new()

	assert_not_null(model.state)
	assert_not_null(model.events)
	assert_not_null(model.scripting)
	assert_not_null(model.radial_abilities)
	assert_not_null(model.action_pacer)
	assert_null(model.map_model)
	assert_null(model.abilities)
	assert_null(model.observers)
	assert_null(model.ai)
	assert_null(model.collateral)


func test_attach_board_creates_scene_dependent_collaborators_but_map_is_model_owned() -> void:
	var board := Board.new()
	var map_scene := Node.new()
	var map_model := MapModel.new()
	map_scene.set("model", map_model)
	board.set("map", map_scene)
	board.events = BoardModel.new().events

	var model := BoardModel.new()
	model.attach_board(board)

	assert_same(model.board, board)
	assert_same(model.map_model, map_model)
	assert_same(model.abilities.state, model.state)
	assert_not_null(model.observers)
	assert_same(model.ai.board, board)
	assert_not_null(model.collateral)

	map_scene.free()
	board.free()
```

If `board.map` cannot be set in this exact way because of typed/onready fields, replace the second test with a real board scene fixture or a typed fake that matches the project pattern. Keep the assertion intent identical.

- [ ] **Step 8: Run tests**

Run:

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_command_scaffolding.gd
./tools/run_gut.sh -gtest=res://tests/unit/board/test_board_model.gd
```

Expected: PASS.

- [ ] **Step 9: Commit Task 1**

```sh
git add scenes/board/logic/commands scenes/board/board_model.gd scenes/abilities/abilities.gd scenes/board/logic/collateral.gd tests/unit/board/commands/test_command_scaffolding.gd tests/unit/board/test_board_model.gd
git commit -m "Add board command service scaffolding"
```

---

### Task 2: MovementCommands Without Board

**Files:**
- Create: `scenes/board/logic/commands/movement_commands.gd`
- Modify: `scenes/board/board_model.gd`
- Modify: `scenes/board/board.gd`
- Modify: `tests/unit/board/headless_board_scenario.gd`
- Test: `tests/unit/board/commands/test_movement_commands.gd`
- Modify: `tests/unit/board/test_headless_validation.gd`

- [ ] **Step 1: Write failing movement service tests**

Create `tests/unit/board/commands/test_movement_commands.gd`:

```gdscript
extends GutTest


func _make_context() -> BoardCommandContext:
	var state := State.new()
	state.add_player(State.PLAYER_HUMAN, "blue", true, 0)
	state.add_player_ap(0, 4)
	var map_model := MapModel.new()
	var events := Events.new()
	return BoardCommandContext.new(state, map_model, events, Scripting.new(), Abilities.new(state))


func test_move_unit_along_path_relocates_unit_spends_ap_and_emits_event() -> void:
	var context := _make_context()
	var source := MapTile.new(0, 0)
	var destination := MapTile.new(1, 0)
	var unit := BaseUnit.new()
	unit.side = "blue"
	unit.team = 0
	unit.move = 4
	unit.max_move = 4
	source.unit.set_tile(unit)

	var commands := MovementCommands.new(context)
	var result := commands.move_unit_along_path(source, destination, 2, ["0_0", "1_0"])

	assert_false(source.unit.is_present())
	assert_true(destination.unit.is_present())
	assert_same(destination.unit.tile, unit)
	assert_eq(unit.move, 2)
	assert_eq(context.state.get_current_ap(), 2)
	assert_eq(result.command_name, "move_unit")
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is UnitMovedEvent)
	assert_same((result.events[0] as UnitMovedEvent).start, source)
	assert_same((result.events[0] as UnitMovedEvent).finish, destination)

	unit.free()


func test_move_unit_rejects_missing_unit() -> void:
	var context := _make_context()
	var commands := MovementCommands.new(context)
	var source := MapTile.new(0, 0)
	var destination := MapTile.new(1, 0)

	var result := commands.move_unit_along_path(source, destination, 1, ["0_0", "1_0"])

	assert_eq(result.command_name, "move_unit_failed")
	assert_true(source.unit.is_present() == false)
	assert_true(destination.unit.is_present() == false)
	assert_eq(context.state.get_current_ap(), 4)
```

- [ ] **Step 2: Run movement tests to verify failure**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_movement_commands.gd
```

Expected: FAIL because `MovementCommands` does not exist.

- [ ] **Step 3: Implement MovementCommands**

Create `scenes/board/logic/commands/movement_commands.gd`:

```gdscript
class_name MovementCommands
extends RefCounted


var context: BoardCommandContext


func _init(command_context: BoardCommandContext) -> void:
	self.context = command_context


func can_move_to_tile(source_tile: MapTile, destination_tile: MapTile, move_cost: int) -> bool:
	if source_tile == null or destination_tile == null:
		return false
	if not source_tile.unit.is_present():
		return false
	if move_cost <= 0:
		return false
	if not self.context.state.can_current_player_afford(move_cost):
		return false
	return destination_tile.can_acommodate_unit(source_tile.unit.tile)


func move_unit_along_path(source_tile: MapTile, destination_tile: MapTile, move_cost: int, movement_path: Array[String]) -> CommandResult:
	var result := CommandResult.new("move_unit")
	if source_tile == null or destination_tile == null or not source_tile.unit.is_present():
		result.command_name = "move_unit_failed"
		return result

	var unit: BaseUnit = source_tile.unit.tile
	destination_tile.unit.set_tile(unit)
	source_tile.unit.release()
	self.context.state.use_current_player_ap(move_cost)
	unit.move = max(0, unit.move - move_cost)

	var event := UnitMovedEvent.new()
	event.unit = unit
	event.start = source_tile
	event.finish = destination_tile
	self.context.events.emit_event(event)
	result.add_event(event)
	result.metadata["path"] = movement_path
	result.delay = movement_path.size() * 0.1
	return result
```

- [ ] **Step 4: Wire MovementCommands into BoardModel**

In `scenes/board/board_model.gd`, add:

```gdscript
var movement_commands: MovementCommands = null
```

Inside `_rebuild_command_context()`, after `command_context` is assigned:

```gdscript
self.movement_commands = MovementCommands.new(self.command_context)
```

Replace `move_unit_along_path`:

```gdscript
func move_unit_along_path(source_tile: MapTile, destination_tile: MapTile, move_cost: int, movement_path: Array[String]) -> CommandResult:
	assert(self.movement_commands != null)
	return self.movement_commands.move_unit_along_path(source_tile, destination_tile, move_cost, movement_path)
```

Keep `move_unit(source_tile, destination_tile)` temporarily as a pure facade that requires explicit cost if markers are not available:

```gdscript
func move_unit(source_tile: MapTile, destination_tile: MapTile) -> CommandResult:
	assert(source_tile != null)
	assert(destination_tile != null)
	var move_cost: int = 1
	return self.move_unit_along_path(source_tile, destination_tile, move_cost, [str(source_tile.position), str(destination_tile.position)])
```

This temporary `move_unit` fallback is not a compatibility wrapper on `Board`; it is a model facade. Later tasks should remove marker-derived movement from command execution entirely.

- [ ] **Step 5: Remove fake movement host from headless scenario**

In `tests/unit/board/headless_board_scenario.gd`, remove `HeadlessBoardHost.move_unit_along_path` and stop assigning `self.model.board = self.host` in `_load_fixture`.

After loading players and tiles, call:

```gdscript
self.model.set_map_model(self.map_model)
```

Add `var map_model: MapModel = MapModel.new()` to `HeadlessBoardScenario` and register fixture tiles with `self.map_model.tiles[tile_position] = tile`.

- [ ] **Step 6: Preserve scene movement presentation in Board**

In `Board`, change call sites that previously called `move_unit_along_path` for gameplay to call `model.move_unit_along_path(...)`, then perform view-only movement animation from the returned result metadata:

```gdscript
var result := self.model.move_unit_along_path(source_tile, destination_tile, move_cost, movement_path)
self.reset_unit_position(source_tile, destination_tile.unit.tile)
self.update_unit_position_along_path(destination_tile, movement_path)
```

Do not keep `Board.move_unit_along_path` as a public gameplay wrapper. If a helper is needed for view animation, name it `_animate_unit_move_result(result: CommandResult)` and keep it private/view-only.

- [ ] **Step 7: Run movement and headless tests**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_movement_commands.gd
./tools/run_gut.sh -gtest=res://tests/unit/board/test_headless_validation.gd
```

Expected: PASS. `test_headless_fixture_can_move_unit_and_emit_event` must pass without assigning a fake board host.

- [ ] **Step 8: Commit Task 2**

```sh
git add scenes/board/logic/commands/movement_commands.gd scenes/board/board_model.gd scenes/board/board.gd tests/unit/board/commands/test_movement_commands.gd tests/unit/board/headless_board_scenario.gd tests/unit/board/test_headless_validation.gd
git commit -m "Move unit movement commands into BoardModel"
```

---

### Task 3: TurnCommands And AP Updates Without Board

**Files:**
- Create: `scenes/board/logic/commands/turn_commands.gd`
- Create: `scenes/board/logic/events/ap_changed.gd`
- Create: `scenes/board/logic/events/turn_ended.gd`
- Modify: `scenes/board/logic/events.gd`
- Modify: `scenes/board/board_model.gd`
- Modify: `scenes/board/board.gd`
- Test: `tests/unit/board/commands/test_turn_commands.gd`

- [ ] **Step 1: Write failing turn command tests**

Create `tests/unit/board/commands/test_turn_commands.gd`:

```gdscript
extends GutTest


func _make_context() -> BoardCommandContext:
	var state := State.new()
	state.add_player(State.PLAYER_HUMAN, "blue", true, 0)
	state.add_player_ap(0, 1)
	state.add_player(State.PLAYER_AI, "red", true, 1)
	state.add_player_ap(1, 2)
	var map_model := MapModel.new()
	return BoardCommandContext.new(state, map_model, Events.new(), Scripting.new(), Abilities.new(state))


func test_use_current_player_ap_emits_ap_changed_event() -> void:
	var context := _make_context()
	var commands := TurnCommands.new(context)

	var result := commands.use_current_player_ap(1)

	assert_eq(context.state.get_current_ap(), 0)
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is ApChangedEvent)
	assert_eq((result.events[0] as ApChangedEvent).player_id, 0)
	assert_eq((result.events[0] as ApChangedEvent).new_ap, 0)


func test_end_turn_emits_turn_ended_and_turn_started() -> void:
	var context := _make_context()
	var commands := TurnCommands.new(context)

	var result := commands.end_turn()

	assert_eq(context.state.current_player, 1)
	assert_eq(context.state.get_current_side(), "red")
	assert_eq(result.events.size(), 2)
	assert_true(result.events[0] is TurnEndedEvent)
	assert_true(result.events[1] is TurnStartedEvent)
	assert_eq((result.events[1] as TurnStartedEvent).player_id, 1)
```

- [ ] **Step 2: Run turn tests to verify failure**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_turn_commands.gd
```

Expected: FAIL because `TurnCommands`, `ApChangedEvent`, and `TurnEndedEvent` do not exist.

- [ ] **Step 3: Add AP and turn-ended events**

Create `scenes/board/logic/events/ap_changed.gd`:

```gdscript
extends BaseEvent
class_name ApChangedEvent

var player_id: int
var old_ap: int
var new_ap: int
```

Create `scenes/board/logic/events/turn_ended.gd`:

```gdscript
extends BaseEvent
class_name TurnEndedEvent

var turn_no: int
var player_id: int
```

Add emitters to `scenes/board/logic/events.gd`:

```gdscript
func emit_ap_changed(player_id: int, old_ap: int, new_ap: int) -> ApChangedEvent:
	var event := ApChangedEvent.new()
	event.player_id = player_id
	event.old_ap = old_ap
	event.new_ap = new_ap
	self.emit_event(event)
	return event


func emit_turn_ended(turn_no: int, player_id: int) -> TurnEndedEvent:
	var event := TurnEndedEvent.new()
	event.turn_no = turn_no
	event.player_id = player_id
	self.emit_event(event)
	return event
```

Change `emit_turn_started` to return the event:

```gdscript
func emit_turn_started(turn_no: int, player_id: int) -> TurnStartedEvent:
	var event := TurnStartedEvent.new()
	event.turn_no = turn_no
	event.player_id = player_id
	self.emit_event(event)
	return event
```

- [ ] **Step 4: Implement TurnCommands**

Create `scenes/board/logic/commands/turn_commands.gd`:

```gdscript
class_name TurnCommands
extends RefCounted


var context: BoardCommandContext


func _init(command_context: BoardCommandContext) -> void:
	self.context = command_context


func use_current_player_ap(value: int) -> CommandResult:
	var result := CommandResult.new("use_current_player_ap")
	var player_id: int = self.context.state.current_player
	var old_ap: int = self.context.state.get_current_ap()
	self.context.state.use_current_player_ap(value)
	var event := self.context.events.emit_ap_changed(player_id, old_ap, self.context.state.get_current_ap())
	result.add_event(event)
	return result


func add_current_player_ap(value: int) -> CommandResult:
	var result := CommandResult.new("add_current_player_ap")
	var player_id: int = self.context.state.current_player
	var old_ap: int = self.context.state.get_current_ap()
	self.context.state.add_current_player_ap(value)
	var event := self.context.events.emit_ap_changed(player_id, old_ap, self.context.state.get_current_ap())
	result.add_event(event)
	return result


func end_turn() -> CommandResult:
	var result := CommandResult.new("end_turn")
	var old_turn: int = self.context.state.turn
	var old_player: int = self.context.state.current_player
	result.add_event(self.context.events.emit_turn_ended(old_turn, old_player))
	self.context.state.switch_to_next_player()
	result.add_event(self.context.events.emit_turn_started(self.context.state.turn, self.context.state.current_player))
	return result
```

- [ ] **Step 5: Wire TurnCommands into BoardModel**

Add to `BoardModel`:

```gdscript
var turn_commands: TurnCommands = null
```

Inside `_rebuild_command_context()`:

```gdscript
self.turn_commands = TurnCommands.new(self.command_context)
```

Replace AP methods and `end_turn`:

```gdscript
func add_current_player_ap(value: int) -> CommandResult:
	assert(self.turn_commands != null)
	return self.turn_commands.add_current_player_ap(value)


func use_current_player_ap(value: int) -> CommandResult:
	assert(self.turn_commands != null)
	return self.turn_commands.use_current_player_ap(value)


func end_turn() -> CommandResult:
	assert(self.turn_commands != null)
	return self.turn_commands.end_turn()
```

- [ ] **Step 6: Move Board turn flow to event/view responsibilities**

In `Board.end_turn()`, keep autosave, radial close, UI reset, deferred `start_turn`, and visual concerns. Replace direct state mutation in `_end_turn()` with:

```gdscript
func _end_turn() -> void:
	self.unselect_tile()
	self.model.end_turn()
	self.ui.reset_timer()
	self.call_deferred(&"start_turn")
```

In `Board.add_current_player_ap` and `Board.use_current_player_ap`, remove gameplay mutation. Either delete these methods if no call sites remain or convert call sites to `model.add_current_player_ap` / `model.use_current_player_ap` and update resource UI from `ApChangedEvent`.

- [ ] **Step 7: Run tests**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_turn_commands.gd
./tools/run_gut.sh -gtest=res://tests/unit/board/test_board_model.gd
```

Expected: PASS.

- [ ] **Step 8: Commit Task 3**

```sh
git add scenes/board/logic/commands/turn_commands.gd scenes/board/logic/events/ap_changed.gd scenes/board/logic/events/turn_ended.gd scenes/board/logic/events.gd scenes/board/board_model.gd scenes/board/board.gd tests/unit/board/commands/test_turn_commands.gd tests/unit/board/test_board_model.gd
git commit -m "Move turn and AP commands into BoardModel"
```

---

### Task 4: UnitLifecycleCommands And Collateral Without Board

**Files:**
- Create: `scenes/board/logic/commands/unit_lifecycle_commands.gd`
- Create: `scenes/board/logic/events/collateral_damage_applied.gd`
- Modify: `scenes/board/logic/collateral.gd`
- Modify: `scenes/board/logic/events.gd`
- Modify: `scenes/board/board_model.gd`
- Modify: `scenes/board/board.gd`
- Test: `tests/unit/board/commands/test_unit_lifecycle_commands.gd`

- [ ] **Step 1: Write failing lifecycle tests**

Create `tests/unit/board/commands/test_unit_lifecycle_commands.gd`:

```gdscript
extends GutTest


func _make_context() -> BoardCommandContext:
	var state := State.new()
	state.add_player(State.PLAYER_HUMAN, "blue", true, 0)
	var map_model := MapModel.new()
	return BoardCommandContext.new(state, map_model, Events.new(), Scripting.new(), Abilities.new(state))


func test_destroy_unit_clears_tile_and_emits_destroyed_event() -> void:
	var context := _make_context()
	var tile := MapTile.new(0, 0)
	var attacker := BaseUnit.new()
	var defender := BaseUnit.new()
	defender.template_name = "tank"
	defender.side = "red"
	tile.unit.set_tile(defender)

	var commands := UnitLifecycleCommands.new(context)
	var result := commands.destroy_unit_on_tile(tile, attacker)

	assert_false(tile.unit.is_present())
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is UnitDestroyedEvent)
	assert_same((result.events[0] as UnitDestroyedEvent).attacker, attacker)
	assert_eq((result.events[0] as UnitDestroyedEvent).unit_type, "tank")
	assert_eq((result.events[0] as UnitDestroyedEvent).unit_side, "red")

	attacker.free()


func test_replenish_unit_actions_resets_current_player_units() -> void:
	var context := _make_context()
	var tile := MapTile.new(0, 0)
	var unit := BaseUnit.new()
	unit.side = "blue"
	unit.team = 0
	unit.max_move = 4
	unit.move = 0
	tile.unit.set_tile(unit)
	context.map_model.tiles[tile.position] = tile

	var commands := UnitLifecycleCommands.new(context)
	commands.replenish_unit_actions("blue")

	assert_eq(unit.move, 4)
	assert_eq(unit.team, 0)

	unit.free()
```

- [ ] **Step 2: Run lifecycle tests to verify failure**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_unit_lifecycle_commands.gd
```

Expected: FAIL because `UnitLifecycleCommands` does not exist.

- [ ] **Step 3: Add collateral event**

Create `scenes/board/logic/events/collateral_damage_applied.gd`:

```gdscript
extends BaseEvent
class_name CollateralDamageAppliedEvent

var origin: Vector2i
var damaged_tiles: Array[Vector2i] = []
var damage_template: Variant = null
```

Add to `Events`:

```gdscript
func emit_collateral_damage_applied(origin: Vector2i, damaged_tiles: Array[Vector2i], damage_template: Variant) -> CollateralDamageAppliedEvent:
	var event := CollateralDamageAppliedEvent.new()
	event.origin = origin
	event.damaged_tiles = damaged_tiles
	event.damage_template = damage_template
	self.emit_event(event)
	return event
```

- [ ] **Step 4: Implement UnitLifecycleCommands**

Create `scenes/board/logic/commands/unit_lifecycle_commands.gd`:

```gdscript
class_name UnitLifecycleCommands
extends RefCounted


var context: BoardCommandContext


func _init(command_context: BoardCommandContext) -> void:
	self.context = command_context


func destroy_unit_on_tile(tile: MapTile, attacker: BaseUnit = null, emit_event: bool = true) -> CommandResult:
	var result := CommandResult.new("destroy_unit")
	if tile == null or not tile.unit.is_present():
		result.command_name = "destroy_unit_failed"
		return result

	var unit: BaseUnit = tile.unit.tile
	var unit_id: int = unit.get_instance_id()
	var unit_type: String = unit.template_name
	var unit_side: String = unit.side

	if unit.unit_class == "hero":
		var hero: HeroUnit = unit as HeroUnit
		if hero != null:
			self.context.state.clear_hero_for_side(unit.side, hero)

	tile.unit.clear()

	if emit_event:
		var event := UnitDestroyedEvent.new()
		event.unit_id = unit_id
		event.unit_type = unit_type
		event.unit_side = unit_side
		event.attacker = attacker
		self.context.events.emit_event(event)
		result.add_event(event)

	return result


func replenish_unit_actions(side: String) -> CommandResult:
	var result := CommandResult.new("replenish_unit_actions")
	var units: Array[BaseUnit] = self.context.map_model.get_player_units(side)
	for unit: BaseUnit in units:
		unit.clear_modifiers()
		if self.context.abilities != null:
			self.context.abilities.apply_passive_modifiers(unit)
		unit.replenish_moves()
		unit.ability_cd_tick_down()
		unit.team = self.context.state.get_player_team(side)
	return result
```

- [ ] **Step 5: Wire lifecycle into BoardModel**

Add to `BoardModel`:

```gdscript
var unit_lifecycle_commands: UnitLifecycleCommands = null
```

Inside `_rebuild_command_context()`:

```gdscript
self.unit_lifecycle_commands = UnitLifecycleCommands.new(self.command_context)
```

Add facade:

```gdscript
func destroy_unit_on_tile(tile: MapTile, attacker: BaseUnit = null) -> CommandResult:
	assert(self.unit_lifecycle_commands != null)
	return self.unit_lifecycle_commands.destroy_unit_on_tile(tile, attacker)


func replenish_unit_actions(side: String = self.get_current_side()) -> CommandResult:
	assert(self.unit_lifecycle_commands != null)
	return self.unit_lifecycle_commands.replenish_unit_actions(side)
```

- [ ] **Step 6: Migrate Board destruction call sites**

Replace gameplay destruction call sites in `Board`:

```gdscript
self.destroy_unit_on_tile(defender_tile)
self.events.emit_unit_destroyed(attacker, defender_id, defender_type, defender_side)
```

with:

```gdscript
var destroy_result := self.model.destroy_unit_on_tile(defender_tile, attacker)
self._present_destroy_result(destroy_result, defender_tile)
```

Add private view helper:

```gdscript
func _present_destroy_result(_result: CommandResult, tile: MapTile) -> void:
	self.explode_a_tile(tile, true)
	if bool(self.settings.get_option("cam_shake")):
		self.map.camera.shake()
```

Do not keep `Board.destroy_unit_on_tile` as a public gameplay method after all callers are migrated.

- [ ] **Step 7: Run lifecycle tests**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_unit_lifecycle_commands.gd
./tools/run_gut.sh
```

Expected: PASS.

- [ ] **Step 8: Commit Task 4**

```sh
git add scenes/board/logic/commands/unit_lifecycle_commands.gd scenes/board/logic/events/collateral_damage_applied.gd scenes/board/logic/events.gd scenes/board/logic/collateral.gd scenes/board/board_model.gd scenes/board/board.gd tests/unit/board/commands/test_unit_lifecycle_commands.gd
git commit -m "Move unit lifecycle commands into BoardModel"
```

---

### Task 5: CombatCommands Without Board

**Files:**
- Create: `scenes/board/logic/commands/combat_commands.gd`
- Modify: `scenes/board/board_model.gd`
- Modify: `scenes/board/board.gd`
- Modify: `scenes/board/logic/ai/actions/attack_action.gd`
- Test: `tests/unit/board/commands/test_combat_commands.gd`
- Modify: `tests/unit/board/test_headless_validation.gd`

- [ ] **Step 1: Write failing combat tests**

Create `tests/unit/board/commands/test_combat_commands.gd`:

```gdscript
extends GutTest


func _make_model() -> BoardModel:
	var model := BoardModel.new()
	model.add_player({"type": State.PLAYER_HUMAN, "side": "blue", "alive": true, "team": 0, "ap": 4})
	model.set_map_model(MapModel.new())
	model.abilities = Abilities.new(model.state)
	model._rebuild_command_context()
	return model


func test_attack_damages_defender_spends_ap_and_emits_attack_event() -> void:
	var model := _make_model()
	var attacker_tile := MapTile.new(0, 0)
	var defender_tile := MapTile.new(1, 0)
	attacker_tile.add_neighbour(MapTile.EAST, defender_tile)
	defender_tile.add_neighbour(MapTile.WEST, attacker_tile)
	var attacker := BaseUnit.new()
	attacker.side = "blue"
	attacker.attack = 3
	attacker.move = 4
	attacker.attacks = 1
	var defender := BaseUnit.new()
	defender.side = "red"
	defender.hp = 10
	defender.max_hp = 10
	defender.armor = 0
	defender.move = 0
	attacker_tile.unit.set_tile(attacker)
	defender_tile.unit.set_tile(defender)

	var result := model.attack_unit(attacker_tile, defender_tile)

	assert_eq(model.get_current_ap(), 3)
	assert_lt(defender.hp, 10)
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is UnitAttackedEvent)

	attacker.free()
	defender.free()


func test_attack_destroying_defender_emits_destroyed_event() -> void:
	var model := _make_model()
	var attacker_tile := MapTile.new(0, 0)
	var defender_tile := MapTile.new(1, 0)
	var attacker := BaseUnit.new()
	attacker.side = "blue"
	attacker.attack = 99
	attacker.move = 4
	attacker.attacks = 1
	var defender := BaseUnit.new()
	defender.side = "red"
	defender.template_name = "scout"
	defender.hp = 1
	defender.max_hp = 1
	defender.armor = 0
	attacker_tile.unit.set_tile(attacker)
	defender_tile.unit.set_tile(defender)

	var result := model.attack_unit(attacker_tile, defender_tile)

	assert_false(defender_tile.unit.is_present())
	assert_true(result.events.any(func(event: BaseEvent) -> bool: return event is UnitDestroyedEvent))

	attacker.free()
```

- [ ] **Step 2: Run combat tests to verify failure**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_combat_commands.gd
```

Expected: FAIL because `BoardModel.attack_unit` and `CombatCommands` do not exist.

- [ ] **Step 3: Implement CombatCommands**

Create `scenes/board/logic/commands/combat_commands.gd`:

```gdscript
class_name CombatCommands
extends RefCounted


var context: BoardCommandContext
var lifecycle: UnitLifecycleCommands
var turns: TurnCommands


func _init(command_context: BoardCommandContext, lifecycle_commands: UnitLifecycleCommands, turn_commands: TurnCommands) -> void:
	self.context = command_context
	self.lifecycle = lifecycle_commands
	self.turns = turn_commands


func attack_unit(attacker_tile: MapTile, defender_tile: MapTile) -> CommandResult:
	var result := CommandResult.new("attack_unit")
	if attacker_tile == null or defender_tile == null:
		result.command_name = "attack_unit_failed"
		return result
	if not attacker_tile.unit.is_present() or not defender_tile.unit.is_present():
		result.command_name = "attack_unit_failed"
		return result

	var attacker: BaseUnit = attacker_tile.unit.tile
	var defender: BaseUnit = defender_tile.unit.tile
	attacker.use_move(1)
	attacker.use_attack()
	defender.receive_damage(attacker.get_attack())
	result.events.append_array(self.turns.use_current_player_ap(1).events)

	if defender.is_alive():
		var attack_event := UnitAttackedEvent.new()
		attack_event.attacker = attacker
		attack_event.unit = defender
		self.context.events.emit_event(attack_event)
		result.add_event(attack_event)
		self._try_retaliation(result, defender_tile, attacker_tile)
	else:
		result.events.append_array(self.lifecycle.destroy_unit_on_tile(defender_tile, attacker).events)

	return result


func _try_retaliation(result: CommandResult, defender_tile: MapTile, attacker_tile: MapTile) -> void:
	var defender: BaseUnit = defender_tile.unit.tile
	var attacker: BaseUnit = attacker_tile.unit.tile
	if defender == null or attacker == null:
		return
	if not defender.can_attack_unit(attacker) or not defender.has_moves():
		return

	defender.use_all_moves()
	attacker.receive_damage(defender.get_attack())
	result.delay = 0.5

	if attacker.is_alive():
		var retaliation_event := UnitAttackedEvent.new()
		retaliation_event.attacker = defender
		retaliation_event.unit = attacker
		self.context.events.emit_event(retaliation_event)
		result.add_event(retaliation_event)
	else:
		result.events.append_array(self.lifecycle.destroy_unit_on_tile(attacker_tile, defender).events)
```

- [ ] **Step 4: Wire combat into BoardModel**

Add:

```gdscript
var combat_commands: CombatCommands = null
```

Inside `_rebuild_command_context()` after lifecycle and turn commands are initialized:

```gdscript
self.combat_commands = CombatCommands.new(self.command_context, self.unit_lifecycle_commands, self.turn_commands)
```

Add facade:

```gdscript
func attack_unit(source_tile: MapTile, target_tile: MapTile) -> CommandResult:
	assert(self.combat_commands != null)
	return self.combat_commands.attack_unit(source_tile, target_tile)
```

Change `interact_unit` so unit targets call `attack_unit` directly and do not delegate to `Board`.

- [ ] **Step 5: Convert Board battle presentation**

Remove `Board.battle` as gameplay command. Move visual-only pieces into event handlers or private helpers:

```gdscript
func _present_unit_attacked(event: UnitAttackedEvent) -> void:
	event.attacker.sfx_effect("attack")
	event.attacker.sfx_effect("hit")
	event.unit.show_explosion()
```

If rotation must remain for presentation, rotate in `_present_unit_attacked` using tile positions carried in a later event update. If the existing `UnitAttackedEvent` lacks tile context, extend it with `attacker_tile` and `defender_tile` in this task.

- [ ] **Step 6: Run combat and headless tests**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_combat_commands.gd
./tools/run_gut.sh -gtest=res://tests/unit/board/test_headless_validation.gd
```

Expected: PASS.

- [ ] **Step 7: Commit Task 5**

```sh
git add scenes/board/logic/commands/combat_commands.gd scenes/board/board_model.gd scenes/board/board.gd scenes/board/logic/ai/actions/attack_action.gd tests/unit/board/commands/test_combat_commands.gd tests/unit/board/test_headless_validation.gd
git commit -m "Move combat commands into BoardModel"
```

---

### Task 6: CaptureCommands Without Board

**Files:**
- Create: `scenes/board/logic/commands/capture_commands.gd`
- Modify: `scenes/board/board_model.gd`
- Modify: `scenes/board/board.gd`
- Modify: `scenes/board/logic/ai/actions/capture_action.gd`
- Test: `tests/unit/board/commands/test_capture_commands.gd`
- Modify: `tests/unit/board/test_headless_validation.gd`

- [ ] **Step 1: Write failing capture tests**

Create `tests/unit/board/commands/test_capture_commands.gd`:

```gdscript
extends GutTest


func _make_model() -> BoardModel:
	var model := BoardModel.new()
	model.add_player({"type": State.PLAYER_HUMAN, "side": "blue", "alive": true, "team": 0, "ap": 4})
	model.set_map_model(MapModel.new())
	model.abilities = Abilities.new(model.state)
	model._rebuild_command_context()
	return model


func test_capture_changes_building_side_spends_ap_and_emits_event() -> void:
	var model := _make_model()
	var attacker_tile := MapTile.new(0, 0)
	var building_tile := MapTile.new(1, 0)
	var attacker := BaseUnit.new()
	attacker.side = "blue"
	attacker.team = 0
	attacker.can_capture = true
	attacker.move = 4
	var building := BaseBuilding.new()
	building.side = "red"
	building.team = 1
	building.require_crew = false
	attacker_tile.unit.set_tile(attacker)
	building_tile.building.set_tile(building)

	var result := model.capture_building(attacker_tile, building_tile)

	assert_eq(building.side, "blue")
	assert_eq(building.team, 0)
	assert_eq(model.get_current_ap(), 3)
	assert_eq(result.events.size(), 2)
	assert_true(result.events.any(func(event: BaseEvent) -> bool: return event is BuildingCapturedEvent))

	attacker.free()
	building.free()
```

- [ ] **Step 2: Run capture tests to verify failure**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_capture_commands.gd
```

Expected: FAIL because `CaptureCommands` and `BoardModel.capture_building` do not exist.

- [ ] **Step 3: Implement CaptureCommands**

Create `scenes/board/logic/commands/capture_commands.gd`:

```gdscript
class_name CaptureCommands
extends RefCounted


var context: BoardCommandContext
var lifecycle: UnitLifecycleCommands
var turns: TurnCommands


func _init(command_context: BoardCommandContext, lifecycle_commands: UnitLifecycleCommands, turn_commands: TurnCommands) -> void:
	self.context = command_context
	self.lifecycle = lifecycle_commands
	self.turns = turn_commands


func capture_building(attacker_tile: MapTile, building_tile: MapTile) -> CommandResult:
	var result := CommandResult.new("capture_building")
	if attacker_tile == null or building_tile == null:
		result.command_name = "capture_building_failed"
		return result
	if not attacker_tile.unit.is_present() or not building_tile.building.is_present():
		result.command_name = "capture_building_failed"
		return result

	var attacker: BaseUnit = attacker_tile.unit.tile
	var building: BaseBuilding = building_tile.building.tile
	if not attacker.can_capture:
		result.command_name = "capture_building_failed"
		return result

	var old_side: String = building.side
	attacker.use_all_moves()
	building.side = attacker.side
	building.team = attacker.team
	result.events.append_array(self.turns.use_current_player_ap(1).events)

	if building.require_crew and self.context.abilities != null and not self.context.abilities.can_intimidate_crew(attacker):
		result.events.append_array(self.lifecycle.destroy_unit_on_tile(attacker_tile, null, false).events)

	var event := BuildingCapturedEvent.new()
	event.building = building
	event.old_side = old_side
	event.new_side = attacker.side
	self.context.events.emit_event(event)
	result.add_event(event)
	result.delay = 0.5
	return result
```

- [ ] **Step 4: Wire capture into BoardModel**

Add:

```gdscript
var capture_commands: CaptureCommands = null
```

Inside `_rebuild_command_context()`:

```gdscript
self.capture_commands = CaptureCommands.new(self.command_context, self.unit_lifecycle_commands, self.turn_commands)
```

Add facade:

```gdscript
func capture_building(source_tile: MapTile, target_tile: MapTile) -> CommandResult:
	assert(self.capture_commands != null)
	return self.capture_commands.capture_building(source_tile, target_tile)
```

Update `interact_unit` so building targets call `capture_building` directly.

- [ ] **Step 5: Remove Board capture command surface**

Delete `Board.capture` after all call sites move. Move smoke/sfx into event presentation:

```gdscript
func _present_building_captured(event: BuildingCapturedEvent) -> void:
	var tile: MapTile = self.map.model.get_tile_for_building(event.building)
	if tile != null:
		self.smoke_a_tile(tile)
	event.building.sfx_effect("capture")
```

If `MapModel` lacks `get_tile_for_building`, add it:

```gdscript
func get_tile_for_building(building: BaseBuilding) -> MapTile:
	for tile: MapTile in self.tiles.values():
		if tile.building.tile == building:
			return tile
	return null
```

- [ ] **Step 6: Run tests**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_capture_commands.gd
./tools/run_gut.sh -gtest=res://tests/unit/board/test_headless_validation.gd
```

Expected: PASS.

- [ ] **Step 7: Commit Task 6**

```sh
git add scenes/board/logic/commands/capture_commands.gd scenes/board/board_model.gd scenes/board/board.gd scenes/map/map_model.gd scenes/board/logic/ai/actions/capture_action.gd tests/unit/board/commands/test_capture_commands.gd tests/unit/board/test_headless_validation.gd
git commit -m "Move capture commands into BoardModel"
```

---

### Task 7: AbilityCommands Without Board

**Files:**
- Create: `scenes/board/logic/commands/ability_commands.gd`
- Modify: `scenes/abilities/ability.gd`
- Modify: `scenes/abilities/ability_state.gd`
- Modify: `scenes/abilities/unit/active.gd`
- Modify: `scenes/abilities/hero/active/active.gd`
- Modify: concrete ability scripts under `scenes/abilities`
- Modify: `scenes/board/board_model.gd`
- Modify: `scenes/board/board.gd`
- Test: `tests/unit/board/commands/test_ability_commands.gd`

- [ ] **Step 1: Write failing ability command tests**

Create `tests/unit/board/commands/test_ability_commands.gd`:

```gdscript
extends GutTest


class TestAbility:
	extends Ability

	var executed_position := Vector2i(-1, -1)

	func _execute_model(model: BoardModel, _source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
		self.executed_position = position
		model.add_current_player_ap(1)


func _make_model() -> BoardModel:
	var model := BoardModel.new()
	model.add_player({"type": State.PLAYER_HUMAN, "side": "blue", "alive": true, "team": 0, "ap": 4})
	model.set_map_model(MapModel.new())
	model.abilities = Abilities.new(model.state)
	model._rebuild_command_context()
	return model


func test_use_ability_executes_with_model_context_activates_cooldown_and_emits_event() -> void:
	var model := _make_model()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var unit := BaseUnit.new()
	unit.side = "blue"
	unit.move = 4
	origin.unit.set_tile(unit)
	var ability := TestAbility.new()
	ability.cooldown = 2

	var result := model.use_ability(origin, ability, target)

	assert_eq(ability.executed_position, target.position)
	assert_eq(unit.get_ability_cooldown(ability), 2)
	assert_true(result.events.any(func(event: BaseEvent) -> bool: return event is AbilityUsedEvent))

	unit.free()
```

- [ ] **Step 2: Run ability tests to verify failure**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_ability_commands.gd
```

Expected: FAIL because `_execute_model`, `AbilityCommands`, and model-side cooldown activation do not exist.

- [ ] **Step 3: Add model-side ability execution API**

Modify `scenes/abilities/ability.gd`:

```gdscript
func execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, position: Vector2i) -> AbilityUsedEvent:
	self._execute_model(model, source, origin_tile, position)
	var event := AbilityUsedEvent.new()
	event.ability = self
	event.target = position
	model.events.emit_event(event)
	return event


func _execute_model(_model: BoardModel, _source: Variant, _origin_tile: MapTile, _position: Vector2i) -> void:
	return
```

Keep old `execute(board, ...)` only until all concrete abilities are migrated. It must be deleted in Task 9.

Modify `scenes/abilities/ability_state.gd`:

```gdscript
func activate_cooldown_model(ability: Ability, abilities: Abilities, source: Variant) -> void:
	self.cd_turns_left = abilities.get_modified_cooldown(ability.get_cooldown(source), source)
```

- [ ] **Step 4: Implement AbilityCommands**

Create `scenes/board/logic/commands/ability_commands.gd`:

```gdscript
class_name AbilityCommands
extends RefCounted


var model: BoardModel
var context: BoardCommandContext


func _init(model_object: BoardModel, command_context: BoardCommandContext) -> void:
	self.model = model_object
	self.context = command_context


func use_ability(origin_tile: MapTile, ability: Ability, target_tile: MapTile) -> CommandResult:
	var result := CommandResult.new("use_ability")
	if origin_tile == null or ability == null or target_tile == null:
		result.command_name = "use_ability_failed"
		return result

	var source: Variant = null
	if origin_tile.building.is_present():
		source = origin_tile.building.tile
	elif origin_tile.unit.is_present():
		source = origin_tile.unit.tile

	if source == null:
		result.command_name = "use_ability_failed"
		return result

	var event := ability.execute_model(self.model, source, origin_tile, target_tile.position)
	result.add_event(event)
	source.get_ability_state(ability).activate_cooldown_model(ability, self.context.abilities, source)
	result.delay = 0.25
	return result
```

- [ ] **Step 5: Wire ability into BoardModel**

Add:

```gdscript
var ability_commands: AbilityCommands = null
```

Inside `_rebuild_command_context()`:

```gdscript
self.ability_commands = AbilityCommands.new(self, self.command_context)
```

Replace `use_ability`:

```gdscript
func use_ability(origin_tile: MapTile, ability: Ability, target_tile: MapTile) -> CommandResult:
	assert(self.ability_commands != null)
	return self.ability_commands.use_ability(origin_tile, ability, target_tile)
```

- [ ] **Step 6: Migrate concrete abilities by category**

For each script under `scenes/abilities`, replace board-facing gameplay in `_execute` with `_execute_model`. Examples:

Unit repair/medkit:

```gdscript
func _execute_model(model: BoardModel, _source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
	var tile := model.get_tile_at(position)
	if tile.unit.is_present():
		tile.unit.tile.heal(self.value)
```

Projectile damage abilities:

```gdscript
func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
	var tile := model.get_tile_at(position)
	if tile.unit.is_present():
		var unit: BaseUnit = tile.unit.tile
		unit.receive_damage(source.get_attack())
		if not unit.is_alive():
			model.destroy_unit_on_tile(tile, source)
```

Production spawn:

```gdscript
func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
	var cost: int = self.cost
	if model.abilities != null:
		cost = model.abilities.get_modified_cost(cost, self.template_name, source)
	model.use_current_player_ap(cost)
	model.spawn_unit(position, self.template_name, 0, model.get_current_side(), source)
```

Hero buff abilities:

```gdscript
func _execute_model(model: BoardModel, _source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
	var tile := model.get_tile_at(position)
	if tile.unit.is_present():
		tile.unit.tile.apply_modifier(self.modifier_name, self.modifier_value)
```

Visual-only calls such as `heal_a_tile`, `bless_a_tile`, `smoke_a_tile`, `shoot_projectile`, `lob_projectile`, `refresh_tile_selection`, and selection changes must be removed from ability command execution. Emit or extend gameplay events when presentation needs context.

- [ ] **Step 7: Remove Board execute ability command surface**

Move `Board.execute_active_ability` to controller/view interaction only:

```gdscript
func execute_active_ability(target_tile: MapTile) -> void:
	assert(self.active_ability != null)
	var result := self.model.use_ability(self.active_ability_origin_tile, self.active_ability, target_tile)
	await self.model.action_pacer.wait_after(result)
	self.cancel_ability()
```

Delete `Board.execute_ability_from_tile` after all callers use `BoardModel.use_ability`.

- [ ] **Step 8: Run ability tests**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/commands/test_ability_commands.gd
./tools/run_gut.sh -gtest=res://tests/unit/board/test_headless_validation.gd
./tools/run_gut.sh
```

Expected: PASS.

- [ ] **Step 9: Commit Task 7**

```sh
git add scenes/board/logic/commands/ability_commands.gd scenes/abilities scenes/board/board_model.gd scenes/board/board.gd tests/unit/board/commands/test_ability_commands.gd tests/unit/board/test_headless_validation.gd
git commit -m "Move ability commands into BoardModel"
```

---

### Task 8: AI Pacing Without Board Command Dependencies

**Files:**
- Modify: `scenes/board/logic/ai/actions/move_action.gd`
- Modify: `scenes/board/logic/ai/actions/attack_action.gd`
- Modify: `scenes/board/logic/ai/actions/capture_action.gd`
- Modify: `scenes/board/logic/ai/actions/use_ability_action.gd`
- Modify: `scenes/board/logic/ai/actions/reserve_ap_action.gd`
- Modify: `scenes/board/logic/ai/ai.gd`
- Test: `tests/unit/board/ai/test_ai_action_pacing.gd`
- Modify: `tests/unit/board/ai/test_ai_actions.gd`

- [ ] **Step 1: Write failing AI pacing tests**

Create `tests/unit/board/ai/test_ai_action_pacing.gd`:

```gdscript
extends GutTest


class RecordingPacer:
	extends ActionPacer

	var results: Array[CommandResult] = []

	func wait_after(result: CommandResult) -> void:
		self.results.append(result)


func test_move_action_waits_on_model_pacer_not_unit_signal() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var pacer := RecordingPacer.new()
	scenario.model.set_action_pacer(pacer)
	var source: MapTile = scenario.get_tile(Vector2i(0, 0))
	var destination: MapTile = scenario.get_tile(Vector2i(1, 0))
	var action := MoveAction.new(source, destination, ["0_0", "1_0"])

	await action.perform(scenario.model)

	assert_eq(pacer.results.size(), 1)
	assert_eq(pacer.results[0].command_name, "move_unit")

	scenario.cleanup()


func test_attack_action_waits_on_model_pacer() -> void:
	var scenario := HeadlessBoardScenario.with_adjacent_enemy()
	var pacer := RecordingPacer.new()
	scenario.model.set_action_pacer(pacer)
	var action := AttackAction.new(scenario.get_tile(Vector2i(0, 0)), null, scenario.get_tile(Vector2i(1, 0)), [])

	await action.perform(scenario.model)

	assert_eq(pacer.results.size(), 1)
	assert_eq(pacer.results[0].command_name, "attack_unit")

	scenario.cleanup()
```

Add helper `HeadlessBoardScenario.with_adjacent_enemy()` in the fixture helper during this task.

- [ ] **Step 2: Run AI pacing tests to verify failure**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/ai/test_ai_action_pacing.gd
```

Expected: FAIL because AI actions still wait on unit signals or model delay methods.

- [ ] **Step 3: Update AI actions to use command results and pacer**

Change `MoveAction.perform`:

```gdscript
func perform(model: BoardModel) -> void:
	var result := model.move_unit_along_path(self.unit, self.target, self._get_move_cost(), self.movement_path)
	await model.action_pacer.wait_after(result)
```

Change `AttackAction.perform`:

```gdscript
func perform(model: BoardModel) -> void:
	var result: CommandResult
	if self.interaction != null:
		var move_result := model.move_unit_along_path(self.unit, self.interaction, self._get_move_cost(), self.movement_path)
		await model.action_pacer.wait_after(move_result)
		result = model.interact_unit(self.interaction, null, self.target)
	else:
		result = model.interact_unit(self.unit, null, self.target)
	await model.action_pacer.wait_after(result)
```

Change `CaptureAction.perform` with the same pattern.

Change `UseAbilityAction.perform`:

```gdscript
func perform(model: BoardModel) -> void:
	var result := model.use_ability(self.origin_tile, self.ability, self.target)
	await model.action_pacer.wait_after(result)
```

`ReserveApAction.perform` should return without pacing unless a later requirement needs it:

```gdscript
func perform(model: BoardModel) -> void:
	model.reserve_ap(self.amount)
```

- [ ] **Step 4: Remove BoardModel.wait_for_action_delay**

Delete `wait_for_action_delay` from `BoardModel` after all call sites are gone.

- [ ] **Step 5: Run AI tests**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/ai/test_ai_action_pacing.gd
./tools/run_gut.sh -gtest=res://tests/unit/board/ai/test_ai_actions.gd
```

Expected: PASS. Existing AI action tests should assert calls to model/service outcomes, not fake `Board` hosts.

- [ ] **Step 6: Commit Task 8**

```sh
git add scenes/board/logic/ai/actions scenes/board/logic/ai/ai.gd scenes/board/board_model.gd tests/unit/board/ai/test_ai_action_pacing.gd tests/unit/board/ai/test_ai_actions.gd tests/unit/board/headless_board_scenario.gd
git commit -m "Move AI pacing outside board commands"
```

---

### Task 9: Remove Board Command Surface And Fake Headless Host

**Files:**
- Modify: `scenes/board/board.gd`
- Modify: `scenes/board/board_model.gd`
- Modify: `tests/unit/board/headless_board_scenario.gd`
- Modify: `tests/unit/board/test_headless_validation.gd`
- Create: `tests/unit/board/test_board_command_boundary.gd`

- [ ] **Step 1: Write boundary tests**

Create `tests/unit/board/test_board_command_boundary.gd`:

```gdscript
extends GutTest


func test_board_model_core_commands_work_without_board() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")

	assert_null(scenario.model.board)
	assert_not_null(scenario.model.movement_commands)
	assert_not_null(scenario.model.capture_commands)
	assert_not_null(scenario.model.ability_commands)
	assert_not_null(scenario.model.turn_commands)

	var move_result := scenario.model.move_unit_along_path(
		scenario.get_tile(Vector2i(0, 0)),
		scenario.get_tile(Vector2i(1, 0)),
		1,
		["0_0", "1_0"]
	)

	assert_eq(move_result.command_name, "move_unit")
	assert_false(scenario.get_tile(Vector2i(0, 0)).unit.is_present())

	scenario.cleanup()


func test_board_model_no_longer_exposes_board_dependent_command_methods() -> void:
	var model := BoardModel.new()

	assert_false(model.has_method("wait_for_action_delay"))
	assert_false(model.has_method("execute_active_ability"))
	assert_false(model.has_method("set_last_unit_move"))
```

- [ ] **Step 2: Run boundary tests to verify failure**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/test_board_command_boundary.gd
```

Expected: FAIL until fake host and board-dependent model methods are removed.

- [ ] **Step 3: Remove fake host from headless scenario**

In `tests/unit/board/headless_board_scenario.gd`, delete `HeadlessAi`, `HeadlessBoardHost`, and all `host` usage. The scenario should create a `BoardModel`, `MapModel`, fixture tiles, event recorders, and command services only.

Keep fields:

```gdscript
var model: BoardModel = BoardModel.new()
var map_model: MapModel = MapModel.new()
var tiles: Dictionary[Vector2i, MapTile] = {}
```

In `_load_fixture`, after tiles and players:

```gdscript
self.model.set_map_model(self.map_model)
self.model.abilities = Abilities.new(self.model.state)
self.model.collateral = Collateral.new(self.model)
self.model._rebuild_command_context()
```

- [ ] **Step 4: Remove BoardModel board command delegates**

Delete these methods from `BoardModel` after all call sites are migrated:

```gdscript
set_last_unit_move
execute_active_ability
can_move_to_tile
wait_for_action_delay
selected_unit_can_interact_with
handle_interaction
```

Keep view/query methods only if they are not command execution and still have active callers. Any remaining method that asserts `self.board != null` must be reviewed and documented as view/adapter bridge, not a command path.

- [ ] **Step 5: Remove Board gameplay command methods**

Delete or privatize old command methods from `Board`:

```gdscript
move_unit
move_unit_along_path
handle_interaction_from_tile
battle
destroy_unit_on_tile
capture
execute_ability_from_tile
replenish_unit_actions
gain_building_ap
add_current_player_ap
use_current_player_ap
```

If a visual helper remains, rename it with a presentation name:

```gdscript
_present_unit_moved
_present_unit_attacked
_present_unit_destroyed
_present_building_captured
_present_ability_used
_present_turn_started
_present_ap_changed
```

- [ ] **Step 6: Add forbidden dependency search checks**

Run:

```sh
rg -n "\\bBoard\\b|board\\.|selected_tile|active_ability|movement_markers|path_markers|ability_markers|camera|radial|audio|animation|animate_|get_tree\\(\\)|create_timer" scenes/board/logic/commands scenes/board/logic/ai/actions
```

Expected: no matches except type names in comments are not allowed. Remove comments if they trip the check.

Run:

```sh
rg -n "func (move_unit|move_unit_along_path|handle_interaction_from_tile|battle|destroy_unit_on_tile|capture|execute_ability_from_tile|add_current_player_ap|use_current_player_ap)" scenes/board/board.gd
```

Expected: no matches.

- [ ] **Step 7: Run boundary and full tests**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh -gtest=res://tests/unit/board/test_board_command_boundary.gd
./tools/run_gut.sh -gtest=res://tests/unit/board/test_headless_validation.gd
./tools/run_gut.sh
```

Expected: PASS.

- [ ] **Step 8: Commit Task 9**

```sh
git add scenes/board/board.gd scenes/board/board_model.gd tests/unit/board/headless_board_scenario.gd tests/unit/board/test_headless_validation.gd tests/unit/board/test_board_command_boundary.gd
git commit -m "Remove board gameplay command surface"
```

---

### Task 10: Final Validation And Documentation

**Files:**
- Modify: `docs/superpowers/specs/2026-07-06-board-command-services-design.md` only if implementation reveals a necessary clarification.
- Modify: `docs/superpowers/plans/2026-07-06-board-command-services.md` checkbox statuses during execution.

- [ ] **Step 1: Run full GUT**

```sh
: "${GODOT_BIN:=godot}"
./tools/run_gut.sh
```

Expected: all tests pass. Existing shutdown leak warnings are acceptable only if exit code is 0 and there are no new parser/script errors.

- [ ] **Step 2: Run Godot headless load**

```sh
: "${GODOT_BIN:=godot}"
HOME=/private/tmp "$GODOT_BIN" --headless --path "$PWD" --quit
```

Expected: exit code 0. Existing shutdown leak warnings are acceptable.

- [ ] **Step 3: Run diff and personal-path checks**

```sh
git diff --check
rg -n "/Users/Personal|Steam/steamapps|Godot.app|Contents/MacOS/Godot" .
```

Expected: `git diff --check` prints nothing and exits 0. The path scan prints nothing and exits 1.

- [ ] **Step 4: Run forbidden dependency checks**

```sh
rg -n "\\bBoard\\b|board\\.|selected_tile|active_ability|movement_markers|path_markers|ability_markers|camera|radial|audio|animation|animate_|get_tree\\(\\)|create_timer" scenes/board/logic/commands scenes/board/logic/ai/actions
rg -n "func (move_unit|move_unit_along_path|handle_interaction_from_tile|battle|destroy_unit_on_tile|capture|execute_ability_from_tile|add_current_player_ap|use_current_player_ap)" scenes/board/board.gd
```

Expected: both searches print nothing and exit 1.

- [ ] **Step 5: Review final public command API**

Run:

```sh
rg -n "func (move_unit|move_unit_along_path|attack_unit|capture_building|use_ability|end_turn|destroy_unit_on_tile|spawn_unit|replenish_unit_actions)" scenes/board/board_model.gd scenes/board/logic/commands
```

Expected: command facades appear on `BoardModel`; command implementations appear in command service files; no core implementation appears in `Board`.

- [ ] **Step 6: Commit validation/doc updates**

```sh
git add docs/superpowers/plans/2026-07-06-board-command-services.md docs/superpowers/specs/2026-07-06-board-command-services-design.md
git commit -m "Document board command service execution status"
```

Skip this commit if no docs changed during implementation.

---

## Self-Review Checklist

- Spec coverage: Tasks cover command services, no Board command execution, all core commands, events-only output, no temporary effects adapters, pacing outside services, headless tests, AI command boundary, and forbidden dependency searches.
- Placeholder scan: This plan intentionally contains no `TBD`, no open-ended "add tests", and no unspecified implementation buckets.
- Type consistency: Public facade names are `move_unit_along_path`, `attack_unit`, `capture_building`, `use_ability`, `end_turn`, `destroy_unit_on_tile`, and `replenish_unit_actions`. Service names match the spec: `MovementCommands`, `CombatCommands`, `CaptureCommands`, `AbilityCommands`, `TurnCommands`, and `UnitLifecycleCommands`.
