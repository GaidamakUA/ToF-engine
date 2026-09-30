extends ActiveUnitAbility

func _execute_model(_model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    source.state.replenish_moves(source.get_stats_with_modifiers())
    return [position]
