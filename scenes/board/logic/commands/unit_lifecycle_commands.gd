class_name UnitLifecycleCommands
extends RefCounted


var context: BoardCommandContext


func _init(command_context: BoardCommandContext) -> void:
	self.context = command_context


func destroy_unit_on_tile(tile: MapTile, attacker: BaseUnit = null) -> CommandResult:
	var result := CommandResult.new("destroy_unit")
	if tile == null or not tile.unit.is_present():
		result.command_name = "destroy_unit_failed"
		return result

	var unit: BaseUnit = tile.unit.tile
	var unit_id: int = unit.get_instance_id()
	var unit_type: String = unit.template_name
	var unit_side: String = unit.side

	if unit.unit_class == "hero":
		var hero: HeroUnit = unit as HeroUnit
		if hero != null:
			self.context.state.clear_hero_for_side(unit.side, hero)

	tile.unit.clear()

	var event := UnitDestroyedEvent.new()
	event.unit_id = unit_id
	event.unit_type = unit_type
	event.unit_side = unit_side
	event.attacker = attacker
	self.context.events.emit_event(event)
	result.add_event(event)

	return result


func replenish_unit_actions(side: String) -> CommandResult:
	var result := CommandResult.new("replenish_unit_actions")
	var units: Array[BaseUnit] = self.context.map_model.get_player_units(side)
	for unit: BaseUnit in units:
		unit.clear_modifiers()
		if self.context.abilities != null:
			self.context.abilities.apply_passive_modifiers(unit)
		unit.replenish_moves()
		unit.ability_cd_tick_down()
		unit.team = self.context.state.get_player_team(side)
	return result
