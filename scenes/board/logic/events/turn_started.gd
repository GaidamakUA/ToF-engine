extends BoardDomainEvent
class_name TurnStartedEvent

var turn_no: int
var player_id: int


func _init(new_turn_no: int, new_player_id: int) -> void:
	self.turn_no = new_turn_no
	self.player_id = new_player_id
