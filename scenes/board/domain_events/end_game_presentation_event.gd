class_name EndGamePresentationEvent
extends ScriptPresentationEvent


var winning_side: String


func _init(new_winning_side: String) -> void:
	self.winning_side = new_winning_side
