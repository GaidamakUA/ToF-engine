extends GutTest


const MovementCommandsScript: Script = preload("res://scenes/board/logic/commands/movement_commands.gd")


class MoveTrackingUnit:
	extends BaseUnit

	var used_move_cost: int = -1

	func use_move(value: int) -> void:
		self.used_move_cost = value
		self.move = max(0, self.move - value)


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
	var unit := MoveTrackingUnit.new()
	unit.side = "blue"
	unit.team = 0
	unit.move = 4
	unit.max_move = 4
	source.unit.set_tile(unit)
	var movement_path: Array[String] = ["0_0", "1_0"]

	var commands: Variant = MovementCommandsScript.new(context)
	var result: CommandResult = commands.move_unit_along_path(source, destination, 2, movement_path)

	assert_false(source.unit.is_present())
	assert_true(destination.unit.is_present())
	assert_same(destination.unit.tile, unit)
	assert_eq(unit.move, 2)
	assert_eq(unit.used_move_cost, 2)
	assert_eq(context.state.get_current_ap(), 2)
	assert_eq(result.command_name, "move_unit")
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is UnitMovedEvent)
	assert_same((result.events[0] as UnitMovedEvent).start, source)
	assert_same((result.events[0] as UnitMovedEvent).finish, destination)

	unit.free()


func test_move_unit_rejects_missing_unit() -> void:
	var context := _make_context()
	var commands: Variant = MovementCommandsScript.new(context)
	var source := MapTile.new(0, 0)
	var destination := MapTile.new(1, 0)
	var movement_path: Array[String] = ["0_0", "1_0"]

	var result: CommandResult = commands.move_unit_along_path(source, destination, 1, movement_path)

	assert_eq(result.command_name, "move_unit_failed")
	assert_true(source.unit.is_present() == false)
	assert_true(destination.unit.is_present() == false)
	assert_eq(context.state.get_current_ap(), 4)
