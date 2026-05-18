extends Control
class_name CampaignMissionMarker

const SIZE_MARGIN: int = 20
const CHAR_SIZE: int = 11

@onready var animations: AnimationPlayer = $"animations"

var main_menu: MainMenu

func bind_menu(menu: MainMenu) -> void:
	self.main_menu = menu

func show_panel() -> void:
	self.animations.play("show")

func hide_panel() -> void:
	self.animations.play("hide")

func set_mission_title(mission_no: int, title: String) -> void:
	var label_text: String = str(mission_no) + ". " + tr(title)
	$"label/background/mission_name".set_text(label_text)
	var box: Control = $"label/background"
	var box_size: Vector2 = box.get_size()
	box_size.x = label_text.length() * self.CHAR_SIZE + self.SIZE_MARGIN
	box.set_size(box_size)


func set_complete() -> void:
	$"flag".hide()
	$"flag_complete".show()
