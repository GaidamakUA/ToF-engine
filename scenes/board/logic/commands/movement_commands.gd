class_name MovementCommands
extends RefCounted


var context: BoardCommandContext


func _init(command_context: BoardCommandContext) -> void:
	self.context = command_context


func can_move_to_tile(source_tile: MapTile, destination_tile: MapTile, move_cost: int) -> bool:
	if source_tile == null or destination_tile == null:
		return false
	if not source_tile.unit.is_present():
		return false
	if move_cost <= 0:
		return false
	if not self.context.state.can_current_player_afford(move_cost):
		return false
	return destination_tile.can_acommodate_unit(source_tile.unit.tile)


func move_unit_along_path(source_tile: MapTile, destination_tile: MapTile, move_cost: int, movement_path: Array[String]) -> CommandResult:
	var result := CommandResult.new("move_unit")
	if source_tile == null or destination_tile == null or not source_tile.unit.is_present():
		result.command_name = "move_unit_failed"
		return result

	var unit: BaseUnit = source_tile.unit.tile
	destination_tile.unit.set_tile(unit)
	source_tile.unit.release()
	self.context.state.use_current_player_ap(move_cost)
	unit.use_move(move_cost)

	var event := UnitMovedEvent.new()
	event.unit = unit
	event.start = source_tile
	event.finish = destination_tile
	self.context.events.emit_event(event)
	result.add_event(event)
	result.metadata["path"] = movement_path
	result.delay = movement_path.size() * 0.1
	return result
