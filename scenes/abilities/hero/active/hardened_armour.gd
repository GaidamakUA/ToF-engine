extends ActiveHeroAbility

var tiles_in_range: Dictionary[String, MapTile] = {}
var units_in_range: Array[MapTile] = []


func _execute(board: Board, source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    if origin_tile == null:
        origin_tile = board.map.model.get_tile(position)

    self._get_units_in_range(origin_tile, source.side, source)

    for unit_tile in self.units_in_range:
        unit_tile.unit.tile.apply_modifier("armor", 1)
        board.bless_a_tile(unit_tile)

func _execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    if origin_tile == null:
        origin_tile = model.get_tile_at(position)

    self._get_units_in_range(origin_tile, source.side, source)

    for unit_tile in self.units_in_range:
        unit_tile.unit.tile.apply_modifier("armor", 1)
        self._append_tile_effect(result, "bless", unit_tile)

    return result

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
