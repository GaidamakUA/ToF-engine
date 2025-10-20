class_name Observer

var board: Board
var suspended := false
var observed_event_type: Events.Type

func _init(_board: Board) -> void:
    self.board = _board

func observe(event: BaseEvent) -> void:
    if self.suspended:
        return

    self._observe(event)

func _observe(_event: BaseEvent) -> void:
    return

func activate() -> void:
    self.suspended = false

func deactivate() -> void:
    self.suspended = true
