extends ActiveHeroAbility


func _execute(board: Board, position: Vector2i) -> void:
    var source_tile: MapTile
    var unit

    if board.selected_tile == null:
        source_tile = board.map.model.get_tile(position)
    else:
        source_tile = board.selected_tile

    for neighbour: MapTile in source_tile.neighbours.values():
        if neighbour.has_friendly_unit(self.source.side):
            unit = neighbour.unit.tile
            if unit.unit_class in ["tank", "mobile_infantry"]:
                unit.apply_modifier("attack_air", true)
                board.bless_a_tile(neighbour)
            elif unit.unit_class != "rocket_artillery":
                unit.apply_modifier("attack", 1)
                board.bless_a_tile(neighbour)
