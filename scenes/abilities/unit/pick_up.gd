extends ActiveUnitAbility

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    var tile: MapTile = model._get_tile_at(position)
    if tile == null or not tile.unit.is_present():
        return []
    source.passenger = tile.unit.tile
    tile.unit.release()
    source.state.remove_moves()
    return [position]

func _is_visible(_model: BoardModel, source: Variant = null) -> bool:
    if source == null:
        return false

    if source.passenger != null:
        return false

    return true

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, source: Variant) -> bool:
    var applicable_types := ["infantry"]
    if source.level == 3:
        applicable_types.append("mobile_infantry")
    if tile.has_friendly_unit(source.side):
        return tile._get_unit().unit_class in applicable_types
    return false
