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
	tile.unit.tile.sfx_effect("spawn")

	tile.unit.tile.heal(self.heal)
	board.heal_a_tile(tile)
	self.source.gain_exp()

func is_tile_applicable(tile: MapTile, source_tile: MapTile) -> bool:
	return tile.has_friendly_unit(self.source.side) and tile != source_tile and (tile.unit.tile.unit_class in self.MEDKIT_UNITS) and tile.unit.tile.is_damaged()

func get_cost() -> int:
	if self.source == null or self.source.level == 0:
		return super.get_cost()

	return 0
