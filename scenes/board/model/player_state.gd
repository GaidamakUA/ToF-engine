class_name PlayerState
extends RefCounted


var type: String
var side: String
var team: Variant
var ap: int
var alive: bool
var heroes: Dictionary[int, HeroUnit] = {}
var peer_id: Variant


func _init(
	new_type: String,
	new_side: String,
	is_alive: bool = true,
	new_team: Variant = null,
	new_peer_id: Variant = null,
	new_ap: int = 0
) -> void:
	self.type = new_type
	self.side = new_side
	self.alive = is_alive
	self.team = new_team
	self.peer_id = new_peer_id
	self.ap = new_ap
