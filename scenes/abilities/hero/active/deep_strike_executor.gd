extends Node3D
class_name DeepStrikeExecutor

var strike_position: Vector2i
var source: BaseUnit
var template_name: String
var board: Board

@export
var heli: Heli

func _ready() -> void:
	heli.sfx_effect("move")

func set_up(_board: Board, _position: Vector2i, _source: BaseUnit, _template_name: String) -> void:
	self.board = _board
	self.strike_position = _position
	self.source = _source
	self.template_name = _template_name

	self.set_side_material()

func set_side_material() -> void:
	heli.set_side(self.source.side)
	heli.set_side_material(self.board.map.templates.get_side_material(self.source.side, self.board.map.templates.MATERIAL_METALLIC))

func _deploy_unit() -> void:
	var tile := self.board.map.model.get_tile(self.strike_position)
	var new_unit: BaseUnit = self.board.map.builder.place_unit(self.strike_position, self.template_name, 90, self.source.side)

	new_unit.remove_moves()
	new_unit.team = self.source.team
	self.board.abilities.apply_passive_modifiers(new_unit)
	new_unit.sfx_effect("spawn")

	self.board.events.emit_unit_spawned(self.source, new_unit)
	self.board.events.emit_unit_moved(new_unit, tile, tile)
