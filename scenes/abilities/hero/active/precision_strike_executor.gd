extends Node3D
class_name PrecisionStrikeExecutor

const DAMAGE := 5

var strike_position: Vector2i
var source: BaseUnit
var board: Board

@export
var heli: Heli

func _ready() -> void:
    heli.sfx_effect("move")

func set_up(_board: Board, _position: Vector2i, _source: BaseUnit) -> void:
    self.board = _board
    self.strike_position = _position
    self.source = _source

    self.set_side_material()

func set_side_material() -> void:
    heli.set_side(self.source.side)
    heli.set_side_material(self.board.map.templates.get_side_material(self.source.side, self.board.map.templates.MATERIAL_METALLIC))

func _drop_the_bombu_man() -> void:
    var tile := self.board.map.model.get_tile(self.strike_position)

    self._bomb_tile(tile)

    for neighbour: MapTile in tile.neighbours.values():
        self._bomb_tile(neighbour)

func _bomb_tile(tile: MapTile) -> void:
    heli.sfx_effect("attack")

    if tile.unit.is_present():
        tile.unit.tile.receive_direct_damage(self.DAMAGE)
        if not tile.unit.tile.is_alive():
            self.board.destroy_unit_on_tile(tile)

    self.board.explode_a_tile(tile)
    board.refresh_tile_selection()
