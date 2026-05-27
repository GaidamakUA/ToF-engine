extends SettingsItem
class_name SettingsOptionRotating


@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var settings: SettingsService = Settings as SettingsService

@onready var label: Label = $"label"
@onready var button: TextureButton = $"toggle"
@onready var button_label: Label = $"toggle/label"

@export var unavailable: bool = false
@export var option_name: String = ""
@export var option_key: String = ""
@export var help_tip: String = ""
@export var available_values: Array[Variant] = ["first", "second"]

func _ready() -> void:
    self.label.set_text(self.option_name)
    self._read_setting()
    self.button.set_disabled(self.unavailable)

func _read_setting() -> void:
    var value: Variant = self.settings.get_option(self.option_key)

    for known_value: Variant in self.available_values:
        if value == known_value:
            if known_value is String:
                self.button_label.set_text(known_value)
            else:
                self.button_label.set_text(str(known_value))
            return

    self.button_label.set_text("???")
    self.button.set_disabled(true)

func _on_toggle_button_pressed() -> void:
    var value: Variant = self.settings.get_option(self.option_key)

    var index: int = self.available_values.find(value)

    if index < 0:
        return

    if (index + 1) < self.available_values.size():
        value = self.available_values[index + 1]
    else:
        value = self.available_values[0]

    self.settings.set_option(self.option_key, value)
    self.audio.play("menu_click")
    self._read_setting()


func _show_help() -> void:
    if self.help_tip != "":
        help_requested.emit(help_tip)
    else:
        self._clear_help()

func _clear_help() -> void:
    clear_help_requested.emit()
