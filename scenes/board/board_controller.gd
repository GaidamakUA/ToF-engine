class_name BoardController


var model: BoardModel
var board: Variant = null
var selected_tile: MapTile = null
var active_ability: Ability = null
var active_ability_origin_tile: MapTile = null


func _init(board_model: BoardModel, board_host: Variant = null) -> void:
	self.model = board_model
	if board_host != null:
		self.attach_board(board_host)


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


func cancel() -> void:
	assert(self.board != null)
	if self.active_ability != null:
		self.board.cancel_ability()
	else:
		self.board.unselect_tile()


func press_tile(tile_position: Vector2i) -> void:
	assert(self.board != null)
	var tile: MapTile = self.board.get_tile_at(tile_position)
	if tile == null:
		return

	var open_unit_abilities: bool = false

	if self.active_ability != null:
		if self.board.has_active_ability_target_marker(tile) or self.board.is_current_player_ai():
			self.board.set_last_unit_move(null)
			self.board.execute_active_ability(tile)
		else:
			self.board.unselect_tile()

	elif self.board.is_tile_selectable_for_current_player(tile):
		if self.selected_tile == tile:
			open_unit_abilities = true
		self.selected_tile = tile
		self.board.show_contextual_select(open_unit_abilities)

	elif self.selected_tile != null:
		if self.board.can_move_to_tile(tile):
			self.board.set_last_unit_move(null)
			self.board.move_unit(self.selected_tile, tile)
			self.selected_tile = tile
			self.board.show_contextual_select()

		elif self.board.selected_unit_can_interact_with(tile):
			self.board.set_last_unit_move(null)
			self.board.handle_interaction(tile)

		else:
			self.board.unselect_tile()

	self.board.hover_tile()
	self.board.play_tile_selected_feedback()
