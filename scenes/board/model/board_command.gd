class_name BoardCommand
extends RefCounted


var animation: BoardAnimation.Kind
var source_id: int
var origin: Vector2i
var target: Vector2i
var path: Array[Vector2i]
var directions: Array[String]
var apply: Callable


func _init(
	command_animation: BoardAnimation.Kind,
	command_apply: Callable,
	command_source_id: int = 0,
	command_origin: Vector2i = Vector2i(-1, -1),
	command_target: Vector2i = Vector2i(-1, -1),
	command_path: Array[Vector2i] = [],
	command_directions: Array[String] = []
) -> void:
	self.animation = command_animation
	self.apply = command_apply
	self.source_id = command_source_id
	self.origin = command_origin
	self.target = command_target
	self.path = command_path.duplicate()
	self.directions = command_directions.duplicate()
