extends Control
class_name StoryStepTypeSelector

var step_no: int = 0
var step_data: Dictionary = {}

@onready var audio: AudioService = SimpleAudioLibrary as AudioService

signal step_data_updated(step_no: int, step_data: Dictionary)
@warning_ignore("unused_signal")
signal step_move_requested(step_no: int, new_step_no: int)
@warning_ignore("unused_signal")
signal step_removal_requested(step_no: int)
@warning_ignore("unused_signal")
signal picker_requested(context: Dictionary)

func _ready() -> void:
	for button: BaseButton in $"buttons".get_children():
		button.pressed.connect(self._on_type_pressed.bind(button))
		
func show_panel() -> void:
	self.show()

func _on_type_pressed(button: BaseButton) -> void:
	self.audio.play("menu_click")
	self.step_data["action"] = str(button.name)
	self.step_data_updated.emit(self.step_no, self.step_data)


func fill_step_data(new_step_no: int, new_step_data: Dictionary) -> void:
	self.step_no = new_step_no
	self.step_data = new_step_data
