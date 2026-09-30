extends ActiveHeroAbility

func _execute_model(model: BoardModel, _source: Variant, origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    if model.relocate_unit(origin_tile.position, position):
        return [origin_tile.position, position]
    return []

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return tile.can_acommodate_unit()
