class_name BoardController


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
