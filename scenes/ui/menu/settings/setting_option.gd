extends SettingsItem
class_name SettingsOption


@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var settings: SettingsService = Settings as SettingsService

@onready var label: Label = $"label"
@onready var button: TextureButton = $"toggle"
@onready var button_label: Label = $"toggle/label"

@export var unavailable: bool = false
@export var option_name: String = ""
@export var option_key: String = ""
@export var help_tip: String = ""

func _ready() -> void:
	self.label.set_text(self.option_name)
	self._read_setting()
	self.button.set_disabled(self.unavailable)

func _read_setting() -> void:
	var value: Variant = self.settings.get_option(self.option_key)

	match value:
		null:
			self.button_label.set_text("???")
			self.button.set_disabled(true)
		true:
			self.button_label.set_text("TR_ON")
		false:
			self.button_label.set_text("TR_OFF")

func _on_toggle_button_pressed() -> void:
	self.settings.set_option(self.option_key, not self.settings.get_option(self.option_key))
	self.audio.play("menu_click")
	self._read_setting()


func _show_help() -> void:
	if self.help_tip != "":
		help_requested.emit(help_tip)
	else:
		self._clear_help()

func _clear_help() -> void:
	clear_help_requested.emit()
