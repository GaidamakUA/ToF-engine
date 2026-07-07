extends GutTest


class FakeAi:
	extends Ai

	var reserved_amounts: Array[int] = []

	func _init() -> void:
		pass

	func reserve_ap(amount: int) -> void:
		self.reserved_amounts.append(amount)


class PresentingBoardModel:
	extends BoardModel

	var presented_results: Array[CommandResult] = []
	var next_result := CommandResult.new("use_ability")

	func use_ability(_origin_tile: MapTile, _ability: Ability, _target_tile: MapTile) -> CommandResult:
		return self.next_result

	func present_action_result(result: CommandResult) -> void:
		self.presented_results.append(result)


class FinishTrackingBoardModel:
	extends BoardModel

	var end_turn_calls: int = 0

	func end_turn() -> CommandResult:
		self.end_turn_calls += 1
		return CommandResult.new("end_turn")


class FinishTrackingBoard:
	extends Board

	var board_end_turn_calls: int = 0
	var scheduled_results: Array[CommandResult] = []

	func _init() -> void:
		super()
		self.board_model = FinishTrackingBoardModel.new()

	func end_turn() -> void:
		self.board_end_turn_calls += 1

	func schedule_turn_start(result: CommandResult = null) -> void:
		self.scheduled_results.append(result)

func _make_model(fake_ai: FakeAi = null) -> BoardModel:
	var model := BoardModel.new()
	model.add_player({
		"type": State.PLAYER_HUMAN,
		"side": "blue",
		"alive": true,
		"team": 0,
		"ap": 5,
	})
	model.set_map_model(MapModel.new())
	model.abilities = Abilities.new(model.state)
	model.ai = fake_ai
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
	var model := _make_model()
	var source := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var unit := _place_unit(source)
	var target_ground := _add_walkable_ground(target)
	var movement_path: Array[String] = ["1_0", "0_0"]
	var action := MoveAction.new(source, target, movement_path)

	await action.perform(model)

	assert_true(source.unit.is_present() == false)
	assert_same(target.unit.tile, unit)
	target.unit.release()
	_free_ground(target, target_ground)
	unit.free()


func test_attack_action_uses_model_interaction_command_without_selection() -> void:
	var model := _make_model()
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

	source.unit.release()
	target.unit.release()
	attacker.free()
	defender.free()


func test_attack_action_with_interaction_uses_path_move_without_selection() -> void:
	var model := _make_model()
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
	interaction.unit.release()
	target.unit.release()
	_free_ground(interaction, interaction_ground)
	unit.free()
	defender.free()


func test_capture_action_uses_model_interaction_command_without_selection() -> void:
	var model := _make_model()
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

	source.unit.release()
	target.building.release()
	unit.free()
	building.free()


func test_ability_action_uses_model_ability_command_without_selection() -> void:
	var model := _make_model()
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

	origin.unit.release()
	unit.free()


func test_ability_action_awaits_action_pacer() -> void:
	var model := _make_model()
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


func test_ability_action_routes_successful_results_through_model_presentation() -> void:
	var model := PresentingBoardModel.new()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var ability := TrackingAbility.new()
	var action := UseAbilityAction.new(ability, origin, target)

	await action.perform(model)

	assert_eq(model.presented_results, [model.next_result])


func test_ai_finish_run_uses_board_model_for_end_turn_and_only_board_for_scheduling() -> void:
	var board := FinishTrackingBoard.new()
	var ai := Ai.new(board)

	ai._finish_run()

	assert_eq((board.board_model as FinishTrackingBoardModel).end_turn_calls, 1)
	assert_eq(board.board_end_turn_calls, 0)
	assert_eq(board.scheduled_results.size(), 1)

	board.free()


func test_reserve_ap_action_uses_model_command_without_selection() -> void:
	var fake_ai := FakeAi.new()
	var model := _make_model(fake_ai)
	var action := ReserveApAction.new(3)

	action.perform(model)

	assert_eq(fake_ai.reserved_amounts, [3])
