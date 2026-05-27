extends Control
class_name TriggerTypeSelector

var trigger_name: String = ""
var trigger_data: Dictionary = {}

@onready var audio: AudioService = SimpleAudioLibrary as AudioService

signal trigger_data_updated(trigger_name: String, trigger_data: Dictionary)
@warning_ignore("unused_signal")
signal trigger_removal_requested(trigger_name: String)
@warning_ignore("unused_signal")
signal picker_requested(context: Dictionary)

func _ready() -> void:
    for button: BaseButton in $"buttons".get_children():
        button.pressed.connect(self._on_type_pressed.bind(button))
        
func show_panel() -> void:
    self.show()

func _on_type_pressed(button: BaseButton) -> void:
    self.audio.play("menu_click")
    self.trigger_data["type"] = str(button.name)
    self.trigger_data_updated.emit(self.trigger_name, self.trigger_data)


func fill_trigger_data(new_trigger_name: String, new_trigger_data: Dictionary) -> void:
    self.trigger_name = new_trigger_name
    self.trigger_data = new_trigger_data
