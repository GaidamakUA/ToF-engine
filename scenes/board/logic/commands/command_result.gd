class_name CommandResult
extends RefCounted


var command_name: String = ""
var events: Array[BaseEvent] = []
var delay: float = 0.0
var metadata: Dictionary[String, Variant] = {}


func _init(new_command_name: String = "") -> void:
	self.command_name = new_command_name


func add_event(event: BaseEvent) -> void:
	self.events.append(event)
