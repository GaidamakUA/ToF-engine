extends Control
class_name BaseStepActionEditor

var step_no: int = 0
var step_data: Dictionary = {}

@onready var audio: AudioService = SimpleAudioLibrary as AudioService

signal step_data_updated(step_no: int, step_data: Dictionary)
signal step_move_requested(step_no: int, new_step_no: int)
signal step_removal_requested(step_no: int)
signal picker_requested(context: Dictionary)

func show_panel() -> void:
	self.show()

func fill_step_data(new_step_no: int, new_step_data: Dictionary) -> void:
	self.step_no = new_step_no
	self.step_data = new_step_data
	
	if not self.step_data.has("delay"):
		self.step_data["delay"] = 0.0
	
	$"delay/delay".set_text(str(self.step_data["delay"]))
	$"step_no/no".set_text(str(self.step_no))
	$"action".set_text(self.step_data["action"])

func build_step_label(requested_step_data: Dictionary) -> String:
	return requested_step_data["action"]

func _emit_updated_signal() -> void:
	self.step_data_updated.emit(self.step_no, _compile_step_data())

func _compile_step_data() -> Dictionary:
	var delay: String = $"delay/delay".get_text()

	if delay != "":
		self.step_data["delay"] = float(delay)

	return self.step_data


func _on_text_changed(_new_text: String) -> void:
	_emit_updated_signal()

func _on_delete_button_pressed() -> void:
	self.audio.play("menu_click")
	self.step_removal_requested.emit(self.step_no)


func _on_change_button_pressed() -> void:
	self.audio.play("menu_click")
	self.step_data["action"] = null
	_emit_updated_signal()


func _handle_picker_response(_response: Variant, _context: Dictionary) -> void:
	return


func _on_move_button_pressed() -> void:
	self.audio.play("menu_click")
	var new_step_no: String = $"step_no/no".get_text()
	if new_step_no != "":
		var int_step_no: int = int(new_step_no)
		if self.step_no != int_step_no:
			self.step_move_requested.emit(self.step_no, int_step_no)
