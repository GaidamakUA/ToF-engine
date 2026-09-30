extends ActiveHeroAbility

func _execute_model(model: BoardModel, _source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    var tile: MapTile = model._get_tile_at(position)
    if tile != null and tile.unit.is_present():
        var unit: BaseUnit = tile.unit.tile
        unit.state.replenish_moves(unit.get_stats_with_modifiers())
        unit.reset_cooldown()
        return [position]
    return []

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, source: Variant) -> bool:
    return tile.has_friendly_unit(source.side) and tile.unit.tile != source
