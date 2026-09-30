class_name UnitLeveledUpDomainEvent
extends BoardDomainEvent


var unit_id: int
var position: Vector2i


func _init(new_unit_id: int, new_position: Vector2i) -> void:
	self.unit_id = new_unit_id
	self.position = new_position
