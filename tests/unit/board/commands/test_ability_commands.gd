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


class FailingActiveUnitAbility:
	extends ActiveUnitAbility

	func _execute_model(_model: BoardModel, _source: Variant, _origin_tile: MapTile, _position: Vector2i) -> CommandResult:
		return CommandResult.new("use_ability_failed")


class FailingActiveHeroAbility:
	extends ActiveHeroAbility

	func _execute_model(_model: BoardModel, _source: Variant, _origin_tile: MapTile, _position: Vector2i) -> CommandResult:
		return CommandResult.new("use_ability_failed")


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


func _add_walkable_ground(tile: MapTile) -> BaseTile:
	var ground := BaseTile.new()
	tile.ground.set_tile(ground)
	return ground


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

	origin.unit.release()
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

	origin.unit.release()
	hero.free()


func test_use_ability_executes_spawn_unit_without_board_command_host() -> void:
	var model := _make_model()
	var origin := model.get_tile_at(Vector2i(0, 0))
	var target := model.get_tile_at(Vector2i(1, 0))
	var building := BaseBuilding.new()
	building.side = "blue"
	building.team = 0
	origin.building.set_tile(building)
	var ground := _add_walkable_ground(target)
	var ability := SpawnUnit.new()
	ability.template_name = "blue_tank"
	ability.ap_cost = 3
	ability.cooldown = 2

	var result: CommandResult = model.use_ability(origin, ability, target)

	assert_eq(result.command_name, "use_ability")
	assert_eq(model.get_current_ap(), 1)
	assert_eq(building.get_ability_cooldown(ability), 2)
	assert_true(target.unit.is_present())
	assert_eq(target.unit.tile.template_name, "blue_tank")
	assert_eq(target.unit.tile.side, "blue")
	assert_eq(target.unit.tile.team, 0)
	assert_eq(target.unit.tile.max_move, 6)
	assert_eq(result.events.size(), 3)
	assert_true(result.events[0] is ApChangedEvent)
	assert_true(result.events[1] is UnitSpawnedEvent)
	assert_true(result.events[2] is AbilityUsedEvent)

	origin.building.release()
	var spawned_unit := target.unit.tile
	target.unit.release()
	spawned_unit.free()
	ground.free()
	building.free()


func test_use_ability_does_not_spend_ap_or_cooldown_when_spawn_fails() -> void:
	var model := _make_model()
	var origin := model.get_tile_at(Vector2i(0, 0))
	var target := model.get_tile_at(Vector2i(1, 0))
	var building := BaseBuilding.new()
	building.side = "blue"
	building.team = 0
	origin.building.set_tile(building)
	var ground := _add_walkable_ground(target)
	var blocking_unit := BaseUnit.new()
	blocking_unit.side = "red"
	blocking_unit.team = 1
	target.unit.set_tile(blocking_unit)
	var ability := SpawnUnit.new()
	ability.template_name = "blue_tank"
	ability.ap_cost = 3
	ability.cooldown = 2

	var result: CommandResult = model.use_ability(origin, ability, target)

	assert_eq(result.command_name, "use_ability_failed")
	assert_eq(model.get_current_ap(), 4)
	assert_eq(building.get_ability_cooldown(ability), 0)
	assert_same(target.unit.tile, blocking_unit)
	assert_false(result.events.any(func(event: BaseEvent) -> bool: return event is AbilityUsedEvent))

	origin.building.release()
	target.unit.release()
	ground.free()
	blocking_unit.free()
	building.free()


func test_use_ability_does_not_spend_ap_move_or_cooldown_when_active_unit_ability_fails() -> void:
	var model := _make_model()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var unit := BaseUnit.new()
	unit.side = "blue"
	unit.team = 0
	unit.move = 4
	unit.max_move = 4
	origin.unit.set_tile(unit)
	var ability := FailingActiveUnitAbility.new()
	ability.ap_cost = 2
	ability.cooldown = 3

	var result: CommandResult = model.use_ability(origin, ability, target)

	assert_eq(result.command_name, "use_ability_failed")
	assert_eq(model.get_current_ap(), 4)
	assert_eq(unit.move, 4)
	assert_eq(unit.get_ability_cooldown(ability), 0)
	assert_true(result.events.is_empty())

	origin.unit.release()
	unit.free()


func test_use_ability_does_not_spend_ap_move_or_cooldown_when_active_hero_ability_fails() -> void:
	var model := _make_model()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var hero := HeroUnit.new()
	hero.side = "blue"
	hero.team = 0
	hero.move = 4
	hero.max_move = 4
	origin.unit.set_tile(hero)
	var ability := FailingActiveHeroAbility.new()
	ability.ap_cost = 3
	ability.cooldown = 2

	var result: CommandResult = model.use_ability(origin, ability, target)

	assert_eq(result.command_name, "use_ability_failed")
	assert_eq(model.get_current_ap(), 4)
	assert_eq(hero.move, 4)
	assert_eq(hero.get_ability_cooldown(ability), 0)
	assert_true(result.events.is_empty())

	origin.unit.release()
	hero.free()


func test_use_ability_fails_without_a_source_on_origin_tile() -> void:
	var model := _make_model()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)

	var result: CommandResult = model.use_ability(origin, Ability.new(), target)

	assert_eq(result.command_name, "use_ability_failed")
	assert_true(result.events.is_empty())
