extends ActiveHeroAbility

const HEAL := 5

func _execute(board: Board, source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    if origin_tile == null:
        origin_tile = board.map.model.get_tile(position)

    for neighbour: MapTile in origin_tile.neighbours.values():
        if neighbour.has_friendly_unit(source.side):
            neighbour.unit.tile.heal(self.HEAL)
            board.heal_a_tile(neighbour)

func _execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    if origin_tile == null:
        origin_tile = model.get_tile_at(position)

    for neighbour: MapTile in origin_tile.neighbours.values():
        if neighbour.has_friendly_unit(source.side):
            neighbour.unit.tile.heal(self.HEAL)
            self._append_tile_effect(result, "heal", neighbour)

    return result
