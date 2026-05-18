extends SettingsItem
class_name SettingsText


@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var settings: SettingsService = Settings as SettingsService

@onready var label: Label = $"label"
@onready var text_input: LineEdit = $"text"

@export var unavailable: bool = false
@export var option_name: String = ""
@export var option_key: String = ""
@export var help_tip: String = ""
@export var placeholder: String = ""
@export var is_int: bool = true

func _ready() -> void:
	self.label.set_text(self.option_name)
	self._read_setting()
	self.text_input.set_editable(not self.unavailable)
	self.text_input.set_placeholder(self.placeholder)

func _read_setting() -> void:
	var value: Variant = self.settings.get_option(self.option_key)

	self.text_input.set_text(str(value))

func _on_text_text_changed(_text: String) -> void:
	var new_value: Variant = self.text_input.get_text()
	if is_int:
		new_value = new_value.to_int()
	self.settings.set_option(self.option_key, new_value)
	self.audio.play("menu_click")


func _show_help() -> void:
	if self.help_tip != "":
		help_requested.emit(help_tip)
	else:
		self._clear_help()

func _clear_help() -> void:
	clear_help_requested.emit()
