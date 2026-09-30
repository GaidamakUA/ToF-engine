extends AbstractAction
class_name MoveAction

var unit: MapTile
var movement_path: Array[String] = []


func _init(unit_tile: MapTile, target_tile: MapTile, movement_path_val: Array[String]) -> void:
    self.unit = unit_tile
    self.target = target_tile
    self.movement_path = movement_path_val


func perform(model: BoardModel, wait_for_presentation: Callable = Callable()) -> void:
    model.move_unit(self.unit.position, self.target.position)
    if wait_for_presentation.is_valid():
        await wait_for_presentation.call()


func _to_string() -> String:
    return str(self.unit.position) + " moves to " + str(self.target.position)


func _get_move_cost() -> int:
    return max(0, self.movement_path.size() - 1)
