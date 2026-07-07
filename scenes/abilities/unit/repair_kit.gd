extends ActiveUnitAbility

const REPAIR_UNITS: Array[String] = [
    "tank",
    "heli",
    "rocket_artillery",
    "scout",
]

@export var heal: int = 5

func _execute(board: Board, source: Variant, _origin_tile: MapTile, position: Vector2i) -> void:
    var tile := board.map.model.get_tile(position)
    var target_unit: BaseUnit = tile._get_unit()
    target_unit.sfx_effect("spawn")

    target_unit.heal(self.heal)
    board.heal_a_tile(tile)
    source.gain_exp()

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := CommandResult.new("use_ability")
    var tile := model.get_tile_at(position)
    var target_unit: BaseUnit = tile._get_unit()
    target_unit.heal(self.heal)
    source.gain_exp()
    self._append_tile_effect(result, "heal", tile)
    return result

func is_tile_applicable(tile: MapTile, origin_tile: MapTile, source: Variant) -> bool:
    if not tile.has_friendly_unit(source.side) or tile == origin_tile:
        return false

    var target_unit: BaseUnit = tile._get_unit()
    return target_unit.unit_class in self.REPAIR_UNITS and target_unit.is_damaged()

func _is_visible(_board: Board, _source: Variant = null) -> bool:
    return true

func get_cost(source: Variant = null) -> int:
    if source == null or source.level < 2:
        return super.get_cost(source)

    if source.level == 2:
        return 10
    return 5
