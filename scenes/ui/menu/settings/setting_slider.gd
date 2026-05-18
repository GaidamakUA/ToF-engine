extends SettingsItem
class_name SettingsSlider


@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var settings: SettingsService = Settings as SettingsService

@onready var label: Label = $"label"
@onready var slider_value: Label = $"slider_value"
@onready var slider: HSlider = $"slider"

@export var option_name: String = ""
@export var option_key: String = ""
@export var help_tip: String = ""

@export var step: float = 1.0
@export var min_value: float = 0.0
@export var max_value: float = 10.0

var prepared: bool = false


func _ready() -> void:
	self.slider.step = step
	self.slider.max_value = max_value - min_value
	self.label.set_text(self.option_name)
	self._read_setting()
	self.prepared = true


func _read_setting() -> void:
	var value: float = float(self.settings.get_option(self.option_key))
	value = maxf(0.0, value - min_value)

	self.slider_value.set_text(str(int(value + min_value)))
	self.slider.set_value(value)


func _on_slider_value_changed(value: float) -> void:
	self.settings.set_option(self.option_key, int(value + min_value))
	if self.prepared:
		self.audio.play("menu_click")
	self.slider_value.set_text(str(int(value + min_value)))


func _show_help() -> void:
	if self.help_tip != "":
		help_requested.emit(help_tip)
	else:
		self._clear_help()

func _clear_help() -> void:
	clear_help_requested.emit()
