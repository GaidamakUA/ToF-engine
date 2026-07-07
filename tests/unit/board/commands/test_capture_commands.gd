extends GutTest


class MoveTrackingUnit:
	extends BaseUnit

	var used_all_moves: bool = false

	func use_all_moves() -> void:
		self.used_all_moves = true
		super.use_all_moves()


class BuildingCapturedRecorder:
	extends Observer

	var observed_events: Array[BuildingCapturedEvent] = []

	func _init() -> void:
		super(null)
		self.observed_event_type = BuildingCapturedEvent

	func _observe(event: BaseEvent) -> void:
		self.observed_events.append(event as BuildingCapturedEvent)


class UnitDestroyedRecorder:
	extends Observer

	var observed_events: Array[UnitDestroyedEvent] = []

	func _init() -> void:
		super(null)
		self.observed_event_type = UnitDestroyedEvent

	func _observe(event: BaseEvent) -> void:
		self.observed_events.append(event as UnitDestroyedEvent)


func _make_model() -> BoardModel:
	var model := BoardModel.new()
	model.add_player({
		"type": State.PLAYER_HUMAN,
		"side": "blue",
		"alive": true,
		"team": 0,
		"ap": 4,
	})
	model.set_map_model(MapModel.new())
	model.abilities = Abilities.new(model.state)
	model._rebuild_command_context()
	return model


func test_capture_changes_building_side_spends_ap_and_emits_event() -> void:
	var model := _make_model()
	var captured_recorder := BuildingCapturedRecorder.new()
	model.events.register_observer(captured_recorder)
	var attacker_tile := MapTile.new(0, 0)
	var building_tile := MapTile.new(1, 0)
	var attacker := MoveTrackingUnit.new()
	attacker.side = "blue"
	attacker.team = 0
	attacker.can_capture = true
	attacker.move = 4
	attacker.max_move = 4
	var building := BaseBuilding.new()
	building.side = "red"
	building.team = 1
	building.require_crew = false
	attacker_tile.unit.set_tile(attacker)
	building_tile.building.set_tile(building)

	var result: CommandResult = model.capture_building(attacker_tile, building_tile)

	assert_eq(result.command_name, "capture_building")
	assert_eq(building.side, "blue")
	assert_eq(building.team, 0)
	assert_eq(model.get_current_ap(), 3)
	assert_eq(attacker.move, 0)
	assert_true(attacker.used_all_moves)
	assert_eq(result.events.size(), 2)
	assert_true(result.events[0] is ApChangedEvent)
	assert_true(result.events[1] is BuildingCapturedEvent)
	assert_eq(captured_recorder.observed_events.size(), 1)
	assert_same(result.events[1], captured_recorder.observed_events[0])
	assert_same(captured_recorder.observed_events[0].building, building)
	assert_eq(captured_recorder.observed_events[0].old_side, "red")
	assert_eq(captured_recorder.observed_events[0].new_side, "blue")

	attacker.free()
	building.free()


func test_capture_with_crew_retaliation_clears_attacker_tile_once() -> void:
	var model := _make_model()
	var captured_recorder := BuildingCapturedRecorder.new()
	var destroyed_recorder := UnitDestroyedRecorder.new()
	model.events.register_observer(captured_recorder)
	model.events.register_observer(destroyed_recorder)
	var attacker_tile := MapTile.new(0, 0)
	var building_tile := MapTile.new(1, 0)
	var attacker := MoveTrackingUnit.new()
	attacker.side = "blue"
	attacker.team = 0
	attacker.template_name = "infantry"
	attacker.can_capture = true
	attacker.move = 4
	attacker.max_move = 4
	var building := BaseBuilding.new()
	building.side = "red"
	building.team = 1
	building.require_crew = true
	attacker_tile.unit.set_tile(attacker)
	building_tile.building.set_tile(building)

	var result: CommandResult = model.capture_building(attacker_tile, building_tile)

	assert_eq(result.command_name, "capture_building")
	assert_eq(building.side, "blue")
	assert_eq(building.team, 0)
	assert_false(attacker_tile.unit.is_present())
	assert_eq(model.get_current_ap(), 3)
	assert_eq(result.events.size(), 3)
	assert_true(result.events[0] is ApChangedEvent)
	assert_true(result.events[1] is UnitDestroyedEvent)
	assert_true(result.events[2] is BuildingCapturedEvent)
	assert_eq(destroyed_recorder.observed_events.size(), 1)
	assert_eq(destroyed_recorder.observed_events[0].unit_type, "infantry")
	assert_eq(captured_recorder.observed_events.size(), 1)
	assert_same(result.events[2], captured_recorder.observed_events[0])

	attacker.free()
	building.free()


func test_capture_with_crew_retaliation_reports_deferred_cleanup_for_live_board_hosts() -> void:
	var model := _make_model()
	model.board = Board.new()
	var attacker_tile := MapTile.new(0, 0)
	var building_tile := MapTile.new(1, 0)
	var attacker := MoveTrackingUnit.new()
	attacker.side = "blue"
	attacker.team = 0
	attacker.template_name = "infantry"
	attacker.can_capture = true
	attacker.move = 4
	attacker.max_move = 4
	var building := BaseBuilding.new()
	building.side = "red"
	building.team = 1
	building.require_crew = true
	attacker_tile.unit.set_tile(attacker)
	building_tile.building.set_tile(building)

	var result: CommandResult = model.capture_building(attacker_tile, building_tile)

	assert_eq(result.command_name, "capture_building")
	assert_false(attacker_tile.unit.is_present())
	assert_same(result.metadata.get("retaliation_destroyed_unit"), attacker)
	assert_true(bool(result.metadata.get("crew_retaliated", false)))

	attacker.free()
	building.free()
	model.board.free()


func test_cheat_capture_routes_through_model_capture_without_spending_ap() -> void:
	var model := _make_model()
	var captured_recorder := BuildingCapturedRecorder.new()
	model.events.register_observer(captured_recorder)
	var building_tile := MapTile.new(1, 0)
	var building := BaseBuilding.new()
	building.side = "red"
	building.team = 1
	building_tile.building.set_tile(building)

	var result: CommandResult = model.cheat_capture_building(building_tile)

	assert_eq(result.command_name, "capture_building")
	assert_eq(building.side, "blue")
	assert_eq(building.team, 0)
	assert_eq(model.get_current_ap(), 4)
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is BuildingCapturedEvent)
	assert_eq(captured_recorder.observed_events.size(), 1)
	assert_same(result.events[0], captured_recorder.observed_events[0])

	building.free()
