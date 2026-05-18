extends Control
class_name MainMenuOptionsPanel

@onready var campaign_button: TextureButton = $"campaign_button"
@onready var skirmish_button: TextureButton = $"skirmish_button"
@onready var multiplayer_button: TextureButton = $"multiplayer_button"
@onready var load_button: TextureButton = $"load_button"
@onready var editor_button: TextureButton = $"editor_button"
@onready var settings_button: TextureButton = $"settings_button"
@onready var online_button: TextureButton = $"online_button"
@onready var quit_button: TextureButton = $"quit_button"
@onready var animations: AnimationPlayer = $"animations"
@onready var gamepad_adapter: GamepadAdapterService = GamepadAdapter as GamepadAdapterService

@onready var switcher: SceneSwitcherService = SceneSwitcher as SceneSwitcherService
@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var mouse_layer: MouseLayerService = MouseLayer as MouseLayerService

var main_menu: Variant
var recent_button_used: TextureButton = null

func _ready() -> void:
    self.set_process_input(true)
    self.campaign_button.grab_focus()

    if OS.has_feature("demo"):
        self.online_button.set_disabled(true)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        self.quit_button.grab_focus()

    if OS.is_debug_build():
        if event.is_action_pressed("cheat_capture"):
            self.main_menu.ui.hide_menu()
            self.main_menu._start_intro()

func bind_menu(menu: Variant) -> void:
    self.main_menu = menu

func _on_skirmish_button_pressed() -> void:
    self.recent_button_used = self.skirmish_button
    self.audio.play("menu_click")
    self.main_menu.open_picker()

func _on_multiplayer_button_pressed() -> void:
    self.recent_button_used = self.multiplayer_button
    self.audio.play("menu_click")
    self.main_menu.open_multiplayer()


func _on_load_button_pressed() -> void:
    self.recent_button_used = self.load_button
    self.audio.play("menu_click")
    self.main_menu.open_saves()

func _on_editor_button_pressed() -> void:
    self.audio.play("menu_click")
    self.recent_button_used = self.editor_button
    self.audio.stop()
    self.gamepad_adapter.disable()
    self.switcher.map_editor()

func _on_settings_button_pressed() -> void:
    self.recent_button_used = self.settings_button
    self.audio.play("menu_click")
    self.main_menu.open_settings()

func _on_campaign_button_pressed() -> void:
    self.recent_button_used = self.campaign_button
    self.audio.play("menu_click")
    self.main_menu.open_campaign_selection()

func _on_online_button_pressed() -> void:
    self.recent_button_used = self.online_button
    self.audio.play("menu_click")
    self.main_menu.open_online()

func _on_quit_button_pressed() -> void:
    self.mouse_layer.destroy()
    self.get_tree().quit()

func show_panel() -> void:
    self.animations.play("show")
    self.set_process_input(true)
    await self.get_tree().create_timer(0.1).timeout

    if self.recent_button_used != null:
        self.recent_button_used.grab_focus()
    else:
        self.campaign_button.grab_focus()

func hide_panel() -> void:
    self.set_process_input(false)
    self.animations.play("hide")
