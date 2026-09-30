extends AbstractAction
class_name CaptureAction

var unit: MapTile
var interaction: MapTile
var movement_path: Array[String] = []

func _init(unit_tile: MapTile, interaction_tile: MapTile, target_tile: MapTile, movement_path_val: Array[String]) -> void:
    self.unit = unit_tile
    self.interaction = interaction_tile
    self.target = target_tile
    self.movement_path = movement_path_val

func perform(model: BoardModel, wait_for_presentation: Callable = Callable()) -> void:
    if self.interaction != null:
        model.move_unit(self.unit.position, self.interaction.position)
        if wait_for_presentation.is_valid():
            await wait_for_presentation.call()
        model.capture_building(self.interaction.position, self.target.position)
    else:
        model.capture_building(self.unit.position, self.target.position)
    if wait_for_presentation.is_valid():
        await wait_for_presentation.call()

func _to_string() -> String:
    var message: String = str(self.unit.position) + " captures " + str(self.target.position)
    if self.interaction != null:
        message += " from " + str(self.interaction.position)
    return message


func _get_move_cost() -> int:
    return max(0, self.movement_path.size() - 1)
