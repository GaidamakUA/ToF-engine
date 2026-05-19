extends Control
class_name StoryStepElement

signal edit_requested(step_no: int)

var step_no: int = 0

func set_step_name(new_step_no: int, label: String) -> void:
	self.step_no = new_step_no
	$"Label".set_text(str(new_step_no) + " - " + str(label))


func _on_edit_button_pressed() -> void:
	self.edit_requested.emit(self.step_no)
