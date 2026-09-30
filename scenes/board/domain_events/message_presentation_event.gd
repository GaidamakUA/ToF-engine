class_name MessagePresentationEvent
extends ScriptPresentationEvent


var text: String
var portrait_key: String
var sound_key: String
var actor_name: String
var side: String
var colour: String
var font_size: int


func _init(
	new_text: String,
	new_portrait_key: String,
	new_sound_key: String,
	new_actor_name: String,
	new_side: String,
	new_colour: String,
	new_font_size: int
) -> void:
	self.text = new_text
	self.portrait_key = new_portrait_key
	self.sound_key = new_sound_key
	self.actor_name = new_actor_name
	self.side = new_side
	self.colour = new_colour
	self.font_size = new_font_size
