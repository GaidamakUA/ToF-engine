extends "res://scenes/board/logic/observers/observer.gd"

func _init(_board):
    super(_board)
    self.observed_event_type = [Events.Type.UNIT_DESTROYED]

func _observe(event):
    if event.attacker != null:
        event.attacker.score_kill()
