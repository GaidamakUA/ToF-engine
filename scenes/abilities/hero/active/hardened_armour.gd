extends ActiveAbility

var tiles_in_range: Dictionary[String, MapTile] = {}
var units_in_range: Array[MapTile] = []


func _execute(board: Board, position: Vector2i) -> void:
    var source_tile: MapTile

    if board.selected_tile == null:
        source_tile = board.map.model.get_tile(position)
    else:
        source_tile = board.selected_tile

    self._get_units_in_range(source_tile, self.source.side)

    for unit_tile in self.units_in_range:
        unit_tile.unit.tile.apply_modifier("armor", 1)
        board.bless_a_tile(unit_tile)

func _get_units_in_range(tile: MapTile, side: String) -> void:
    self.tiles_in_range.clear()
    self.units_in_range.clear()
    self.tiles_in_range[self._get_key(tile)] = tile

    self._expand_from_tile(tile, 2, side)

func _expand_from_tile(tile: MapTile, depth: int, side: String) -> void:
    if depth < 1:
        return

    var key: String

    for neighbour: MapTile in tile.neighbours.values():
        key = self._get_key(neighbour)

        if not self.tiles_in_range.has(key):
            self.tiles_in_range[key] = neighbour

            if neighbour.has_friendly_unit(side) and neighbour.unit.tile != self.source:
                self.units_in_range.append(neighbour)

            self._expand_from_tile(neighbour, depth - 1, side)

func _get_key(tile: MapTile) -> String:
    return str(tile.position.x) + "_" + str(tile.position.y)
