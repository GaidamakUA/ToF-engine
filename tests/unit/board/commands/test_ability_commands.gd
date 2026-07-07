extends GutTest


class TrackingActiveUnitAbility:
	extends ActiveUnitAbility

	var executed_position := Vector2i(-1, -1)

	func _execute_model(_model: BoardModel, _source: Variant, _origin_tile: MapTile, position: Vector2i) -> CommandResult:
		self.executed_position = position
		return CommandResult.new("tracking_active_unit")


class TrackingActiveHeroAbility:
	extends ActiveHeroAbility

	var executed_position := Vector2i(-1, -1)

	func _execute_model(_model: BoardModel, _source: Variant, _origin_tile: MapTile, position: Vector2i) -> CommandResult:
		self.executed_position = position
		return CommandResult.new("tracking_active_hero")


class SpawnTrackingModel:
	extends BoardModel

	var spawn_requests: Array = []
	var spawned_unit: BaseUnit = BaseUnit.new()

	func spawn_unit(position: Vector2i, template_name: String, rotation: int, side: String, _source: Variant = null, _ai_paused: bool = false) -> BaseUnit:
		self.spawn_requests.append({
			"position": position,
			"template_name": template_name,
			"rotation": rotation,
			"side": side,
		})
		self.spawned_unit.side = side
		return self.spawned_unit


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


func _make_spawn_model() -> SpawnTrackingModel:
	var model := SpawnTrackingModel.new()
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


func test_use_ability_executes_active_unit_ability_spends_ap_and_activates_cooldown() -> void:
	var model := _make_model()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var unit := BaseUnit.new()
	unit.side = "blue"
	unit.team = 0
	unit.move = 4
	unit.max_move = 4
	origin.unit.set_tile(unit)
	var ability := TrackingActiveUnitAbility.new()
	ability.ap_cost = 2
	ability.cooldown = 3

	var result: CommandResult = model.use_ability(origin, ability, target)

	assert_eq(result.command_name, "use_ability")
	assert_eq(model.get_current_ap(), 2)
	assert_eq(unit.move, 3)
	assert_eq(unit.get_ability_cooldown(ability), 3)
	assert_eq(ability.executed_position, target.position)
	assert_eq(result.events.size(), 2)
	assert_true(result.events[0] is ApChangedEvent)
	assert_true(result.events[1] is AbilityUsedEvent)

	unit.free()


func test_use_ability_executes_active_hero_ability_spends_ap_after_effect_and_activates_cooldown() -> void:
	var model := _make_model()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var hero := HeroUnit.new()
	hero.side = "blue"
	hero.team = 0
	hero.move = 4
	hero.max_move = 4
	origin.unit.set_tile(hero)
	var ability := TrackingActiveHeroAbility.new()
	ability.ap_cost = 3
	ability.cooldown = 2

	var result: CommandResult = model.use_ability(origin, ability, target)

	assert_eq(result.command_name, "use_ability")
	assert_eq(model.get_current_ap(), 1)
	assert_eq(hero.move, 3)
	assert_eq(hero.get_ability_cooldown(ability), 2)
	assert_eq(ability.executed_position, target.position)
	assert_eq(result.events.size(), 2)
	assert_true(result.events[0] is AbilityUsedEvent)
	assert_true(result.events[1] is ApChangedEvent)

	hero.free()


func test_use_ability_executes_spawn_unit_without_board_command_host() -> void:
	var model := _make_spawn_model()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var building := BaseBuilding.new()
	building.side = "blue"
	building.team = 0
	origin.building.set_tile(building)
	var ability := SpawnUnit.new()
	ability.template_name = "tank"
	ability.ap_cost = 3
	ability.cooldown = 2

	var result: CommandResult = model.use_ability(origin, ability, target)

	assert_eq(result.command_name, "use_ability")
	assert_eq(model.get_current_ap(), 1)
	assert_eq(building.get_ability_cooldown(ability), 2)
	assert_eq(model.spawn_requests.size(), 1)
	assert_eq(model.spawn_requests[0]["position"], target.position)
	assert_eq(model.spawn_requests[0]["template_name"], "tank")
	assert_eq(model.spawn_requests[0]["rotation"], 0)
	assert_eq(model.spawn_requests[0]["side"], "blue")
	assert_eq(model.spawned_unit.team, 0)
	assert_eq(result.events.size(), 3)
	assert_true(result.events[0] is ApChangedEvent)
	assert_true(result.events[1] is UnitSpawnedEvent)
	assert_true(result.events[2] is AbilityUsedEvent)

	model.spawned_unit.free()
	building.free()


func test_use_ability_fails_without_a_source_on_origin_tile() -> void:
	var model := _make_model()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)

	var result: CommandResult = model.use_ability(origin, Ability.new(), target)

	assert_eq(result.command_name, "use_ability_failed")
	assert_true(result.events.is_empty())
