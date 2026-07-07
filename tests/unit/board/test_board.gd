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
		var attack_calls: Array[Array] = []
		var cheat_capture_calls: Array[MapTile] = []
		var ability_calls: Array[Array] = []
		var next_ability_result: CommandResult = null
		var fake_unit_lifecycle_commands := FakeUnitLifecycleCommands.new()

		func _init() -> void:
			self.unit_lifecycle_commands = self.fake_unit_lifecycle_commands

		func use_current_player_ap(value: int) -> CommandResult:
			self.used_ap.append(value)
			return CommandResult.new("use_current_player_ap")

		func destroy_unit_on_tile(tile: MapTile, attacker: BaseUnit = null) -> CommandResult:
			self.destroy_calls.append([tile, attacker])
			return CommandResult.new("destroy_unit")

		func attack_unit(source_tile: MapTile, target_tile: MapTile) -> CommandResult:
			self.attack_calls.append([source_tile, target_tile])
			return CommandResult.new("attack_unit")

		func cheat_capture_building(target_tile: MapTile) -> CommandResult:
			self.cheat_capture_calls.append(target_tile)
			return CommandResult.new("capture_building")

		func use_ability(origin_tile: MapTile, ability: Ability, target_tile: MapTile) -> CommandResult:
			self.ability_calls.append([origin_tile, ability, target_tile])
			return self.next_ability_result

	var contextual_select_count: int = 0
	var presented_attack_results: Array[CommandResult] = []
	var presented_destructions: Array[Array] = []
	var presented_capture_results: Array[CommandResult] = []
	var smoked_tiles: Array[MapTile] = []
	var unselect_count: int = 0
	var cancel_ability_count: int = 0
	var selected_positions: Array[Vector2i] = []
	var presented_ability_results: Array[CommandResult] = []

	func _init() -> void:
		super()
		self.board_model = FakeBoardModel.new()

	func _update_ap_spent_presentation() -> void:
		pass

	func _present_attack_result(result: CommandResult) -> void:
		self.presented_attack_results.append(result)

	func _present_capture_result(result: CommandResult) -> void:
		self.presented_capture_results.append(result)

	func smoke_a_tile(tile: MapTile) -> void:
		self.smoked_tiles.append(tile)

	func show_contextual_select(_open_unit_abilities: bool = false) -> void:
		self.contextual_select_count += 1

	func _present_unit_destruction(tile: MapTile, skip_explosion: bool = false) -> void:
		self.presented_destructions.append([tile, skip_explosion])

	func unselect_tile() -> void:
		self.unselect_count += 1

	func cancel_ability() -> void:
		self.cancel_ability_count += 1

	func select_tile(tile_position: Vector2i) -> void:
		self.selected_positions.append(tile_position)

	func _present_ability_result(result: CommandResult) -> void:
		self.presented_ability_results.append(result)


class FrameDelayingPacer:
	extends ActionPacer

	var wait_calls: Array[CommandResult] = []

	func wait_after(result: CommandResult) -> void:
		self.wait_calls.append(result)
		await (Engine.get_main_loop() as SceneTree).process_frame


func test_source_explicit_interaction_does_not_refresh_contextual_selection() -> void:
	var board := FakeBoard.new()
	var source := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var attacker := BaseUnit.new()
	var defender := BaseUnit.new()
	source.unit.set_tile(attacker)
	target.unit.set_tile(defender)

	board.handle_interaction_from_tile(source, target)

	assert_eq((board.board_model as FakeBoard.FakeBoardModel).attack_calls, [[source, target]])
	assert_true((board.board_model as FakeBoard.FakeBoardModel).used_ap.is_empty())
	assert_eq(board.presented_attack_results.size(), 1)
	assert_eq(board.presented_attack_results[0].command_name, "attack_unit")
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


func test_capture_result_presentation_defers_retaliation_cleanup_in_board() -> void:
	var file := FileAccess.open("res://scenes/board/board.gd", FileAccess.READ)
	assert_not_null(file)
	var source := file.get_as_text()
	var capture_result_source := source.get_slice("func _present_capture_result(result: CommandResult) -> void:", 1).get_slice("func _present_building_captured(event: BuildingCapturedEvent) -> void:", 0)

	assert_ne(capture_result_source.find("result.metadata.get(\"retaliation_destroyed_unit\")"), -1)
	assert_ne(capture_result_source.find("retaliation_destroyed_unit.queue_free()"), -1)


func test_execute_active_ability_waits_for_pacer_before_cleanup() -> void:
	var board := FakeBoard.new()
	var pacer := FrameDelayingPacer.new()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var ability := ActiveUnitAbility.new()
	var result := CommandResult.new("use_ability")
	result.delay = 0.25
	result.metadata["select_tile_position"] = Vector2i(2, 3)
	(board.board_model as FakeBoard.FakeBoardModel).next_ability_result = result
	board.board_model.set_action_pacer(pacer)
	board.active_ability = ability
	board.active_ability_origin_tile = origin

	board.execute_active_ability(target)

	assert_eq(pacer.wait_calls, [result])
	assert_eq((board.board_model as FakeBoard.FakeBoardModel).ability_calls, [[origin, ability, target]])
	assert_eq(board.cancel_ability_count, 0)
	assert_eq(board.selected_positions.size(), 0)
	assert_eq(board.presented_ability_results, [result])

	await wait_process_frames(1)

	assert_eq(board.cancel_ability_count, 1)
	assert_eq(board.selected_positions, [Vector2i(2, 3)])

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


func test_cheat_capture_routes_through_board_model() -> void:
	var board := FakeBoard.new()
	board.map = Map.new()
	board.map.model = MapModel.new()
	board.map.tile_box_position = Vector2i(3, 4)
	var tile := MapTile.new(3, 4)
	var building := BaseBuilding.new()
	tile.building.set_tile(building)
	board.map.model.tiles["3_4"] = tile

	board.cheat_capture()

	assert_eq((board.board_model as FakeBoard.FakeBoardModel).cheat_capture_calls, [tile])
	assert_eq(board.presented_capture_results.size(), 1)
	assert_eq(board.presented_capture_results[0].command_name, "capture_building")

	building.free()
	board.map.free()
	board.free()
