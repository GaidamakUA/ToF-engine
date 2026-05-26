extends ActiveUnitAbility

const MEDKIT_UNITS: Array[String] = [
	"infantry",
	"mobile_infantry",
	"hero",
	"npc",
]

@export var heal: int = 5

func _execute(board: Board, position: Vector2i) -> void:
	var tile := board.map.model.get_tile(position)
	var target_unit: BaseUnit = tile._get_unit()
	target_unit.sfx_effect("spawn")

	target_unit.heal(self.heal)
	board.heal_a_tile(tile)
	self.source.gain_exp()

func is_tile_applicable(tile: MapTile, source_tile: MapTile) -> bool:
	if not tile.has_friendly_unit(self.source.side) or tile == source_tile:
		return false

	var target_unit: BaseUnit = tile._get_unit()
	return target_unit.unit_class in self.MEDKIT_UNITS and target_unit.is_damaged()

func get_cost() -> int:
	if self.source == null or self.source.level == 0:
		return super.get_cost()

	return 0
