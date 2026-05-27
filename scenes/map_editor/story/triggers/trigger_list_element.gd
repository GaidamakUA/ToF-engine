extends Control
class_name TriggerListElement

signal edit_requested(trigger_name: String)

var trigger_name: String = ""

func set_trigger_name(new_trigger_name: String) -> void:
    self.trigger_name = new_trigger_name
    $"Label".set_text(new_trigger_name)


func _on_edit_button_pressed() -> void:
    self.edit_requested.emit(self.trigger_name)
