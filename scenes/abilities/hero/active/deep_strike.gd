extends ActiveHeroAbility

@export var unit_template: String = "blue_infantry"

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    var unit: BaseUnit = model._spawn_unit(position, self.unit_template, source.side, 90)
    if unit == null:
        return []
    unit.state.remove_moves()
    unit.team = source.team
    model.abilities.apply_passive_modifiers(unit)
    return [position]

func is_tile_applicable(tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return tile.can_acommodate_unit()
