extends GutTest


class RecordingPacer:
	extends ActionPacer

	var results: Array[CommandResult] = []

	func wait_after(result: CommandResult) -> void:
		self.results.append(result)


class TrackingAbility:
	extends ActiveUnitAbility

	func _execute_model(_model: BoardModel, _source: Variant, _origin_tile: MapTile, _position: Vector2i) -> CommandResult:
		var result := CommandResult.new("tracking_ai_ability")
		result.delay = 0.25
		return result


class FakeAi:
	extends Ai

	var reserved_amounts: Array[int] = []

	func _init() -> void:
		pass

	func reserve_ap(amount: int) -> void:
		self.reserved_amounts.append(amount)


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
	var action := AttackAction.new(scenario.get_tile(Vector2i(0, 0)), null, scenario.get_tile(Vector2i(1, 1)), [])

	await action.perform(scenario.model)

	assert_eq(pacer.results.size(), 1)
	assert_eq(pacer.results[0].command_name, "attack_unit")

	scenario.cleanup()


func test_capture_action_waits_on_model_pacer_for_move_and_capture() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var pacer := RecordingPacer.new()
	scenario.model.set_action_pacer(pacer)
	var source: MapTile = scenario.get_tile(Vector2i(0, 0))
	var interaction: MapTile = scenario.get_tile(Vector2i(1, 0))
	var target: MapTile = scenario.get_tile(Vector2i(2, 0))
	var action := CaptureAction.new(source, interaction, target, ["0_0", "1_0"])

	await action.perform(scenario.model)

	assert_eq(pacer.results.size(), 2)
	assert_eq(pacer.results[0].command_name, "move_unit")
	assert_eq(pacer.results[1].command_name, "capture_building")

	scenario.cleanup()


func test_use_ability_action_waits_on_model_pacer() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var pacer := RecordingPacer.new()
	scenario.model.set_action_pacer(pacer)
	var ability := TrackingAbility.new()
	var action := UseAbilityAction.new(ability, scenario.get_tile(Vector2i(0, 0)), scenario.get_tile(Vector2i(2, 0)))

	await action.perform(scenario.model)

	assert_eq(pacer.results.size(), 1)
	assert_eq(pacer.results[0].command_name, "use_ability")

	scenario.cleanup()


func test_reserve_ap_action_does_not_wait_on_model_pacer() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var pacer := RecordingPacer.new()
	var fake_ai := FakeAi.new()
	scenario.model.set_action_pacer(pacer)
	scenario.model.ai = fake_ai
	var action := ReserveApAction.new(2)

	action.perform(scenario.model)

	assert_eq(pacer.results.size(), 0)
	assert_eq(fake_ai.reserved_amounts, [2])

	scenario.cleanup()
