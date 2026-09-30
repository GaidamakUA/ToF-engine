class_name AttackResolvedEvent
extends BoardDomainEvent


var attacker_position: Vector2i
var defender_position: Vector2i
var retaliated: bool
var attacker_id: int
var defender_id: int


func _init(
	new_attacker_position: Vector2i,
	new_defender_position: Vector2i,
	did_retaliate: bool,
	new_attacker_id: int = 0,
	new_defender_id: int = 0
) -> void:
	self.attacker_position = new_attacker_position
	self.defender_position = new_defender_position
	self.retaliated = did_retaliate
	self.attacker_id = new_attacker_id
	self.defender_id = new_defender_id
