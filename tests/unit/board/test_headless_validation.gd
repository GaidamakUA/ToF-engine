extends GutTest


const FIXTURE := "res://tests/fixtures/board/headless_validation_map.json"


func test_headless_fixture_moves_unit_without_board_scene() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var initial_snapshot: BoardStateSnapshot = scenario.model.get_snapshot()

	assert_true(scenario.model.move_unit(Vector2i(0, 0), Vector2i(1, 0)))

	assert_false(scenario.get_tile(Vector2i(0, 0)).unit.is_present())
	assert_true(scenario.get_tile(Vector2i(1, 0)).unit.is_present())
	assert_eq(scenario.model.get_current_ap(), 3)
	assert_eq(initial_snapshot.map.get_tile(Vector2i(0, 0)).unit.move, 4)
	assert_eq(initial_snapshot.map.get_tile(Vector2i(1, 0)).unit, null)
	assert_true(_contains_event_type(scenario.domain_events, UnitMovedDomainEvent))
	scenario.cleanup()


func test_headless_fixture_switches_turns() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)

	assert_true(scenario.model.end_turn())

	assert_eq(scenario.model.get_current_side(), "red")
	assert_true(scenario.model.is_current_player_ai())
	scenario.cleanup()


func test_headless_fixture_captures_building() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)

	assert_true(scenario.model.move_unit(Vector2i(0, 0), Vector2i(1, 0)))
	assert_true(scenario.model.capture_building(Vector2i(1, 0), Vector2i(2, 0)))

	var building: BaseBuilding = scenario.get_tile(Vector2i(2, 0)).building.tile
	assert_eq(building.side, "blue")
	assert_eq(building.team, 0)
	assert_eq(scenario.model.get_current_ap(), 2)
	assert_true(_contains_event_type(scenario.domain_events, BuildingCapturedDomainEvent))
	scenario.cleanup()


func test_ai_actions_call_position_based_model_commands() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var source: MapTile = scenario.get_tile(Vector2i(0, 0))
	var destination: MapTile = scenario.get_tile(Vector2i(1, 0))
	var action := MoveAction.new(source, destination, ["1_0", "0_0"])

	action.perform(scenario.model)

	assert_true(destination.unit.is_present())
	assert_eq(scenario.model.get_current_ap(), 3)
	scenario.cleanup()


func test_ai_collector_runs_without_view_or_timers() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	scenario.get_tile(Vector2i.ZERO).unit.tile.unit_class = "infantry"
	var collector := Collector.new(scenario.model)

	var action: Variant = collector.select_best_action()

	assert_not_null(action)
	assert_same(collector.model, scenario.model)
	scenario.cleanup()


func test_ai_collector_honors_model_ap_reservation() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	scenario.model.reserved_ap = scenario.model.get_current_ap()
	var collector := Collector.new(scenario.model)

	assert_null(collector.select_best_action())
	scenario.cleanup()


func test_ability_executes_headlessly_by_stable_key() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var unit: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var ability: Ability = load("res://scenes/abilities/unit/rapid_response.gd").new()
	ability.index = 8
	ability.ap_cost = 1
	unit.active_abilities.append(ability)
	unit.move = 1

	assert_true(scenario.model.use_ability(Vector2i.ZERO, ability.get_key(), Vector2i.ZERO))

	assert_eq(scenario.model.get_current_ap(), 3)
	assert_eq(unit.move, unit.get_stats_with_modifiers()["max_move"] - 1)
	assert_true(_contains_event_type(scenario.domain_events, AbilityUsedDomainEvent))
	var used_event := _last_event_of_type(scenario.domain_events, AbilityUsedDomainEvent) as AbilityUsedDomainEvent
	assert_eq(used_event.affected_positions, [Vector2i.ZERO])
	scenario.cleanup()


func test_promote_emits_animation_and_level_event_once() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var source: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var target: BaseUnit = scenario.place_unit(Vector2i(1, 0), "blue", 0)
	var ability := load("res://resources/abilities/hero/active/promote.tres") as Ability
	source.active_abilities.append(ability)

	assert_true(scenario.model.use_ability(Vector2i.ZERO, ability.get_key(), Vector2i(1, 0)))

	var used_event := _last_event_of_type(scenario.domain_events, AbilityUsedDomainEvent) as AbilityUsedDomainEvent
	assert_eq(target.level, 1)
	assert_eq(used_event.animation, BoardAnimation.Kind.BLESS)
	assert_eq(used_event.affected_positions, [Vector2i(1, 0)])
	assert_eq(_event_count(scenario.domain_events, UnitLeveledUpDomainEvent), 1)
	scenario.cleanup()


func test_precision_strike_reports_every_affected_position() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var source: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var ability := load("res://resources/abilities/hero/active/precision_strike.tres") as Ability
	source.active_abilities.append(ability)
	scenario.model.random_collateral_enabled = false

	assert_true(scenario.model.use_ability(Vector2i.ZERO, ability.get_key(), Vector2i(1, 0)))

	var event := _last_event_of_type(scenario.domain_events, AbilityUsedDomainEvent) as AbilityUsedDomainEvent
	assert_eq(event.animation, BoardAnimation.Kind.PRECISION_STRIKE)
	assert_has(event.affected_positions, Vector2i.ZERO)
	assert_has(event.affected_positions, Vector2i(1, 0))
	assert_has(event.affected_positions, Vector2i(2, 0))
	scenario.cleanup()


func test_multi_unit_ability_reports_every_affected_position() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var source: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var first_target: BaseUnit = scenario.place_unit(Vector2i(1, 0), "blue", 0)
	var second_target: BaseUnit = scenario.place_unit(Vector2i(2, 0), "blue", 0)
	var ability := load("res://resources/abilities/hero/active/hardened_armour.tres") as Ability
	source.active_abilities.append(ability)

	assert_true(scenario.model.use_ability(Vector2i.ZERO, ability.get_key(), Vector2i.ZERO))

	var event := _last_event_of_type(scenario.domain_events, AbilityUsedDomainEvent) as AbilityUsedDomainEvent
	assert_eq(event.affected_positions, [Vector2i(1, 0), Vector2i(2, 0)])
	assert_eq(first_target.modifiers["armor"], 1)
	assert_eq(second_target.modifiers["armor"], 1)
	scenario.cleanup()


func test_experience_level_up_uses_level_domain_event() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var attacker: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	attacker.experience = attacker.EXP_PER_LEVEL - 1
	scenario.place_unit(Vector2i(1, 0), "red", 1, 3)
	scenario.model.random_collateral_enabled = false

	assert_true(scenario.model.attack_unit(Vector2i.ZERO, Vector2i(1, 0)))

	var event := _last_event_of_type(scenario.domain_events, UnitLeveledUpDomainEvent) as UnitLeveledUpDomainEvent
	assert_eq(attacker.level, 1)
	assert_eq(event.unit_id, attacker.model_id)
	assert_eq(event.position, Vector2i.ZERO)
	scenario.cleanup()


func test_scripted_level_up_uses_level_domain_event() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var outcome := LevelUpOutcome.new()
	outcome.model = scenario.model
	outcome.who = Vector2i.ZERO

	outcome.execute()

	var event := _last_event_of_type(scenario.domain_events, UnitLeveledUpDomainEvent) as UnitLeveledUpDomainEvent
	assert_eq(scenario.get_tile(Vector2i.ZERO).unit.tile.level, 1)
	assert_not_null(event)
	scenario.cleanup()


func test_scripted_ability_bypasses_player_rules_and_only_applies_requested_cooldown() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var source: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var ability := Ability.new()
	ability.index = 7
	ability.ap_cost = 99
	ability.cooldown = 3
	source.active_abilities.append(ability)
	var ability_state: AbilityState = source.get_ability_state(ability)
	ability_state.disabled = true
	ability_state.cd_turns_left = 2
	source.state.remove_moves()
	assert_true(scenario.model.end_turn())
	var current_ap: int = scenario.model.get_current_ap()
	var outcome := UseAbilityOutcome.new()
	outcome.model = scenario.model
	outcome.who = Vector2i.ZERO
	outcome.which = ability.get_key()
	outcome.where = Vector2i(2, 0)

	outcome.execute()

	assert_eq(scenario.model.get_current_ap(), current_ap)
	assert_eq(source.move, 0)
	assert_eq(ability_state.cd_turns_left, 2)
	assert_not_null(_last_event_of_type(scenario.domain_events, AbilityUsedDomainEvent))

	outcome.cooldown = true
	outcome.execute()
	assert_eq(ability_state.cd_turns_left, 3)
	scenario.cleanup()


func test_scripted_move_preserves_explicit_route() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	scenario.get_tile(Vector2i(2, 0)).building.release()
	var outcome := MoveOutcome.new()
	outcome.model = scenario.model
	outcome.who = Vector2i.ZERO
	outcome.where = Vector2i(2, 0)
	outcome.path.assign(["e", "e", "w"])

	outcome.execute()

	var event := _last_event_of_type(scenario.domain_events, UnitMovedDomainEvent) as UnitMovedDomainEvent
	assert_true(scenario.get_tile(Vector2i(2, 0)).unit.is_present())
	assert_eq(event.path, [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)])
	assert_eq(event.directions, ["e", "e", "w"])
	scenario.cleanup()


func test_teleport_move_does_not_invent_a_non_adjacent_path() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	scenario.get_tile(Vector2i(2, 0)).building.release()

	assert_true(scenario.model.relocate_unit(Vector2i.ZERO, Vector2i(2, 0)))

	var event := _last_event_of_type(scenario.domain_events, UnitMovedDomainEvent) as UnitMovedDomainEvent
	assert_eq(event.path, [Vector2i.ZERO])
	scenario.cleanup()


func test_destroy_story_can_despawn_victim_before_level_up() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var attacker: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var victim: BaseUnit = scenario.place_unit(Vector2i(1, 0), "red", 1, 1)
	victim.template_name = "red_infantry"
	var despawn := DespawnOutcome.new()
	despawn.model = scenario.model
	despawn.fields.assign([{"x1": 1, "x2": 1, "y1": 0, "y2": 0}])
	var level_up := LevelUpOutcome.new()
	level_up.model = scenario.model
	level_up.who = Vector2i.ZERO
	var story := StoryOutcome.new()
	story.model = scenario.model
	story.add_step(despawn)
	story.add_step(level_up)
	var trigger := AssassinationTrigger.new()
	trigger.model = scenario.model
	trigger.unit_type = victim.template_name
	trigger.one_off = true
	trigger.outcome = story
	scenario.model.events.register_observer(trigger)

	assert_true(scenario.model.destroy_unit(Vector2i(1, 0), attacker.model_id, false))

	assert_false(scenario.get_tile(Vector2i(1, 0)).unit.is_present())
	assert_eq(attacker.level, 1)
	assert_eq(_event_count(scenario.domain_events, UnitDestroyedDomainEvent), 1)
	assert_eq(_event_count(scenario.domain_events, UnitLeveledUpDomainEvent), 1)
	scenario.cleanup()


func test_destroyed_unit_leaves_model_and_view_on_commit() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var tile: MapTile = scenario.get_tile(Vector2i.ZERO)
	var headless_unit: BaseUnit = tile.unit.tile
	tile.unit.release()
	headless_unit.free()
	var unit := scenario.model.templates.get_template("blue_infantry") as BaseUnit
	tile.unit.set_tile(unit)
	scenario.model.set_map_model(scenario.map_model)
	self.add_child(unit)

	assert_true(scenario.model.destroy_unit(Vector2i.ZERO, 0, false))

	var event := _last_event_of_type(scenario.domain_events, UnitDestroyedDomainEvent) as UnitDestroyedDomainEvent
	assert_false(scenario.get_tile(Vector2i.ZERO).unit.is_present())
	assert_true(unit.is_queued_for_deletion())
	assert_eq(event.unit_id, unit.model_id)
	await wait_process_frames(1)
	assert_false(is_instance_valid(unit))
	scenario.cleanup()


func test_story_publishes_delays_between_presentation_steps() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	scenario.domain_events.clear()
	var focus := CameraOutcome.new()
	focus.model = scenario.model
	focus.where = Vector2i(2, 0)
	focus.delay = 0.5
	var first_message := MessageOutcome.new()
	first_message.model = scenario.model
	first_message.text = "first"
	var second_message := MessageOutcome.new()
	second_message.model = scenario.model
	second_message.text = "second"
	var story := StoryOutcome.new()
	story.model = scenario.model
	story.add_step(focus)
	story.add_step(first_message)
	story.add_step(second_message)

	story.execute()

	var presentations: Array[ScriptPresentationEvent] = []
	for event: BoardDomainEvent in scenario.domain_events:
		if event is ScriptPresentationEvent:
			presentations.append(event as ScriptPresentationEvent)
	assert_eq(presentations.size(), 6)
	assert_true(presentations[0] is LockPresentationEvent)
	assert_true(presentations[1] is FocusPresentationEvent)
	assert_true(presentations[2] is DelayPresentationEvent)
	assert_true(presentations[3] is MessagePresentationEvent)
	assert_true(presentations[4] is MessagePresentationEvent)
	assert_true(presentations[5] is LockPresentationEvent)
	var opening_lock := presentations[0] as LockPresentationEvent
	var closing_lock := presentations[5] as LockPresentationEvent
	assert_eq(opening_lock.target, LockPresentationEvent.Target.STORY)
	assert_true(opening_lock.locked)
	assert_eq((presentations[2] as DelayPresentationEvent).duration, 0.5)
	assert_eq(closing_lock.target, LockPresentationEvent.Target.STORY)
	assert_false(closing_lock.locked)
	scenario.cleanup()


func test_production_ability_spawns_unit_headlessly() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var building: BaseBuilding = scenario.get_tile(Vector2i(2, 0)).building.tile
	building.side = "blue"
	building.team = 0
	var ability := SpawnUnit.new()
	ability.index = 2
	ability.ap_cost = 1
	ability.template_name = "blue_infantry"
	building.abilities.append(ability)

	assert_true(scenario.model.use_ability(Vector2i(2, 0), ability.get_key(), Vector2i(1, 0)))

	var spawned: BaseUnit = scenario.get_tile(Vector2i(1, 0)).unit.tile
	var spawn_event := _last_event_of_type(scenario.domain_events, UnitSpawnedDomainEvent) as UnitSpawnedDomainEvent
	assert_not_null(spawned)
	assert_gt(spawned.model_id, 0)
	assert_eq(spawn_event.unit_id, spawned.model_id)
	assert_true(scenario.model.destroy_unit(Vector2i(1, 0), 0, false))
	scenario.cleanup()


func test_drop_off_places_the_existing_passenger_without_a_fake_spawn() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var carrier: BaseUnit = scenario.get_tile(Vector2i.ZERO).unit.tile
	var passenger: BaseUnit = scenario.place_unit(Vector2i(1, 0), "blue", 0)
	var ability := load("res://resources/abilities/unit/drop_off.tres") as Ability
	carrier.active_abilities.append(ability)
	carrier.passenger = passenger
	scenario.get_tile(Vector2i(1, 0)).unit.release()
	scenario.domain_events.clear()

	assert_true(scenario.model.use_ability(Vector2i.ZERO, ability.get_key(), Vector2i(1, 0)))

	var event := _last_event_of_type(scenario.domain_events, UnitSpawnedDomainEvent) as UnitSpawnedDomainEvent
	assert_same(scenario.get_tile(Vector2i(1, 0)).unit.tile, passenger)
	assert_null(event)
	scenario.cleanup()


func test_snapshot_collections_are_detached() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var snapshot: BoardStateSnapshot = scenario.model.get_snapshot()
	var players: Array[PlayerStateSnapshot] = snapshot.match.players
	var tiles: Dictionary[Vector2i, TileStateSnapshot] = snapshot.map.tiles
	players.clear()
	tiles.clear()

	var fresh_snapshot: BoardStateSnapshot = scenario.model.get_snapshot()
	assert_eq(fresh_snapshot.match.players.size(), 2)
	assert_gt(fresh_snapshot.map.tiles.size(), 0)
	scenario.cleanup()


func test_snapshot_keeps_modified_empty_tiles() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var position := Vector2i(10, 10)
	var tile: MapTile = scenario.get_tile(position)
	assert_false(tile.has_content())
	tile.is_state_modified = true

	var snapshot: BoardStateSnapshot = scenario.model.get_snapshot()
	var save_data: Dictionary[String, Variant] = BoardStateSerializer.to_save_data(snapshot)

	assert_true(snapshot.map.tiles.has(position))
	assert_true(save_data["tiles"].has("10_10"))
	assert_null(save_data["tiles"]["10_10"]["ground"]["tile"])
	scenario.cleanup()


func test_combat_and_destruction_are_headless_typed_events() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	scenario.place_unit(Vector2i(1, 0), "red", 1, 3)
	scenario.model.random_collateral_enabled = false

	assert_true(scenario.model.attack_unit(Vector2i(0, 0), Vector2i(1, 0)))

	assert_false(scenario.get_tile(Vector2i(1, 0)).unit.is_present())
	assert_true(_contains_event_type(scenario.domain_events, AttackResolvedEvent))
	assert_true(_contains_event_type(scenario.domain_events, UnitDestroyedDomainEvent))
	scenario.cleanup()


func test_undo_restores_position_actions_and_ap() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var unit: BaseUnit = scenario.get_tile(Vector2i(0, 0)).unit.tile

	assert_true(scenario.model.move_unit(Vector2i(0, 0), Vector2i(1, 0)))
	assert_true(scenario.model.undo_last_move())

	assert_same(scenario.get_tile(Vector2i(0, 0)).unit.tile, unit)
	assert_eq(unit.move, 4)
	assert_eq(scenario.model.get_current_ap(), 4)
	scenario.cleanup()


func test_undo_reverses_the_original_route() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	scenario.get_tile(Vector2i(2, 0)).building.release()

	assert_true(scenario.model.move_unit(Vector2i.ZERO, Vector2i(2, 0)))
	assert_true(scenario.model.undo_last_move())

	var event := _last_event_of_type(scenario.domain_events, UnitMovedDomainEvent) as UnitMovedDomainEvent
	assert_eq(event.path, [Vector2i(2, 0), Vector2i(1, 0), Vector2i.ZERO])
	scenario.cleanup()


func test_undo_does_not_cross_turn_boundaries() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	assert_true(scenario.model.move_unit(Vector2i.ZERO, Vector2i(1, 0)))
	assert_true(scenario.model.end_turn())
	var next_player_ap: int = scenario.model.get_current_ap()

	assert_false(scenario.model.undo_last_move())

	assert_true(scenario.get_tile(Vector2i(1, 0)).unit.is_present())
	assert_eq(scenario.model.get_current_ap(), next_player_ap)
	scenario.cleanup()


func test_ai_moves_are_not_undoable() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	scenario.get_tile(Vector2i.ZERO).unit.release()
	scenario.place_unit(Vector2i.ZERO, "red", 1)
	assert_true(scenario.model.end_turn())

	assert_true(scenario.model.move_unit(Vector2i.ZERO, Vector2i(1, 0)))
	assert_false(scenario.model.undo_last_move())

	assert_true(scenario.get_tile(Vector2i(1, 0)).unit.is_present())
	scenario.cleanup()


func test_save_adapter_serializes_snapshot_without_nodes() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var snapshot: BoardStateSnapshot = scenario.model.get_snapshot()
	var save_data: Dictionary[String, Variant] = BoardStateSerializer.to_save_data(snapshot)
	var unit_data: Dictionary = save_data["tiles"]["0_0"]["unit"]

	assert_eq(int(unit_data["id"]), snapshot.map.get_tile(Vector2i.ZERO).unit.id)
	assert_eq(unit_data["side"], "blue")
	for value: Variant in unit_data.values():
		assert_false(value is Node)
	scenario.cleanup()


func test_save_adapter_serializes_disabled_hero_abilities() -> void:
	var stats: Dictionary[String, int] = {}
	var modifiers: Dictionary[String, Variant] = {}
	var tags: Dictionary[String, Variant] = {}
	var abilities: Array[AbilityStateSnapshot] = []
	var unit := UnitStateSnapshot.new(
		1, "hero_captain", 0, "blue", 0, stats, false, modifiers, tags, abilities, true
	)

	var data: Dictionary[String, Variant] = BoardStateSerializer._unit_to_dictionary(unit)

	assert_true(data["disable_active_abilities"])


func test_match_state_serialization_round_trip() -> void:
	var scenario := HeadlessBoardScenario.from_fixture(self.FIXTURE)
	var original: MatchStateSnapshot = scenario.model.get_snapshot().match
	var restored: MatchStateSnapshot = BoardStateSerializer.match_from_save_data(
		BoardStateSerializer.to_save_data(scenario.model.get_snapshot())
	)

	assert_eq(restored.current_player, original.current_player)
	assert_eq(restored.turn, original.turn)
	assert_eq(restored.players.size(), original.players.size())
	assert_eq(restored.players[0].side, original.players[0].side)
	assert_eq(restored.players[0].ap, original.players[0].ap)
	scenario.cleanup()


func _contains_event_type(events: Array[BoardDomainEvent], event_type: Resource) -> bool:
	for event: BoardDomainEvent in events:
		if is_instance_of(event, event_type):
			return true
	return false


func _last_event_of_type(events: Array[BoardDomainEvent], event_type: Resource) -> BoardDomainEvent:
	for index: int in range(events.size() - 1, -1, -1):
		if is_instance_of(events[index], event_type):
			return events[index]
	return null


func _event_count(events: Array[BoardDomainEvent], event_type: Resource) -> int:
	var count: int = 0
	for event: BoardDomainEvent in events:
		if is_instance_of(event, event_type):
			count += 1
	return count
