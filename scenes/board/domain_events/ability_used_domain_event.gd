class_name AbilityUsedDomainEvent
extends BoardDomainEvent


var source_id: int
var origin: Vector2i
var target: Vector2i
var animation: BoardAnimation.Kind
var affected_positions: Array[Vector2i]
var ability_key: String
var consumed: bool = false


func _init(
	new_source_id: int,
	new_origin: Vector2i,
	new_target: Vector2i,
	new_animation: BoardAnimation.Kind = BoardAnimation.Kind.NONE,
	new_affected_positions: Array[Vector2i] = [],
	new_ability_key: String = ""
) -> void:
	self.source_id = new_source_id
	self.origin = new_origin
	self.target = new_target
	self.animation = new_animation
	self.affected_positions = new_affected_positions.duplicate()
	self.ability_key = new_ability_key
