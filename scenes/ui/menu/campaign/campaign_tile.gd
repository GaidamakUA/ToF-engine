extends Control
class_name CampaignTile

@onready var audio: AudioService = SimpleAudioLibrary as AudioService

@onready var button: TextureButton = $"button"
@onready var icon_anchor: Control = $"icon_anchor"
@onready var label: Label = $"label"
@onready var tick: Node = $"tick"

var main_menu: MainMenu
var attached_icon: Node = null
var campaign_name: String = ""

func bind_menu(menu: MainMenu) -> void:
    self.main_menu = menu

func set_up(visible_name: String, icon: Node, _campaign_name: String) -> void:
    self.campaign_name = _campaign_name
    self.label.set_text(visible_name)
    self._set_icon(icon)
    self.button.set_disabled(false)
    self.tick.hide()

func set_locked(icon: Node) -> void:
    self.label.set_text("TR_LOCKED")
    self._set_icon(icon)
    self.button.set_disabled(true)
    self.tick.hide()

func set_complete() -> void:
    self.tick.show()

func focus_tile() -> void:
    self.button.grab_focus()

func _set_icon(icon: Node) -> void:
    if self.attached_icon != null:
        self.attached_icon.queue_free()
        self.attached_icon = null

    if icon != null:
        self.icon_anchor.add_child(icon)
        #icon.set_scale(Vector2(2, 2))
        self.attached_icon = icon

func _on_button_pressed() -> void:
    self.audio.play("menu_click")
    self.main_menu.open_campaign_mission_selection(self.campaign_name)
    self.main_menu.ui.campaign_selection.last_campaign_tile_clicked = self
