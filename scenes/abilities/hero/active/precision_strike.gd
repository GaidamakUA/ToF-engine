extends ActiveAbility

var precision_strike_executor_template: PackedScene = preload("res://scenes/abilities/hero/active/precision_strike_executor.tscn")


func _execute(board: Board, position: Vector2i) -> void:
    var executor: PrecisionStrikeExecutor = self.precision_strike_executor_template.instantiate()

    executor.set_up(board, position, self.source)
    board.ability_markers.add_child(executor)
    executor.set_position(board.map.map_to_local(position))

func is_tile_applicable(tile: MapTile, _source_tile: MapTile) -> bool:
    if tile.unit.is_present():
        return tile.unit.tile != self.source
    return true
