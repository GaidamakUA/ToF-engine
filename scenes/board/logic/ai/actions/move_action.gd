extends AbstractAction
class_name MoveAction

var unit: MapTile
var path_length: int


func _init(unit_tile: MapTile, target_tile: MapTile, path_length_val: int) -> void:
    self.unit = unit_tile
    self.target = target_tile
    self.path_length = path_length_val


func perform(board: Board) -> void:
    var unit_object: BaseUnit = self.unit.unit.tile

    board.select_tile(self.unit.position)
    board.select_tile(self.target.position)
    board.unselect_tile()

    if unit_object and not unit_object.is_queued_for_deletion():
        await unit_object.move_finished


func _to_string() -> String:
    return str(self.unit.position) + " moves to " + str(self.target.position)
