class_name TileDamagedEvent
extends BoardDomainEvent


var position: Vector2i
var layer: StringName
var template_key: String
var rotation: int


func _init(new_position: Vector2i, new_layer: StringName, new_template_key: String, new_rotation: int) -> void:
	self.position = new_position
	self.layer = new_layer
	self.template_key = new_template_key
	self.rotation = new_rotation
