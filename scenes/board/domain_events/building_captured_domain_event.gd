class_name BuildingCapturedDomainEvent
extends BoardDomainEvent


var position: Vector2i
var old_side: String
var new_side: String


func _init(new_position: Vector2i, captured_side: String, previous_side: String = "") -> void:
	self.position = new_position
	self.old_side = previous_side
	self.new_side = captured_side
