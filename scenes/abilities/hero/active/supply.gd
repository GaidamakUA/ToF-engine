extends ActiveHeroAbility

const HEAL := 5

func _execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, _position: Vector2i) -> Array[Vector2i]:
    var affected: Array[Vector2i] = []
    for neighbour: MapTile in origin_tile.neighbours.values():
        if neighbour.has_friendly_unit(source.side) and model.heal_unit(neighbour.position, self.HEAL):
            affected.append(neighbour.position)
    return affected
