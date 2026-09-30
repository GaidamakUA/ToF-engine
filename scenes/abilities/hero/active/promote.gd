extends ActiveHeroAbility

func _execute_model(model: BoardModel, _source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    if model.level_up_unit(position):
        return [position]
    return []

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, source: Variant) -> bool:
    return tile.has_friendly_unit(source.side) and tile.unit.tile != source and not tile.unit.tile.is_max_level()
