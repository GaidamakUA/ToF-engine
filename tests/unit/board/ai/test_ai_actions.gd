extends GutTest


class FakeAi:
	var reserved_amounts: Array[int] = []

	func reserve_ap(amount: int) -> void:
		self.reserved_amounts.append(amount)


class FakeBoardHost:
	var ai := FakeAi.new()
	var selected_tile: MapTile = null
	var moved_pairs: Array[Array] = []
	var path_moves: Array[Array] = []
	var interaction_pairs: Array[Array] = []
	var capture_pairs: Array[Array] = []
	var select_tile_count: int = 0
	var unselect_tile_count: int = 0

	func move_unit(source_tile: MapTile, destination_tile: MapTile) -> void:
		self.moved_pairs.append([source_tile, destination_tile])

	func move_unit_along_path(source_tile: MapTile, destination_tile: MapTile, move_cost: int, movement_path: Array[String]) -> void:
		self.path_moves.append([source_tile, destination_tile, move_cost, movement_path])

	func handle_interaction_from_tile(source_tile: MapTile, target_tile: MapTile) -> void:
		self.interaction_pairs.append([source_tile, target_tile])

	func _present_capture_result(_result: CommandResult) -> void:
		pass

	func _activate_ability(_ability: Ability) -> void:
		pass

	func _activate_production_ability(_ability: Ability) -> void:
		pass

	func select_tile(_position: Vector2i) -> void:
		self.select_tile_count += 1

	func unselect_tile() -> void:
		self.unselect_tile_count += 1


func _make_model(board: FakeBoardHost) -> BoardModel:
	var model := BoardModel.new()
	model.add_player({
		"type": State.PLAYER_HUMAN,
		"side": "blue",
		"alive": true,
		"team": 0,
		"ap": 5,
	})
	model.board = board
	model.set_map_model(MapModel.new())
	model.abilities = Abilities.new(model.state)
	model._rebuild_command_context()
	return model


func _place_unit(tile: MapTile) -> BaseUnit:
	var unit := BaseUnit.new()
	unit.side = "blue"
	unit.team = 0
	unit.move = 5
	unit.max_move = 5
	tile.unit.set_tile(unit)
	return unit


func _add_walkable_ground(tile: MapTile) -> BaseTile:
	var ground := BaseTile.new()
	tile.ground.set_tile(ground)
	return ground


func _free_ground(tile: MapTile, ground: BaseTile) -> void:
	tile.ground.release()
	ground.free()


class TrackingAbility:
	extends ActiveUnitAbility

	var executed_position := Vector2i(-1, -1)

	func _execute_model(_model: BoardModel, _source: Variant, _origin_tile: MapTile, position: Vector2i) -> CommandResult:
		self.executed_position = position
		return CommandResult.new("tracking_ai_ability")


class FrameBlockingPacer:
	extends ActionPacer

	var steps: Array[String] = []

	func wait_after(_result: CommandResult) -> void:
		self.steps.append("started")
		await (Engine.get_main_loop() as SceneTree).process_frame
		self.steps.append("finished")


func test_move_action_uses_model_command_without_selection() -> void:
	var board := FakeBoardHost.new()
	var model := _make_model(board)
	var source := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var unit := _place_unit(source)
	var target_ground := _add_walkable_ground(target)
	var movement_path: Array[String] = ["1_0", "0_0"]
	var action := MoveAction.new(source, target, movement_path)

	await action.perform(model)

	assert_true(source.unit.is_present() == false)
	assert_same(target.unit.tile, unit)
	assert_true(board.path_moves.is_empty())
	assert_true(board.moved_pairs.is_empty())
	assert_eq(board.select_tile_count, 0)
	assert_eq(board.unselect_tile_count, 0)
	target.unit.release()
	_free_ground(target, target_ground)
	unit.free()


func test_attack_action_uses_model_interaction_command_without_selection() -> void:
	var board := FakeBoardHost.new()
	var model := _make_model(board)
	var source := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var attacker := _place_unit(source)
	attacker.attack = 3
	attacker.attacks = 1
	var defender := BaseUnit.new()
	defender.side = "red"
	defender.team = 1
	defender.hp = 5
	defender.max_hp = 5
	defender.armor = 0
	defender.move = 0
	defender.max_move = 0
	target.unit.set_tile(defender)
	var movement_path: Array[String] = []
	var action := AttackAction.new(source, null, target, movement_path)

	await action.perform(model)

	assert_eq(model.get_current_ap(), 4)
	assert_eq(defender.hp, 2)
	assert_true(board.interaction_pairs.is_empty())
	assert_eq(board.select_tile_count, 0)
	assert_eq(board.unselect_tile_count, 0)

	source.unit.release()
	target.unit.release()
	attacker.free()
	defender.free()


func test_attack_action_with_interaction_uses_path_move_without_selection() -> void:
	var board := FakeBoardHost.new()
	var model := _make_model(board)
	var source := MapTile.new(0, 0)
	var interaction := MapTile.new(1, 0)
	var target := MapTile.new(2, 0)
	var unit := _place_unit(source)
	unit.attack = 3
	unit.attacks = 1
	var defender := BaseUnit.new()
	defender.side = "red"
	defender.team = 1
	defender.hp = 5
	defender.max_hp = 5
	defender.armor = 0
	defender.move = 0
	defender.max_move = 0
	target.unit.set_tile(defender)
	var interaction_ground := _add_walkable_ground(interaction)
	var movement_path: Array[String] = ["1_0", "0_0"]
	var action := AttackAction.new(source, interaction, target, movement_path)

	await action.perform(model)

	assert_true(source.unit.is_present() == false)
	assert_same(interaction.unit.tile, unit)
	assert_eq(model.get_current_ap(), 3)
	assert_eq(defender.hp, 2)
	assert_true(board.path_moves.is_empty())
	assert_true(board.interaction_pairs.is_empty())
	assert_true(board.moved_pairs.is_empty())
	assert_eq(board.select_tile_count, 0)
	assert_eq(board.unselect_tile_count, 0)
	interaction.unit.release()
	target.unit.release()
	_free_ground(interaction, interaction_ground)
	unit.free()
	defender.free()


func test_capture_action_uses_model_interaction_command_without_selection() -> void:
	var board := FakeBoardHost.new()
	var model := _make_model(board)
	var source := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var unit := _place_unit(source)
	unit.can_capture = true
	var building := BaseBuilding.new()
	building.side = "red"
	building.team = 1
	building.require_crew = false
	target.building.set_tile(building)
	var movement_path: Array[String] = []
	var action := CaptureAction.new(source, null, target, movement_path)

	await action.perform(model)

	assert_eq(target.building.tile.side, "blue")
	assert_eq(target.building.tile.team, 0)
	assert_eq(model.get_current_ap(), 4)
	assert_true(board.interaction_pairs.is_empty())
	assert_eq(board.select_tile_count, 0)
	assert_eq(board.unselect_tile_count, 0)

	source.unit.release()
	target.building.release()
	unit.free()
	building.free()


func test_ability_action_uses_model_ability_command_without_selection() -> void:
	var board := FakeBoardHost.new()
	var model := _make_model(board)
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var unit := _place_unit(origin)
	var ability := TrackingAbility.new()
	ability.ap_cost = 2
	ability.cooldown = 3
	var action := UseAbilityAction.new(ability, origin, target)

	await action.perform(model)

	assert_eq(ability.executed_position, target.position)
	assert_eq(model.get_current_ap(), 3)
	assert_eq(unit.move, 4)
	assert_eq(unit.get_ability_cooldown(ability), 3)
	assert_null(board.selected_tile)
	assert_eq(board.select_tile_count, 0)
	assert_eq(board.unselect_tile_count, 0)

	origin.unit.release()
	unit.free()


func test_ability_action_awaits_action_pacer() -> void:
	var board := FakeBoardHost.new()
	var model := _make_model(board)
	var pacer := FrameBlockingPacer.new()
	model.set_action_pacer(pacer)
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var unit := _place_unit(origin)
	var ability := TrackingAbility.new()
	var action := UseAbilityAction.new(ability, origin, target)

	await action.perform(model)

	assert_eq(pacer.steps, ["started", "finished"])
	assert_eq(ability.executed_position, target.position)

	origin.unit.release()
	unit.free()


func test_reserve_ap_action_uses_model_command_without_selection() -> void:
	var board := FakeBoardHost.new()
	var model := _make_model(board)
	var action := ReserveApAction.new(3)

	action.perform(model)

	assert_eq(board.ai.reserved_amounts, [3])
	assert_eq(board.select_tile_count, 0)
	assert_eq(board.unselect_tile_count, 0)
