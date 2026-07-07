extends GutTest


class FakeBoard:
	extends Board

	class FakeUnitLifecycleCommands:
		extends RefCounted

		var destroy_calls: Array[Array] = []

		func destroy_unit_on_tile(tile: MapTile, attacker: BaseUnit = null, emit_event: bool = true) -> CommandResult:
			self.destroy_calls.append([tile, attacker, emit_event])
			return CommandResult.new("destroy_unit")

	class FakeBoardModel:
		extends BoardModel

		var used_ap: Array[int] = []
		var destroy_calls: Array[Array] = []
		var fake_unit_lifecycle_commands := FakeUnitLifecycleCommands.new()

		func _init() -> void:
			self.unit_lifecycle_commands = self.fake_unit_lifecycle_commands

		func use_current_player_ap(value: int) -> CommandResult:
			self.used_ap.append(value)
			return CommandResult.new("use_current_player_ap")

		func destroy_unit_on_tile(tile: MapTile, attacker: BaseUnit = null) -> CommandResult:
			self.destroy_calls.append([tile, attacker])
			return CommandResult.new("destroy_unit")

	var battle_calls: Array[Array] = []
	var contextual_select_count: int = 0
	var presented_destructions: Array[Array] = []

	func _init() -> void:
		super()
		self.board_model = FakeBoardModel.new()

	func battle(attacker_tile: MapTile, defender_tile: MapTile) -> void:
		self.battle_calls.append([attacker_tile, defender_tile])

	func _update_ap_spent_presentation() -> void:
		pass

	func show_contextual_select(_open_unit_abilities: bool = false) -> void:
		self.contextual_select_count += 1

	func _present_unit_destruction(tile: MapTile, skip_explosion: bool = false) -> void:
		self.presented_destructions.append([tile, skip_explosion])


func test_source_explicit_interaction_does_not_refresh_contextual_selection() -> void:
	var board := FakeBoard.new()
	var source := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var attacker := BaseUnit.new()
	var defender := BaseUnit.new()
	source.unit.set_tile(attacker)
	target.unit.set_tile(defender)

	board.handle_interaction_from_tile(source, target)

	assert_eq(board.battle_calls, [[source, target]])
	assert_eq((board.board_model as FakeBoard.FakeBoardModel).used_ap, [1])
	assert_eq(board.contextual_select_count, 0)

	attacker.free()
	defender.free()
	board.free()


func test_start_turn_does_not_emit_duplicate_turn_started_event() -> void:
	var file := FileAccess.open("res://scenes/board/board.gd", FileAccess.READ)
	assert_not_null(file)
	var source := file.get_as_text()
	var start_turn_source := source.get_slice("func start_turn() -> void:", 1).get_slice("func start_initial_turn() -> void:", 0)

	assert_eq(start_turn_source.find("emit_turn_started"), -1)


func test_destroy_unit_on_tile_routes_through_board_model_and_preserves_presentation() -> void:
	var board := FakeBoard.new()
	var tile := MapTile.new(0, 0)
	var attacker := BaseUnit.new()
	var defender := BaseUnit.new()
	tile.unit.set_tile(defender)

	board.destroy_unit_on_tile(tile, false, attacker)

	assert_eq(board.presented_destructions, [[tile, false]])
	assert_eq((board.board_model as FakeBoard.FakeBoardModel).destroy_calls, [[tile, attacker]])
	assert_eq((board.board_model as FakeBoard.FakeBoardModel).fake_unit_lifecycle_commands.destroy_calls.size(), 0)

	attacker.free()
	defender.free()
	board.free()


func test_direct_damage_abilities_do_not_manually_emit_unit_destroyed_events() -> void:
	for path: String in [
		"res://scenes/abilities/unit/heavy_weapon.gd",
		"res://scenes/abilities/unit/long_range_shell.gd",
		"res://scenes/abilities/unit/missile.gd",
	]:
		var file := FileAccess.open(path, FileAccess.READ)
		assert_not_null(file)
		assert_eq(file.get_as_text().find("emit_unit_destroyed"), -1, path)
