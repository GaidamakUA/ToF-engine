extends ActiveAbility

@export var unit_template := "blue_infantry"

var deep_strike_executor_template: PackedScene = preload("res://scenes/abilities/hero/active/deep_strike_executor.tscn")

func _execute(board: Board, position: Vector2i) -> void:
    var executor: DeepStrikeExecutor = self.deep_strike_executor_template.instantiate()

    executor.set_up(board, position, self.source, self.unit_template)
    board.ability_markers.add_child(executor)
    executor.set_position(board.map.map_to_local(position))

func is_tile_applicable(tile: MapTile, _source_tile: MapTile) -> bool:
    return tile.can_acommodate_unit()
