extends ActiveHeroAbility

var tiles_in_range: Dictionary[String, MapTile] = {}
var units_in_range: Array[MapTile] = []


func _execute_model(_model: BoardModel, source: Variant, origin_tile: MapTile, _position: Vector2i) -> Array[Vector2i]:
    self._get_units_in_range(origin_tile, source.side, source)
    var affected: Array[Vector2i] = []
    for unit_tile: MapTile in self.units_in_range:
        unit_tile.unit.tile.state.apply_modifier("armor", 1)
        affected.append(unit_tile.position)
    return affected

func _get_units_in_range(tile: MapTile, side: String, source: Variant) -> void:
    self.tiles_in_range.clear()
    self.units_in_range.clear()
    self.tiles_in_range[self._get_key(tile)] = tile

    self._expand_from_tile(tile, 2, side, source)

func _expand_from_tile(tile: MapTile, depth: int, side: String, source: Variant) -> void:
    if depth < 1:
        return

    var key: String

    for neighbour: MapTile in tile.neighbours.values():
        key = self._get_key(neighbour)

        if not self.tiles_in_range.has(key):
            self.tiles_in_range[key] = neighbour

            if neighbour.has_friendly_unit(side) and neighbour.unit.tile != source:
                self.units_in_range.append(neighbour)

            self._expand_from_tile(neighbour, depth - 1, side, source)

func _get_key(tile: MapTile) -> String:
    return str(tile.position.x) + "_" + str(tile.position.y)
