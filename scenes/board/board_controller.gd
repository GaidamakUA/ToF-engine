class_name BoardController


signal clear_selection_view_requested
signal clear_ability_view_requested
signal contextual_select_requested(open_unit_abilities: bool)
signal hover_tile_requested
signal tile_selected_feedback_requested


var model: BoardModel
var selected_tile: MapTile = null
var active_ability: Ability = null
var active_ability_origin_tile: MapTile = null


func _init(board_model: BoardModel) -> void:
	self.model = board_model


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
		self.clear_ability_view_requested.emit()
	else:
		self.clear_selection()
		self.clear_selection_view_requested.emit()


func press_tile(tile_position: Vector2i) -> void:
	var tile: MapTile = self.model.get_tile_at(tile_position)
	if tile == null:
		return

	var open_unit_abilities: bool = false

	if self.active_ability != null:
		if self.model.has_active_ability_target_marker(tile) or self.model.is_current_player_ai():
			self.model.set_last_unit_move(null)
			self.model.execute_active_ability(tile)
		else:
			self.clear_selection_view_requested.emit()

	elif self.model.is_tile_selectable_for_current_player(tile):
		if self.selected_tile == tile:
			open_unit_abilities = true
		self.selected_tile = tile
		self.contextual_select_requested.emit(open_unit_abilities)

	elif self.selected_tile != null:
		if self.model.can_move_to_tile(tile):
			self.model.set_last_unit_move(null)
			self.model.move_unit(self.selected_tile, tile)
			self.selected_tile = tile
			self.contextual_select_requested.emit(false)

		elif self.model.selected_unit_can_interact_with(tile):
			self.model.set_last_unit_move(null)
			self.model.handle_interaction(tile)

		else:
			self.clear_selection_view_requested.emit()

	self.hover_tile_requested.emit()
	self.tile_selected_feedback_requested.emit()
