extends Control
class_name ControlsPanel

@onready var audio: AudioService = SimpleAudioLibrary as AudioService

@onready var animations: AnimationPlayer = $"animations"
@onready var back_button: TextureButton = $"widgets/back_button"

var main_menu: Variant

func bind_menu(menu: Variant) -> void:
    self.main_menu = menu

func _ready() -> void:
    self.set_process_input(false)  
    
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") or event.is_action_pressed('editor_menu'):
        self._on_back_button_pressed()

func _on_back_button_pressed() -> void:
    self.audio.play("menu_back")
    self.main_menu.close_controls()

func show_panel() -> void:
    self.animations.play("show")
    self.set_process_input(true)
    await self.get_tree().create_timer(0.1).timeout
    self.back_button.grab_focus()

func hide_panel() -> void:
    self.animations.play("hide")
    self.set_process_input(false)
