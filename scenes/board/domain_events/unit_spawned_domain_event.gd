class_name UnitSpawnedDomainEvent
extends BoardDomainEvent


var unit_id: int
var position: Vector2i
var template_key: String
var side: String


func _init(new_unit_id: int, new_position: Vector2i, new_template_key: String, new_side: String) -> void:
	self.unit_id = new_unit_id
	self.position = new_position
	self.template_key = new_template_key
	self.side = new_side
