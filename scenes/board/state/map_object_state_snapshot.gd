class_name MapObjectStateSnapshot
extends RefCounted


var template_key: String
var rotation: int


func _init(new_template_key: String = "", new_rotation: int = 0) -> void:
	self.template_key = new_template_key
	self.rotation = new_rotation
