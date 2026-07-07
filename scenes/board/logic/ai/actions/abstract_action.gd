class_name AbstractAction
var value: int = 0
var target: MapTile = null

func perform(_model: BoardModel) -> void:
    return

func _present_movement_result(model: BoardModel, result: CommandResult) -> void:
    model.present_action_result(result)

func _to_string() -> String:
    return "generic abstract action"
