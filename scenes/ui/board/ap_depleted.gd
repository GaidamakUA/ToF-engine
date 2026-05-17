extends Node2D
class_name ApDepletedView

@onready var animations: AnimationPlayer = $"animations"

func flash() -> void:
	self.animations.play("flash")
