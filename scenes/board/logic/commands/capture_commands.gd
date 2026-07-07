class_name CaptureCommands
extends RefCounted


var context: BoardCommandContext
var lifecycle: UnitLifecycleCommands
var turns: TurnCommands


func _init(command_context: BoardCommandContext, lifecycle_commands: UnitLifecycleCommands, turn_commands: TurnCommands) -> void:
	self.context = command_context
	self.lifecycle = lifecycle_commands
	self.turns = turn_commands


func capture_building(attacker_tile: MapTile, building_tile: MapTile, defer_retaliation_free: bool = false) -> CommandResult:
	var result := CommandResult.new("capture_building")
	if not self._can_capture(attacker_tile, building_tile):
		result.command_name = "capture_building_failed"
		return result

	var attacker: BaseUnit = attacker_tile.unit.tile
	var building: BaseBuilding = building_tile.building.tile
	var old_side: String = building.side

	attacker.use_all_moves()
	building.side = attacker.side
	building.team = attacker.team
	result.events.append_array(self.turns.use_current_player_ap(1).events)

	var crew_retaliated: bool = building.require_crew and self.context.abilities != null and not self.context.abilities.can_intimidate_crew(attacker)
	if crew_retaliated:
		var destroy_result := self.lifecycle.destroy_unit_on_tile(attacker_tile, null, defer_retaliation_free)
		result.events.append_array(destroy_result.events)
		if defer_retaliation_free:
			result.metadata["retaliation_destroyed_unit"] = destroy_result.metadata.get("released_unit")

	var event := BuildingCapturedEvent.new()
	event.building = building
	event.old_side = old_side
	event.new_side = attacker.side
	self.context.events.emit_event(event)
	result.add_event(event)
	result.delay = 0.5
	result.metadata["attacker_tile"] = attacker_tile
	result.metadata["building_tile"] = building_tile
	result.metadata["crew_retaliated"] = crew_retaliated
	return result


func cheat_capture_building(building_tile: MapTile, side: String, team: int) -> CommandResult:
	var result := CommandResult.new("capture_building")
	if not self._can_cheat_capture(building_tile):
		result.command_name = "capture_building_failed"
		return result

	var building: BaseBuilding = building_tile.building.tile
	var old_side: String = building.side
	building.side = side
	building.team = team

	var event := BuildingCapturedEvent.new()
	event.building = building
	event.old_side = old_side
	event.new_side = side
	self.context.events.emit_event(event)
	result.add_event(event)
	result.metadata["building_tile"] = building_tile
	return result


func _can_capture(attacker_tile: MapTile, building_tile: MapTile) -> bool:
	if attacker_tile == null or building_tile == null:
		return false
	if not attacker_tile.unit.is_present() or not building_tile.building.is_present():
		return false

	var attacker: BaseUnit = attacker_tile.unit.tile
	var building: BaseBuilding = building_tile.building.tile
	if attacker == null or building == null:
		return false
	if not attacker.can_capture:
		return false
	if not attacker.has_moves():
		return false
	if not building_tile.has_enemy_building(attacker.side, attacker.team):
		return false
	if not self.context.state.can_current_player_afford(1):
		return false
	return true


func _can_cheat_capture(building_tile: MapTile) -> bool:
	return building_tile != null and building_tile.building.is_present() and building_tile.building.tile != null
