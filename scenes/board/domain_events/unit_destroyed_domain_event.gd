class_name UnitDestroyedDomainEvent
extends BoardDomainEvent


var unit_id: int
var position: Vector2i
var template_key: String
var unit_side: String
var attacker_id: int


func _init(
	new_unit_id: int,
	new_position: Vector2i,
	new_template_key: String,
	new_unit_side: String = "",
	new_attacker_id: int = 0
) -> void:
	self.unit_id = new_unit_id
	self.position = new_position
	self.template_key = new_template_key
	self.unit_side = new_unit_side
	self.attacker_id = new_attacker_id
