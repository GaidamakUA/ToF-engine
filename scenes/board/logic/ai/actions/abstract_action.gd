class_name AbstractAction
var value: int = 0
var target: MapTile = null

func perform(_model: BoardModel) -> void:
    return

func _present_movement_result(model: BoardModel, result: CommandResult) -> void:
    if result.command_name != "move_unit" or result.events.is_empty():
        return
    if model.board != null and model.board.has_method(&"_animate_unit_move_result"):
        model.board._animate_unit_move_result(result)
        return
    var event: UnitMovedEvent = null
    for result_event: BaseEvent in result.events:
        if result_event is UnitMovedEvent:
            event = result_event as UnitMovedEvent
            break
    if event != null and event.unit != null:
        event.unit.call_deferred("emit_signal", "move_finished")

func _to_string() -> String:
    return "generic abstract action"
