extends TextureButton
class_name MapPickerButton

@onready var label: Label = $"label"
@onready var downloads_label: Label = $"downloads"

var map_name: String = ""
var online_id: Variant = null
var downloads: Variant = null

var bound_object: Object = null
var bound_method: StringName = &""

var focus_object: Object = null
var focus_method: StringName = &""


func _ready() -> void:
	var _error: Error = self.connect("pressed", Callable(self, "_on_button_pressed"))
	self.label.set_message_translation(false)
	self.label.notification(NOTIFICATION_TRANSLATION_CHANGED)


func fill_data(fill_name: String, map_online_id: Variant, downloads_amount: Variant = null) -> void:
	self.map_name = fill_name
	self.online_id = map_online_id
	self.downloads = downloads_amount

	self.refresh_label()


func refresh_label() -> void:
	var new_text: String = self.map_name

	if self.online_id != null:
		new_text = str(self.online_id) + " - " + new_text

	self.label.set_text(new_text)
	if self.downloads != null:
		self.downloads_label.show()
		self.downloads_label.set_text(str(self.downloads))
	else:
		self.downloads_label.hide()


func bind_method(new_object: Object, new_method: StringName) -> void:
	self.bound_object = new_object
	self.bound_method = new_method


func bind_focus(new_object: Object, new_method: StringName) -> void:
	self.focus_object = new_object
	self.focus_method = new_method


func _get_map_id() -> Variant:
	if self.online_id == null:
		return self.map_name
	return self.online_id

func _on_button_pressed() -> void:
	if self.bound_object != null:
		self.bound_object.call_deferred(self.bound_method, self._get_map_id())


func _on_focus_entered() -> void:
	if self.focus_object != null:
		self.focus_object.call_deferred(self.focus_method, self._get_map_id())

func _on_mouse_entered() -> void:
	self._on_focus_entered()
