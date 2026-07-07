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


func merge_from(other: CommandResult) -> void:
	if other == null:
		return
	if other.command_name.ends_with("_failed"):
		self.command_name = other.command_name
	elif self.command_name == "" and other.command_name != "":
		self.command_name = other.command_name
	self.events.append_array(other.events)
	self.delay = max(self.delay, other.delay)
	for key: String in other.metadata.keys():
		self.metadata[key] = other.metadata[key]
