extends ActiveHeroAbility


func _execute_model(_model: BoardModel, source: Variant, origin_tile: MapTile, _position: Vector2i) -> Array[Vector2i]:
    var affected: Array[Vector2i] = []
    for neighbour: MapTile in origin_tile.neighbours.values():
        if not neighbour.has_friendly_unit(source.side):
            continue
        var unit: BaseUnit = neighbour.unit.tile
        if unit.unit_class in ["tank", "mobile_infantry"]:
            unit.state.apply_modifier("attack_air", true)
            affected.append(neighbour.position)
        elif unit.unit_class != "rocket_artillery":
            unit.state.apply_modifier("attack", 1)
            affected.append(neighbour.position)
    return affected
