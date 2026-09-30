class_name LockPresentationEvent
extends ScriptPresentationEvent


enum Target {
	HUD,
	STORY,
}

var target: Target
var locked: bool


func _init(new_target: Target, is_locked: bool) -> void:
	self.target = new_target
	self.locked = is_locked
