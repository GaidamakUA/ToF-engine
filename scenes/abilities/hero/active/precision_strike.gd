extends ActiveHeroAbility

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    var tile: MapTile = model._get_tile_at(position)
    if tile == null:
        return []
    var affected: Array[Vector2i] = [position]
    model.damage_unit(position, 5, true, source.model_id)
    for neighbour: MapTile in tile.neighbours.values():
        affected.append(neighbour.position)
        model.damage_unit(neighbour.position, 5, true, source.model_id)
    return affected

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, source: Variant) -> bool:
    if tile.unit.is_present():
        return tile.unit.tile != source
    return true
