extends Node3D
class_name PrecisionStrikeExecutor

signal impact
signal finished

var strike_position: Vector2i
var source: BaseUnit
var board: Variant

@export var heli_resource: UnitResource
@export var heli: BaseUnit

func _ready() -> void:
    heli.configure(self.heli_resource)

func set_up(_board: Variant, _position: Vector2i, _source: BaseUnit) -> void:
    self.board = _board
    self.strike_position = _position
    self.source = _source

    self.set_side_material()

func set_side_material() -> void:
    heli.set_side(self.source.side)
    heli.set_side_material(self.board.map.templates.get_side_material(self.source.side, self.board.map.templates.MATERIAL_METALLIC))

func _drop_the_bombu_man() -> void:
    self.impact.emit()

func _finish() -> void:
    self.finished.emit()
    self.queue_free()
