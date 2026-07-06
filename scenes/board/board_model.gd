class_name BoardModel


var board: Variant = null
var state: State = State.new()
var radial_abilities: RadialAbilities = RadialAbilities.new()
var abilities: Abilities = null
var events: Events = Events.new()
var observers: Observers = null
var scripting: Scripting = Scripting.new()
var ai: Ai = null
var collateral: Collateral = null


func _init(board_host: Variant = null) -> void:
	if board_host != null:
		self.attach_board(board_host)


func attach_board(board_host: Variant) -> void:
	self.board = board_host
	self.abilities = Abilities.new(board_host)
	self.observers = Observers.new(board_host)
	self.ai = Ai.new(board_host)
	self.collateral = Collateral.new(board_host)


func add_player(data: Dictionary[String, Variant]) -> void:
	var side: String = String(data["side"])
	self.state.add_player(String(data["type"]), side, bool(data["alive"]), data["team"])
	var player_id: int = self.state.players.size() - 1
	if data.has("ap"):
		self.state.add_player_ap(player_id, int(data["ap"]))
	self.state.set_player_team(side, self.state.get_player_team(side))


func get_current_player() -> Dictionary:
	return self.state.get_current_player()


func get_current_side() -> String:
	return self.state.get_current_side()


func get_current_team() -> int:
	return self.state.get_current_team()


func get_current_ap() -> int:
	return self.state.get_current_ap()


func get_player_team(side: String) -> int:
	return self.state.get_player_team(side)


func add_current_player_ap(value: int) -> void:
	self.state.add_current_player_ap(value)


func use_current_player_ap(value: int) -> void:
	self.state.use_current_player_ap(value)


func can_current_player_afford(amount: int) -> bool:
	return self.state.can_current_player_afford(amount)


func end_turn() -> void:
	self.state.switch_to_next_player()


func get_tile_at(tile_position: Vector2i) -> MapTile:
	assert(self.board != null)
	return self.board.get_tile_at(tile_position)


func is_tile_selectable_for_current_player(tile: MapTile) -> bool:
	assert(self.board != null)
	return self.board.is_tile_selectable_for_current_player(tile)


func has_active_ability_target_marker(tile: MapTile) -> bool:
	assert(self.board != null)
	return self.board.has_active_ability_target_marker(tile)


func is_current_player_ai() -> bool:
	return self.state.is_current_player_ai()


func set_last_unit_move(value: Variant) -> void:
	assert(self.board != null)
	self.board.set_last_unit_move(value)


func execute_active_ability(tile: MapTile) -> void:
	assert(self.board != null)
	self.board.execute_active_ability(tile)


func can_move_to_tile(tile: MapTile) -> bool:
	assert(self.board != null)
	return self.board.can_move_to_tile(tile)


func move_unit(source_tile: MapTile, destination_tile: MapTile) -> void:
	assert(self.board != null)
	self.board.move_unit(source_tile, destination_tile)


func selected_unit_can_interact_with(tile: MapTile) -> bool:
	assert(self.board != null)
	return self.board.selected_unit_can_interact_with(tile)


func handle_interaction(tile: MapTile) -> void:
	assert(self.board != null)
	self.board.handle_interaction(tile)
