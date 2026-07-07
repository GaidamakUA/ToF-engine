class_name AbilityCommands
extends RefCounted


var model: BoardModel
var context: BoardCommandContext


func _init(model_object: BoardModel, command_context: BoardCommandContext) -> void:
	self.model = model_object
	self.context = command_context


func use_ability(origin_tile: MapTile, ability: Ability, target_tile: MapTile) -> CommandResult:
	var result := CommandResult.new("use_ability")
	if origin_tile == null or ability == null or target_tile == null:
		result.command_name = "use_ability_failed"
		return result

	var source: Variant = self._get_source(origin_tile)
	if source == null:
		result.command_name = "use_ability_failed"
		return result
	if not self._can_use_ability(source, ability):
		result.command_name = "use_ability_failed"
		return result

	result.merge_from(ability.execute_model(self.model, source, origin_tile, target_tile.position))
	if result.command_name == "use_ability_failed":
		return result

	var ability_state: AbilityState = source.get_ability_state(ability)
	ability_state.activate_cooldown_model(ability, self.context.abilities, source)
	return result


func _get_source(origin_tile: MapTile) -> Variant:
	if origin_tile.building.is_present():
		return origin_tile.building.tile
	if origin_tile.unit.is_present():
		return origin_tile.unit.tile
	return null


func _can_use_ability(source: Variant, ability: Ability) -> bool:
	if source == null or not source.has_method(&"get_ability_state"):
		return false

	var ability_state: AbilityState = source.get_ability_state(ability)
	if ability_state == null:
		return false
	if ability_state.disabled or ability_state.is_on_cooldown():
		return false

	return self.context.state.can_current_player_afford(self._get_ability_cost(source, ability))


func _get_ability_cost(source: Variant, ability: Ability) -> int:
	var cost := ability.get_cost(source)
	if self.context.abilities == null or not (source is BaseBuilding):
		return cost

	var template_name: Variant = ability.get("template_name")
	if template_name == null or String(template_name).is_empty():
		return cost

	return self.context.abilities.get_modified_cost(cost, String(template_name), source)
