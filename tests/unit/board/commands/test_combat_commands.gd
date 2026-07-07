extends GutTest


class AttackTrackingUnit:
	extends BaseUnit

	var used_move_cost: int = -1
	var used_attack: bool = false
	var used_all_moves: bool = false

	func use_move(value: int) -> void:
		self.used_move_cost = value
		super.use_move(value)

	func use_attack() -> void:
		self.used_attack = true
		super.use_attack()

	func use_all_moves() -> void:
		self.used_all_moves = true
		super.use_all_moves()


class UnitAttackedRecorder:
	extends Observer

	var observed_events: Array[UnitAttackedEvent] = []

	func _init() -> void:
		super(null)
		self.observed_event_type = UnitAttackedEvent

	func _observe(event: BaseEvent) -> void:
		self.observed_events.append(event as UnitAttackedEvent)


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


func test_attack_unit_damages_defender_spends_ap_and_emits_attack_event() -> void:
	var model := _make_model()
	var attacked_recorder := UnitAttackedRecorder.new()
	model.events.register_observer(attacked_recorder)
	var attacker_tile := MapTile.new(0, 0)
	var defender_tile := MapTile.new(1, 0)
	attacker_tile.add_neighbour(MapTile.EAST, defender_tile)
	defender_tile.add_neighbour(MapTile.WEST, attacker_tile)
	var attacker := AttackTrackingUnit.new()
	attacker.side = "blue"
	attacker.team = 0
	attacker.attack = 3
	attacker.move = 4
	attacker.max_move = 4
	attacker.attacks = 1
	var defender := BaseUnit.new()
	defender.side = "red"
	defender.team = 1
	defender.hp = 10
	defender.max_hp = 10
	defender.armor = 0
	defender.move = 0
	defender.max_move = 0
	attacker_tile.unit.set_tile(attacker)
	defender_tile.unit.set_tile(defender)

	var result: CommandResult = model.attack_unit(attacker_tile, defender_tile)

	assert_eq(result.command_name, "attack_unit")
	assert_eq(model.get_current_ap(), 3)
	assert_eq(attacker.move, 3)
	assert_eq(attacker.attacks, 0)
	assert_eq(attacker.used_move_cost, 1)
	assert_true(attacker.used_attack)
	assert_eq(defender.hp, 7)
	assert_eq(result.events.size(), 2)
	assert_true(result.events[0] is ApChangedEvent)
	assert_true(result.events[1] is UnitAttackedEvent)
	assert_eq(attacked_recorder.observed_events.size(), 1)
	assert_same(attacked_recorder.observed_events[0].attacker, attacker)
	assert_same(attacked_recorder.observed_events[0].unit, defender)
	assert_same(attacked_recorder.observed_events[0].attacker_tile, attacker_tile)
	assert_same(attacked_recorder.observed_events[0].defender_tile, defender_tile)

	attacker.free()
	defender.free()


func test_attack_unit_retaliation_damages_attacker_and_consumes_defender_moves() -> void:
	var model := _make_model()
	var attacked_recorder := UnitAttackedRecorder.new()
	model.events.register_observer(attacked_recorder)
	var attacker_tile := MapTile.new(0, 0)
	var defender_tile := MapTile.new(1, 0)
	attacker_tile.add_neighbour(MapTile.EAST, defender_tile)
	defender_tile.add_neighbour(MapTile.WEST, attacker_tile)
	var attacker := BaseUnit.new()
	attacker.side = "blue"
	attacker.team = 0
	attacker.hp = 10
	attacker.max_hp = 10
	attacker.armor = 0
	attacker.attack = 3
	attacker.move = 4
	attacker.max_move = 4
	attacker.attacks = 1
	var defender := AttackTrackingUnit.new()
	defender.side = "red"
	defender.team = 1
	defender.hp = 10
	defender.max_hp = 10
	defender.armor = 0
	defender.attack = 2
	defender.move = 3
	defender.max_move = 3
	attacker_tile.unit.set_tile(attacker)
	defender_tile.unit.set_tile(defender)

	var result: CommandResult = model.attack_unit(attacker_tile, defender_tile)

	assert_eq(result.command_name, "attack_unit")
	assert_eq(attacker.hp, 8)
	assert_eq(defender.move, 0)
	assert_true(defender.used_all_moves)
	assert_eq(result.events.size(), 3)
	assert_true(result.events[0] is ApChangedEvent)
	assert_true(result.events[1] is UnitAttackedEvent)
	assert_true(result.events[2] is UnitAttackedEvent)
	assert_eq(attacked_recorder.observed_events.size(), 2)
	assert_same(result.events[1], attacked_recorder.observed_events[0])
	assert_same(result.events[2], attacked_recorder.observed_events[1])
	assert_same(attacked_recorder.observed_events[0].attacker, defender)
	assert_same(attacked_recorder.observed_events[0].unit, attacker)
	assert_same(attacked_recorder.observed_events[0].attacker_tile, defender_tile)
	assert_same(attacked_recorder.observed_events[0].defender_tile, attacker_tile)
	assert_same(attacked_recorder.observed_events[1].attacker, attacker)
	assert_same(attacked_recorder.observed_events[1].unit, defender)
	assert_same(attacked_recorder.observed_events[1].attacker_tile, attacker_tile)
	assert_same(attacked_recorder.observed_events[1].defender_tile, defender_tile)

	attacker.free()
	defender.free()


func test_attack_unit_destroying_defender_emits_destroyed_event_and_clears_tile() -> void:
	var model := _make_model()
	var destroyed_recorder := UnitDestroyedRecorder.new()
	model.events.register_observer(destroyed_recorder)
	var attacker_tile := MapTile.new(0, 0)
	var defender_tile := MapTile.new(1, 0)
	var attacker := AttackTrackingUnit.new()
	attacker.side = "blue"
	attacker.team = 0
	attacker.attack = 99
	attacker.move = 4
	attacker.max_move = 4
	attacker.attacks = 1
	var defender := BaseUnit.new()
	defender.side = "red"
	defender.team = 1
	defender.template_name = "scout"
	defender.hp = 1
	defender.max_hp = 1
	defender.armor = 0
	attacker_tile.unit.set_tile(attacker)
	defender_tile.unit.set_tile(defender)

	var result: CommandResult = model.attack_unit(attacker_tile, defender_tile)

	assert_eq(result.command_name, "attack_unit")
	assert_false(defender_tile.unit.is_present())
	assert_eq(result.events.size(), 2)
	assert_true(result.events[0] is ApChangedEvent)
	assert_true(result.events[1] is UnitDestroyedEvent)
	assert_eq(destroyed_recorder.observed_events.size(), 1)
	assert_same(destroyed_recorder.observed_events[0].attacker, attacker)
	assert_eq(destroyed_recorder.observed_events[0].unit_type, "scout")
	assert_eq(destroyed_recorder.observed_events[0].unit_side, "red")

	attacker.free()
	defender.free()
