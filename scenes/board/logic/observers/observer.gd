class_name Observer

var suspended := false
var observed_event_type: Resource

func observe(event: BoardDomainEvent) -> void:
    if self.suspended:
        return

    self._observe(event)

func _observe(_event: BoardDomainEvent) -> void:
    return

func activate() -> void:
    self.suspended = false

func deactivate() -> void:
    self.suspended = true
