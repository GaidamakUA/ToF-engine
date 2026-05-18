extends TextureButton
class_name SaveEntryButton

@onready var label: Label = $"label"
@onready var stars: Node2D = $"stars"

var save_id: int = 0
var map_name: String = ""
var turn_no: int = 0
var created_at: Dictionary = {}

var bound_object: Object = null
var bound_method: StringName = &""

func _ready() -> void:
	self.hide_stars()
	self.label.set_message_translation(false)
	self.label.notification(NOTIFICATION_TRANSLATION_CHANGED)

func fill_data(fill_name: String, map_save_id: int, map_turn_no: int, map_created_at: Dictionary) -> void:
	self.map_name = fill_name
	self.save_id = map_save_id
	self.turn_no = map_turn_no
	self.created_at = map_created_at

	self.refresh_label()

func refresh_label() -> void:
	var new_text: String = self.map_name + " - " + tr("TR_TURN") + " " + str(self.turn_no) + " - "
	new_text += str(self.created_at["year"]) + "-" + str(self.created_at["month"]) + "-" + str(self.created_at["day"])
	new_text += " " + str(self.created_at["hour"]) + ":"
	if int(self.created_at["minute"]) < 10:
		new_text += "0"
	new_text += str(self.created_at["minute"])
	self.label.set_text(new_text)

func bind_method(new_object: Object, new_method: StringName) -> void:
	self.bound_object = new_object
	self.bound_method = new_method

func _on_button_pressed() -> void:
	if self.bound_object != null:
		self.bound_object.call_deferred(self.bound_method, self.save_id, self)
		self.show_stars()

func show_stars() -> void:
	self.stars.show()

func hide_stars() -> void:
	self.stars.hide()
