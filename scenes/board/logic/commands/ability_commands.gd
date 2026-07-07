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
