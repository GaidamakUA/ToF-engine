extends GutTest


func _make_state() -> State:
    var state := State.new()
    state.add_player(State.PLAYER_HUMAN, "blue", true, 0)
    state.add_player(State.PLAYER_AI, "red", true, 1)
    state.add_player(State.PLAYER_HUMAN, "green", true, 0)
    return state


func test_add_player_ap_clamps_to_upper_limit() -> void:
    var state := _make_state()

    state.add_player_ap(0, 1000)

    assert_eq(state.get_player_ap(0), 999)


func test_add_player_ap_clamps_to_zero() -> void:
    var state := _make_state()

    state.add_player_ap(0, -5)

    assert_eq(state.get_player_ap(0), 0)


func test_use_player_ap_clamps_to_zero_and_marks_player_moved() -> void:
    var state := _make_state()
    state.add_player_ap(0, 2)

    state.use_player_ap(0, 5)

    assert_eq(state.get_player_ap(0), 0)
    assert_true(state.has_player_moved)


func test_switch_to_next_player_advances_current_player() -> void:
    var state := _make_state()

    state.switch_to_next_player()

    assert_eq(state.current_player, 1)
    assert_eq(state.turn, 1)
    assert_false(state.has_player_moved)


func test_switch_to_next_player_wraps_and_increments_turn() -> void:
    var state := _make_state()
    state.current_player = 2

    state.switch_to_next_player()

    assert_eq(state.current_player, 0)
    assert_eq(state.turn, 2)


func test_switch_to_next_player_skips_dead_players() -> void:
    var state := _make_state()
    state.eliminate_player("red")

    state.switch_to_next_player()

    assert_eq(state.get_current_side(), "green")


func test_get_player_id_and_side_by_side() -> void:
    var state := _make_state()

    assert_eq(state.get_player_id_by_side("red"), 1)
    assert_eq(state.get_player_side_by_id(2), "green")


func test_get_player_team_uses_explicit_team_or_player_index() -> void:
    var state := State.new()
    state.add_player(State.PLAYER_HUMAN, "blue")
    state.add_player(State.PLAYER_AI, "red", true, 5)

    assert_eq(state.get_player_team("blue"), 0)
    assert_eq(state.get_player_team("red"), 5)
