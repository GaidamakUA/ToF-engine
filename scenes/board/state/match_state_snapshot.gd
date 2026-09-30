class_name MatchStateSnapshot
extends RefCounted


var current_player: int
var turn: int
var has_player_moved: bool
var turn_limit: int
var time_limit: int
var players: Array[PlayerStateSnapshot]


func _init(
	new_current_player: int,
	new_turn: int,
	player_moved: bool,
	new_players: Array[PlayerStateSnapshot],
	new_turn_limit: int = 0,
	new_time_limit: int = 0
) -> void:
	self.current_player = new_current_player
	self.turn = new_turn
	self.has_player_moved = player_moved
	self.players = new_players.duplicate()
	self.turn_limit = new_turn_limit
	self.time_limit = new_time_limit
