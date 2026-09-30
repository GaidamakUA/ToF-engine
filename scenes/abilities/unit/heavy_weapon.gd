extends ActiveUnitAbility

@export var damage: int = 8

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    if model.damage_unit(position, self.damage, false, source.model_id):
        return [position]
    return []

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, source: Variant) -> bool:
    return tile.has_enemy_unit(source.side, source.team)
