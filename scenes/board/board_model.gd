class_name BoardModel


const MovementCommandsScript: Script = preload("res://scenes/board/logic/commands/movement_commands.gd")

var board: Variant = null
var state: State = State.new()
var radial_abilities: RadialAbilities = RadialAbilities.new()
var map_model: MapModel = null
var command_context: BoardCommandContext = null
var movement_commands: RefCounted = null
var turn_commands: TurnCommands = null
var action_pacer: ActionPacer = NoOpActionPacer.new()
var abilities: Abilities = null
var events: Events = Events.new()
var observers: Observers = null
var scripting: Scripting = Scripting.new()
var ai: Ai = null
var collateral: Collateral = null


func _init(board_host: Variant = null) -> void:
	if board_host != null:
		self.attach_board(board_host)
	else:
		self._rebuild_command_context()


func attach_board(board_host: Variant) -> void:
	self.board = board_host
	if board_host.map != null:
		self.map_model = board_host.map.model
	elif board_host is Node and not board_host.ready.is_connected(self._sync_map_model_from_board):
		board_host.ready.connect(self._sync_map_model_from_board, CONNECT_ONE_SHOT)
	self.abilities = Abilities.new(self.state)
	self.observers = Observers.new(board_host)
	self.ai = Ai.new(board_host)
	self.collateral = Collateral.new(self)
	self._rebuild_command_context()


func set_map_model(new_map_model: MapModel) -> void:
	self.map_model = new_map_model
	self._rebuild_command_context()


func set_action_pacer(new_pacer: ActionPacer) -> void:
	if new_pacer == null:
		self.action_pacer = NoOpActionPacer.new()
		return
	self.action_pacer = new_pacer


func _rebuild_command_context() -> void:
	self.command_context = BoardCommandContext.new(
		self.state,
		self.map_model,
		self.events,
		self.scripting,
		self.abilities,
		self.collateral
	)
	self.turn_commands = TurnCommands.new(self.command_context)
	self.movement_commands = MovementCommandsScript.new(self.command_context, self.turn_commands)


func _sync_map_model_from_board() -> void:
	if self.board != null and self.board.map != null:
		self.set_map_model(self.board.map.model)


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


func add_current_player_ap(value: int) -> CommandResult:
	assert(self.turn_commands != null)
	return self.turn_commands.add_current_player_ap(value)


func use_current_player_ap(value: int) -> CommandResult:
	assert(self.turn_commands != null)
	return self.turn_commands.use_current_player_ap(value)


func can_current_player_afford(amount: int) -> bool:
	return self.state.can_current_player_afford(amount)


func end_turn() -> CommandResult:
	assert(self.turn_commands != null)
	return self.turn_commands.end_turn()


func get_tile_at(tile_position: Vector2i) -> MapTile:
	assert(self.map_model != null)
	return self.map_model.get_tile(tile_position)


func _get_tile_key(tile: MapTile) -> String:
	if tile == null:
		return ""
	return str(tile.position.x) + "_" + str(tile.position.y)


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
	return self.can_move_to_tile_from_source(null, tile, 0)


func can_move_to_tile_from_source(source_tile: MapTile, destination_tile: MapTile, move_cost: int) -> bool:
	assert(self.movement_commands != null)
	return self.movement_commands.can_move_to_tile(source_tile, destination_tile, move_cost)


func move_unit(source_tile: MapTile, destination_tile: MapTile) -> CommandResult:
	var movement_path: Array[String] = [
		_get_tile_key(source_tile),
		_get_tile_key(destination_tile),
	]
	var result: CommandResult = self.move_unit_along_path(source_tile, destination_tile, 1, movement_path)
	return result


func move_unit_along_path(source_tile: MapTile, destination_tile: MapTile, move_cost: int, movement_path: Array[String]) -> CommandResult:
	assert(self.movement_commands != null)
	var result: CommandResult = self.movement_commands.move_unit_along_path(source_tile, destination_tile, move_cost, movement_path)
	return result


func reserve_ap(amount: int) -> void:
	assert(self.board != null)
	self.board.ai.reserve_ap(amount)


func interact_unit(source_tile: MapTile, interaction_tile: MapTile, target_tile: MapTile) -> void:
	assert(self.board != null)
	var action_source: MapTile = source_tile
	if interaction_tile != null:
		self.move_unit(source_tile, interaction_tile)
		action_source = interaction_tile
	self.board.handle_interaction_from_tile(action_source, target_tile)


func use_ability(origin_tile: MapTile, ability: Ability, target_tile: MapTile) -> void:
	assert(self.board != null)
	self.board.execute_ability_from_tile(origin_tile, ability, target_tile)


func wait_for_action_delay(delay: float) -> void:
	if delay <= 0.0:
		return
	if self.board is Node:
		await self.board.get_tree().create_timer(delay).timeout


func selected_unit_can_interact_with(tile: MapTile) -> bool:
	assert(self.board != null)
	return self.board.selected_unit_can_interact_with(tile)


func handle_interaction(tile: MapTile) -> void:
	assert(self.board != null)
	self.board.handle_interaction(tile)
