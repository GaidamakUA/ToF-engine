class_name TurnCommands
extends RefCounted


var context: BoardCommandContext


func _init(command_context: BoardCommandContext) -> void:
	self.context = command_context


func use_current_player_ap(value: int) -> CommandResult:
	var result := CommandResult.new("use_current_player_ap")
	var player_id: int = self.context.state.current_player
	var old_ap: int = self.context.state.get_current_ap()
	self.context.state.use_current_player_ap(value)
	var event := self.context.events.emit_ap_changed(player_id, old_ap, self.context.state.get_current_ap())
	result.add_event(event)
	return result


func add_current_player_ap(value: int) -> CommandResult:
	var result := CommandResult.new("add_current_player_ap")
	var player_id: int = self.context.state.current_player
	var old_ap: int = self.context.state.get_current_ap()
	self.context.state.add_current_player_ap(value)
	var event := self.context.events.emit_ap_changed(player_id, old_ap, self.context.state.get_current_ap())
	result.add_event(event)
	return result


func prepare_current_turn() -> CommandResult:
	var result := CommandResult.new("prepare_current_turn")
	if self.context.map_model == null:
		return result

	var side := self.context.state.get_current_side()
	var team := self.context.state.get_player_team(side)

	for unit: BaseUnit in self.context.map_model.get_player_units(side):
		unit.clear_modifiers()
		if self.context.abilities != null:
			self.context.abilities.apply_passive_modifiers(unit)
		unit.replenish_moves()
		unit.ability_cd_tick_down()
		unit.team = team

	var ap_sum: int = 0
	var ap_gain_tiles: Array[MapTile] = []
	for building_tile: MapTile in self.context.map_model.get_player_buildings_tiles(side):
		var building: BaseBuilding = building_tile.building.tile
		if building == null:
			continue
		var modified_ap_gain := building.ap_gain
		if self.context.abilities != null:
			modified_ap_gain = self.context.abilities.get_modified_ap_gain(modified_ap_gain, building)
		ap_sum += modified_ap_gain
		building.team = team
		if building.ap_gain > 0:
			ap_gain_tiles.append(building_tile)

	if ap_sum != 0:
		result.merge_from(self.add_current_player_ap(ap_sum))
	result.metadata["ap_gain_tiles"] = ap_gain_tiles
	return result


func end_turn() -> CommandResult:
	var result := CommandResult.new("end_turn")
	var old_turn: int = self.context.state.turn
	var old_player: int = self.context.state.current_player
	result.add_event(self.context.events.emit_turn_ended(old_turn, old_player))
	self.context.state.switch_to_next_player()
	result.merge_from(self.prepare_current_turn())
	result.add_event(self.context.events.emit_turn_started(self.context.state.turn, self.context.state.current_player))
	return result
