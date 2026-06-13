extends ActiveUnitAbility

const MEDKIT_UNITS: Array[String] = [
    "infantry",
    "mobile_infantry",
    "hero",
    "npc",
]

@export var heal: int = 5

func _execute(board: Board, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)
    var target_unit: BaseUnit = tile._get_unit()
    target_unit.sfx_effect("spawn")

    target_unit.heal(self.heal)
    board.heal_a_tile(tile)
    source.gain_exp()

func is_tile_applicable(tile: MapTile, origin_tile: MapTile, source: Variant) -> bool:
    if not tile.has_friendly_unit(source.side) or tile == origin_tile:
        return false

    var target_unit: BaseUnit = tile._get_unit()
    return target_unit.unit_class in self.MEDKIT_UNITS and target_unit.is_damaged()

func get_cost(source: Variant = null) -> int:
    if source == null or source.level == 0:
        return super.get_cost(source)

    return 0
