extends GutTest


const UnitLifecycleCommandsScript: Script = preload("res://scenes/board/logic/commands/unit_lifecycle_commands.gd")


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

	var commands: Variant = UnitLifecycleCommandsScript.new(context)
	var result: CommandResult = commands.destroy_unit_on_tile(tile, attacker)

	assert_false(tile.unit.is_present())
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is UnitDestroyedEvent)
	assert_same((result.events[0] as UnitDestroyedEvent).attacker, attacker)
	assert_eq((result.events[0] as UnitDestroyedEvent).unit_type, "tank")
	assert_eq((result.events[0] as UnitDestroyedEvent).unit_side, "red")

	attacker.free()
	defender.free()


func test_destroy_hero_clears_state_registration() -> void:
	var context := _make_context()
	var tile := MapTile.new(0, 0)
	var hero := HeroUnit.new()
	hero.side = "blue"
	hero.unit_class = "hero"
	tile.unit.set_tile(hero)
	context.state.add_hero_for_side("blue", hero)

	var commands: Variant = UnitLifecycleCommandsScript.new(context)
	commands.destroy_unit_on_tile(tile)

	assert_false(tile.unit.is_present())
	assert_eq(context.state.get_heroes_for_side("blue").size(), 0)

	hero.free()


func test_replenish_unit_actions_resets_current_player_units() -> void:
	var context := _make_context()
	var tile := MapTile.new(0, 0)
	var unit := BaseUnit.new()
	unit.side = "blue"
	unit.team = 0
	unit.max_move = 4
	unit.move = 0
	tile.unit.set_tile(unit)
	context.map_model.tiles["0_0"] = tile

	var commands: Variant = UnitLifecycleCommandsScript.new(context)
	commands.replenish_unit_actions("blue")

	assert_eq(unit.move, 4)
	assert_eq(unit.team, 0)

	tile.unit.release()
	unit.free()
