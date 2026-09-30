extends GutTest


func _make_model_with_players() -> BoardModel:
	var model := BoardModel.new()
	model.add_player(State.PLAYER_HUMAN, "blue", true, 0, 3)
	model.add_player(State.PLAYER_AI, "red", true, 1, 2)
	return model


func test_new_model_has_no_view_or_board_dependency() -> void:
	var model := BoardModel.new()

	assert_not_null(model.get_snapshot().match)
	assert_not_null(model.events)
	assert_not_null(model.scripting)
	assert_not_null(model.abilities)
	var property_names: Array[StringName] = []
	for property: Dictionary in model.get_property_list():
		property_names.append(StringName(property["name"]))
	assert_false(property_names.has(&"board"))


func test_ap_commands_publish_typed_snapshot() -> void:
	var model := _make_model_with_players()
	var snapshots: Array[BoardStateSnapshot] = []
	model.updated.connect(func(snapshot: BoardStateSnapshot, _events: Array[BoardDomainEvent]) -> void:
		snapshots.append(snapshot)
	)

	assert_true(model.use_current_player_ap(2))

	assert_eq(model.get_current_ap(), 1)
	assert_eq(snapshots.size(), 1)
	assert_eq(snapshots[0].match.players[0].ap, 1)


func test_rejected_ap_command_does_not_publish() -> void:
	var model := _make_model_with_players()
	var update_count: Array[int] = [0]
	model.updated.connect(func(_snapshot: BoardStateSnapshot, _events: Array[BoardDomainEvent]) -> void:
		update_count[0] += 1
	)

	assert_false(model.use_current_player_ap(4))

	assert_eq(model.get_current_ap(), 3)
	assert_eq(update_count[0], 0)


func test_end_turn_publishes_new_current_player() -> void:
	var model := _make_model_with_players()
	var snapshots: Array[BoardStateSnapshot] = []
	model.updated.connect(func(new_snapshot: BoardStateSnapshot, _events: Array[BoardDomainEvent]) -> void:
		snapshots.append(new_snapshot)
	)

	assert_true(model.end_turn())

	assert_eq(snapshots[0].match.current_player, 1)
	assert_eq(snapshots[0].match.turn, 1)


func test_turn_limit_is_resolved_by_model() -> void:
	var model := _make_model_with_players()
	model.turn_limit = 1
	var emissions: Array[Array] = []
	model.updated.connect(func(_snapshot: BoardStateSnapshot, events: Array[BoardDomainEvent]) -> void:
		emissions.append(events)
	)

	assert_true(model.end_turn())
	assert_true(model.end_turn())

	assert_eq(model.get_snapshot().scenario.winner, "none")
	assert_true(emissions[-1].any(func(event: BoardDomainEvent) -> bool:
		return event is EndGamePresentationEvent
	))
