class_name BoardController


var model: BoardModel
var view: BoardView = BoardView.new()
var board: Variant = null
var selected_tile: MapTile = null
var active_ability: Ability = null
var active_ability_origin_tile: MapTile = null


func _init(board_model: BoardModel, view_host: BoardView = null, board_host: Variant = null) -> void:
	self.model = board_model
	if view_host != null:
		self.attach_view(view_host)
	if board_host != null:
		self.attach_board(board_host)


func attach_view(view_host: BoardView) -> void:
	self.view = view_host


func attach_board(board_host: Variant) -> void:
	self.board = board_host


func select_tile(tile: MapTile) -> void:
	self.selected_tile = tile


func start_ability_targeting(origin_tile: MapTile, ability: Ability) -> void:
	self.active_ability = ability
	self.active_ability_origin_tile = origin_tile


func cancel_ability() -> void:
	self.active_ability = null
	self.active_ability_origin_tile = null


func clear_selection() -> void:
	self.selected_tile = null


func cancel_interaction() -> void:
	if self.active_ability != null:
		self.cancel_ability()
		self.view.cancel_ability()
	else:
		self.clear_selection()
		self.view.unselect_tile()


func press_tile(tile_position: Vector2i) -> void:
	var tile: MapTile = self.model.get_tile_at(tile_position)
	if tile == null:
		return

	var open_unit_abilities: bool = false

	if self.active_ability != null:
		if self.model.has_active_ability_target_marker(tile) or self.model.is_current_player_ai():
			self._clear_last_unit_move()
			self._execute_targeted_ability(tile)
		else:
			self.view.unselect_tile()

	elif self.model.is_tile_selectable_for_current_player(tile):
		if self.selected_tile == tile:
			open_unit_abilities = true
		self.selected_tile = tile
		self.view.show_contextual_select(open_unit_abilities)

	elif self.selected_tile != null:
		var move_completed: bool = false
		if self.view.can_move_to_tile(tile):
			self._clear_last_unit_move()
			move_completed = self.view.move_unit_from_marker_path(self.selected_tile, tile)
		elif self.model.can_move_to_tile_from_source(self.selected_tile, tile, 1):
			self._clear_last_unit_move()
			var result := self.model.move_unit(self.selected_tile, tile)
			move_completed = result.command_name == "move_unit"

		if move_completed:
			self.selected_tile = tile
			self.view.show_contextual_select()

		elif self._selected_unit_can_interact_with(tile):
			self._clear_last_unit_move()
			self._handle_selected_tile_interaction(tile)

		else:
			self.view.unselect_tile()

	self.view.hover_tile()
	self.view.play_tile_selected_feedback()


func _clear_last_unit_move() -> void:
	if self.board == null:
		return
	self.board._set_last_unit_move(null)


func _execute_targeted_ability(tile: MapTile) -> void:
	assert(self.active_ability != null)
	var result := self.model.use_ability(self.active_ability_origin_tile, self.active_ability, tile)
	self._present_ability_result(result)
	await self.model.action_pacer.wait_after(result)
	self.cancel_ability()
	self.view.cancel_ability()
	var select_tile_position: Variant = result.metadata.get("select_tile_position")
	if select_tile_position != null:
		self._select_tile_position(Vector2i(select_tile_position))


func _selected_unit_can_interact_with(tile: MapTile) -> bool:
	if self.selected_tile == null:
		return false
	if not self.selected_tile.unit.is_present():
		return false
	return self.selected_tile.is_neighbour(tile) && tile.can_unit_interact(self.selected_tile.unit.tile) && self.model.can_current_player_afford(1)


func _handle_selected_tile_interaction(tile: MapTile) -> void:
	var source_tile: MapTile = self.selected_tile
	self._handle_interaction_from_tile(source_tile, tile)
	if source_tile != null && source_tile.unit.is_present():
		self.view.show_contextual_select()


func _handle_interaction_from_tile(source_tile: MapTile, target_tile: MapTile) -> void:
	if source_tile == null:
		return
	if not source_tile.unit.is_present():
		return
	if target_tile.unit.is_present():
		var attack_result := self.model.attack_unit(source_tile, target_tile)
		self._present_attack_result(attack_result)
	if target_tile.building.is_present():
		var capture_result := self.model.capture_building(source_tile, target_tile)
		self._present_capture_result(capture_result)


func _present_attack_result(result: CommandResult) -> void:
	if self.board == null:
		return
	self.board._present_attack_result(result)


func _present_capture_result(result: CommandResult) -> void:
	if self.board == null:
		return
	self.board._present_capture_result(result)


func _present_ability_result(result: CommandResult) -> void:
	self.model.present_action_result(result)


func _select_tile_position(tile_position: Vector2i) -> void:
	if self.board == null:
		return
	self.board.select_tile(tile_position)
