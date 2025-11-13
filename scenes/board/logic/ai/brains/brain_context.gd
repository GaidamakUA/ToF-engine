class_name BrainContext

var entity_tile: MapTile
var enemy_buildings: Array[MapTile]
var enemy_units: Array[MapTile]
var own_buildings: Array[MapTile]
var own_units: Array[MapTile]
var ap: int
var board: Board

func _init(_entity_tile: MapTile,
           _enemy_buildings: Array[MapTile],
           _enemy_units: Array[MapTile],
           _own_buildings: Array[MapTile],
           _own_units: Array[MapTile],
           _ap: int,
           _board: Board) -> void:
    entity_tile = _entity_tile
    enemy_buildings = _enemy_buildings
    enemy_units = _enemy_units
    own_buildings = _own_buildings
    own_units = _own_units
    ap = _ap
    board = _board
