class_name PlayerStateSnapshot
extends RefCounted


var type: String
var side: String
var team: Variant
var ap: int
var alive: bool
var peer_id: Variant


func _init(
	new_type: String,
	new_side: String,
	new_team: Variant,
	new_ap: int,
	new_alive: bool,
	new_peer_id: Variant
) -> void:
	self.type = new_type
	self.side = new_side
	self.team = new_team
	self.ap = new_ap
	self.alive = new_alive
	self.peer_id = new_peer_id
