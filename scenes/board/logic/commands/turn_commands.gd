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


func end_turn() -> CommandResult:
	var result := CommandResult.new("end_turn")
	var old_turn: int = self.context.state.turn
	var old_player: int = self.context.state.current_player
	result.add_event(self.context.events.emit_turn_ended(old_turn, old_player))
	self.context.state.switch_to_next_player()
	result.add_event(self.context.events.emit_turn_started(self.context.state.turn, self.context.state.current_player))
	return result
