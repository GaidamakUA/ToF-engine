class_name FocusPresentationEvent
extends ScriptPresentationEvent


var position: Vector2i
var zoom: float


func _init(new_position: Vector2i, new_zoom: float = -1.0) -> void:
	self.position = new_position
	self.zoom = new_zoom
