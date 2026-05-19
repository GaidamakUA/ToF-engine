extends Control
class_name StoryListElement

signal edit_requested(story_name: String)
signal story_removal_requested(story_name: String)

var story_name: String = ""

func set_story_name(new_story_name: String) -> void:
	self.story_name = new_story_name
	$"Label".set_text(new_story_name)


func _on_edit_button_pressed() -> void:
	self.edit_requested.emit(self.story_name)


func _on_delete_button_pressed() -> void:
	self.story_removal_requested.emit(self.story_name)
