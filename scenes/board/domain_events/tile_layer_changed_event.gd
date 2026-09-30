class_name TileLayerChangedEvent
extends BoardDomainEvent


var position: Vector2i
var layer: StringName
var rotation: int
var effect: StringName


func _init(new_position: Vector2i, new_layer: StringName, new_rotation: int, new_effect: StringName = &"") -> void:
	self.position = new_position
	self.layer = new_layer
	self.rotation = new_rotation
	self.effect = new_effect
