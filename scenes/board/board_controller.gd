class_name BoardController


var model: BoardModel
var view: BoardView = BoardView.new()
var selected_tile: MapTile = null
var active_ability: Ability = null
var active_ability_origin_tile: MapTile = null


func _init(board_model: BoardModel, view_host: BoardView = null) -> void:
	self.model = board_model
	if view_host != null:
		self.attach_view(view_host)


func attach_view(view_host: BoardView) -> void:
	self.view = view_host


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
			self.model.set_last_unit_move(null)
			self.model.execute_active_ability(tile)
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
			self.model.set_last_unit_move(null)
			move_completed = self.view.move_unit_from_marker_path(self.selected_tile, tile)
		elif self.model.can_move_to_tile(tile):
			self.model.set_last_unit_move(null)
			var result := self.model.move_unit(self.selected_tile, tile)
			move_completed = result.command_name == "move_unit"

		if move_completed:
			self.selected_tile = tile
			self.view.show_contextual_select()

		elif self.model.selected_unit_can_interact_with(tile):
			self.model.set_last_unit_move(null)
			self.model.handle_interaction(tile)

		else:
			self.view.unselect_tile()

	self.view.hover_tile()
	self.view.play_tile_selected_feedback()
