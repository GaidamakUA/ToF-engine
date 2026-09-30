extends GutTest


class DamageOutcome extends BaseOutcome:
	var position: Vector2i
	var amount: int

	func _init(target_position: Vector2i, damage: int) -> void:
		self.position = target_position
		self.amount = damage

	func _execute(_metadata: Dictionary[String, Variant]) -> void:
		self.model.damage_unit(self.position, self.amount, true)


class FakeBoardView:
	signal presentation_finished
	signal command_impact

	var interaction_render_count: int = 0
	var model_updates: Array[BoardStateSnapshot] = []
	var contextual_selects: Array[bool] = []
	var clear_selection_count: int = 0
	var feedback_count: int = 0
	var auto_impact: bool = true

	func render_interaction(_presenter: BoardPresenter) -> void:
		self.interaction_render_count += 1

	func present_command_lead_in(_command: BoardCommand) -> void:
		if self.auto_impact:
			self.command_impact.emit()

	func present_model_update(
		snapshot: BoardStateSnapshot,
		_events: Array[BoardDomainEvent],
		_command: BoardCommand = null
	) -> void:
		self.model_updates.append(snapshot)

	func show_contextual_select(open_abilities: bool) -> void:
		self.contextual_selects.append(open_abilities)

	func clear_selection_view() -> void:
		self.clear_selection_count += 1

	func clear_ability_view() -> void:
		pass

	func hover_tile() -> void:
		pass

	func play_tile_selected_feedback() -> void:
		self.feedback_count += 1

	func finish_presentation() -> void:
		self.presentation_finished.emit()

	func reach_impact() -> void:
		self.command_impact.emit()


func test_presenter_owns_selection_hover_and_targeting() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var presenter := BoardPresenter.new(scenario.model, FakeBoardView.new())
	var ability := Ability.new()
	ability.index = 3
	scenario.get_tile(Vector2i.ZERO).unit.tile.active_abilities.append(ability)
	presenter.select_position(Vector2i.ZERO)
	presenter.set_hover(Vector2i(1, 0))
	presenter.start_targeting(Vector2i.ZERO, ability)

	assert_eq(presenter.selected_position, Vector2i.ZERO)
	assert_eq(presenter.hovered_position, Vector2i(1, 0))
	assert_same(presenter.active_ability, ability)
	presenter.cancel_targeting()
	assert_null(presenter.active_ability)
	scenario.cleanup()


func test_presenter_translates_selection_and_move_controls() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var view := FakeBoardView.new()
	var presenter := BoardPresenter.new(scenario.model, view)

	presenter.press_tile(Vector2i(0, 0))
	presenter.press_tile(Vector2i(1, 0))
	view.finish_presentation()

	assert_eq(view.contextual_selects, [false, false])
	assert_eq(view.feedback_count, 2)
	assert_eq(view.model_updates.size(), 1)
	assert_true(scenario.get_tile(Vector2i(1, 0)).unit.is_present())
	assert_eq(presenter.selected_position, Vector2i(1, 0))
	scenario.cleanup()


func test_presenter_queues_model_updates_until_view_finishes() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var view := FakeBoardView.new()
	var _presenter := BoardPresenter.new(scenario.model, view)

	scenario.model.publish_state()
	scenario.model.publish_state()
	assert_eq(view.model_updates.size(), 1)

	view.finish_presentation()
	assert_eq(view.model_updates.size(), 2)
	scenario.cleanup()


func test_presenter_commits_model_only_at_visual_impact() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var view := FakeBoardView.new()
	view.auto_impact = false
	var presenter := BoardPresenter.new(scenario.model, view)

	assert_true(scenario.model.move_unit(Vector2i.ZERO, Vector2i(1, 0)))
	assert_true(scenario.get_tile(Vector2i.ZERO).unit.is_present())
	assert_false(scenario.get_tile(Vector2i(1, 0)).unit.is_present())

	view.reach_impact()
	assert_false(scenario.get_tile(Vector2i.ZERO).unit.is_present())
	assert_true(scenario.get_tile(Vector2i(1, 0)).unit.is_present())
	assert_eq(view.model_updates.size(), 1)
	view.finish_presentation()
	scenario.cleanup()


func test_projectile_damage_commits_only_at_visual_impact() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var source: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var target: BaseUnit = scenario.place_unit(Vector2i(1, 0), "red", 1)
	var ability := load("res://resources/abilities/unit/heavy_weapon.tres") as Ability
	source.active_abilities.append(ability)
	scenario.model.random_collateral_enabled = false
	var view := FakeBoardView.new()
	view.auto_impact = false
	var _presenter := BoardPresenter.new(scenario.model, view)
	var initial_hp: int = target.hp

	assert_true(scenario.model.scripted_use_ability(
		Vector2i.ZERO, ability.get_key(), Vector2i(1, 0)
	))
	assert_eq(target.hp, initial_hp)

	view.reach_impact()
	assert_lt(target.hp, initial_hp)
	view.finish_presentation()
	scenario.cleanup()


func test_healing_commits_when_its_visual_effect_starts() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var source: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var target: BaseUnit = scenario.place_unit(Vector2i(1, 0), "blue", 0)
	var ability := load("res://resources/abilities/unit/medkit.tres") as Ability
	source.active_abilities.append(ability)
	target.state.receive_direct_damage(5)
	var view := FakeBoardView.new()
	view.auto_impact = false
	var _presenter := BoardPresenter.new(scenario.model, view)
	var damaged_hp: int = target.hp

	assert_true(scenario.model.scripted_use_ability(
		Vector2i.ZERO, ability.get_key(), Vector2i(1, 0)
	))
	assert_eq(target.hp, damaged_hp)

	view.reach_impact()
	assert_gt(target.hp, damaged_hp)
	view.finish_presentation()
	scenario.cleanup()


func test_drop_off_moves_passenger_in_model_at_visual_impact() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var carrier: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var passenger: BaseUnit = scenario.place_unit(Vector2i(1, 0), "blue", 0)
	var ability := load("res://resources/abilities/unit/drop_off.tres") as Ability
	carrier.active_abilities.append(ability)
	carrier.passenger = passenger
	scenario.get_tile(Vector2i(1, 0)).unit.release()
	var view := FakeBoardView.new()
	view.auto_impact = false
	var _presenter := BoardPresenter.new(scenario.model, view)

	assert_true(scenario.model.scripted_use_ability(
		Vector2i.ZERO, ability.get_key(), Vector2i(1, 0)
	))
	assert_same(carrier.passenger, passenger)
	assert_false(scenario.get_tile(Vector2i(1, 0)).unit.is_present())

	view.reach_impact()
	assert_null(carrier.passenger)
	assert_same(scenario.get_tile(Vector2i(1, 0)).unit.tile, passenger)
	view.finish_presentation()
	scenario.cleanup()


func test_story_submits_only_one_step_after_each_presentation() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var view := FakeBoardView.new()
	var _presenter := BoardPresenter.new(scenario.model, view)
	var story := StoryOutcome.new()
	story.model = scenario.model
	var first := DamageOutcome.new(Vector2i.ZERO, 1)
	first.model = scenario.model
	var second := DamageOutcome.new(Vector2i.ZERO, 1)
	second.model = scenario.model
	story.add_step(first)
	story.add_step(second)
	var unit: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var initial_hp: int = unit.hp

	story.execute()
	assert_eq(unit.hp, initial_hp)

	view.finish_presentation()
	assert_eq(unit.hp, initial_hp - 1)
	view.finish_presentation()
	assert_eq(unit.hp, initial_hp - 2)
	view.finish_presentation()
	view.finish_presentation()
	scenario.cleanup()


func test_presenter_blocks_commands_while_presenting() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var view := FakeBoardView.new()
	var presenter := BoardPresenter.new(scenario.model, view)

	assert_true(scenario.model.use_current_player_ap(1))
	assert_true(presenter.is_presenting())
	presenter.select_position(Vector2i.ZERO)

	assert_null(presenter.selected_position)
	assert_false(presenter.end_turn())
	assert_eq(scenario.model.get_current_side(), "blue")
	view.finish_presentation()
	scenario.cleanup()


func test_presenter_clears_stale_control_when_model_rejects_it() -> void:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var view := FakeBoardView.new()
	var presenter := BoardPresenter.new(scenario.model, view)
	presenter.selected_position = Vector2i.ZERO
	presenter.legal_moves = {Vector2i(2, 0): [Vector2i.ZERO, Vector2i(2, 0)]}

	presenter.press_tile(Vector2i(2, 0))

	assert_eq(view.model_updates.size(), 0)
	assert_null(presenter.selected_position)
	scenario.cleanup()
