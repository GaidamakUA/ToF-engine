extends Control
class_name CinematicBars

@onready var animations: AnimationPlayer = $"animations"

var is_extended: bool = false

func show_bars() -> void:
    self.animations.play("show")
    self.is_extended = true

func hide_bars() -> void:
    self.animations.play("hide")
    self.is_extended = false
