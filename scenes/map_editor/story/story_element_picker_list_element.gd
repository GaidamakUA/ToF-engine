extends Control
class_name StoryElementPickerListElement

signal value_selected(element_value: String)

var element_value: String = ""

func set_element_value(new_element_value: String) -> void:
	self.element_value = new_element_value
	$"button/label".set_text(new_element_value)


func _on_button_pressed() -> void:
	self.value_selected.emit(self.element_value)
