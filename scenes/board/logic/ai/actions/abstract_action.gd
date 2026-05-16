class_name AbstractAction
var value: int = 0
var target: MapTile = null

func perform(_board: Board) -> void:
    return

func _to_string() -> String:
    return "generic abstract action"
