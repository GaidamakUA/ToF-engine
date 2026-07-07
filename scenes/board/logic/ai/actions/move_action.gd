extends AbstractAction
class_name MoveAction

var unit: MapTile
var movement_path: Array[String] = []


func _init(unit_tile: MapTile, target_tile: MapTile, movement_path_val: Array[String]) -> void:
    self.unit = unit_tile
    self.target = target_tile
    self.movement_path = movement_path_val


func perform(model: BoardModel) -> void:
    var result := model.move_unit_along_path(self.unit, self.target, self._get_move_cost(), self.movement_path)
    self._present_movement_result(model, result)
    await model.action_pacer.wait_after(result)


func _to_string() -> String:
    return str(self.unit.position) + " moves to " + str(self.target.position)


func _get_move_cost() -> int:
    return max(0, self.movement_path.size() - 1)
