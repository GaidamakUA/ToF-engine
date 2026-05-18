extends Control
class_name MultiplayerBoardOverlay

@onready var announcement_label: Label = $"announcement"

func set_announcement(announcement: String) -> void:
	self.announcement_label.set_text(announcement)
	self.announcement_label.show()

func clear_announcement() -> void:
	self.announcement_label.hide()
