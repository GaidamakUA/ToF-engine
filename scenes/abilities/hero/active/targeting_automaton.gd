extends ActiveHeroAbility


func _execute(board: Board, source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    var unit: BaseUnit

    if origin_tile == null:
        origin_tile = board.map.model.get_tile(position)

    for neighbour: MapTile in origin_tile.neighbours.values():
        if neighbour.has_friendly_unit(source.side):
            unit = neighbour.unit.tile
            if unit.unit_class in ["tank", "mobile_infantry"]:
                unit.apply_modifier("attack_air", true)
                board.bless_a_tile(neighbour)
            elif unit.unit_class != "rocket_artillery":
                unit.apply_modifier("attack", 1)
                board.bless_a_tile(neighbour)
