extends AbstractAction
class_name AttackAction

var unit: MapTile
var interaction: MapTile
var movement_path: Array[String] = []

func _init(unit_tile: MapTile, interaction_tile: MapTile, target_tile: MapTile, movement_path_val: Array[String]) -> void:
    self.unit = unit_tile
    self.interaction = interaction_tile
    self.target = target_tile
    self.movement_path = movement_path_val

func perform(model: BoardModel) -> void:
    var result: CommandResult = null
    if self.interaction != null:
        var move_result := model.move_unit_along_path(self.unit, self.interaction, self._get_move_cost(), self.movement_path)
        self._present_movement_result(model, move_result)
        await model.action_pacer.wait_after(move_result)
        result = model.interact_unit(self.interaction, null, self.target)
    else:
        result = model.interact_unit(self.unit, null, self.target)
    if result != null:
        await model.action_pacer.wait_after(result)

func _to_string() -> String:
    var message: String = str(self.unit.position) + " attacks " + str(self.target.position)
    if self.interaction != null:
        message += " from " + str(self.interaction.position)
    return message


func _get_move_cost() -> int:
    return max(0, self.movement_path.size() - 1)
