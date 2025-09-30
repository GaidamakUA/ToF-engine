extends ActiveAbility

const HEAL := 5

func _execute(board: Board, position: Vector2i) -> void:
    var source_tile: MapTile

    if board.selected_tile == null:
        source_tile = board.map.model.get_tile(position)
    else:
        source_tile = board.selected_tile

    for neighbour: MapTile in source_tile.neighbours.values():
        if neighbour.has_friendly_unit(self.source.side):
            neighbour.unit.tile.heal(self.HEAL)
            board.heal_a_tile(neighbour)
