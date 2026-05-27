extends Node2D
class_name EndTurnView

@onready var progress: ProgressBar = $"background/progress"

func reset() -> void:
    self.progress.value = 0

func set_progress(value: float) -> void:
    self.progress.value = value
