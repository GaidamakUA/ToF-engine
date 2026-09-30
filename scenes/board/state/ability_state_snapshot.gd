class_name AbilityStateSnapshot
extends RefCounted


var index: int
var disabled: bool
var cooldown: int


func _init(new_index: int, is_disabled: bool, cooldown_turns: int) -> void:
	self.index = new_index
	self.disabled = is_disabled
	self.cooldown = cooldown_turns
