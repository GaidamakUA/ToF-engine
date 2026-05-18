extends Control
class_name MainMenuSettingsPanel

@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var settings: SettingsService = Settings as SettingsService

@onready var animations: AnimationPlayer = $"animations"

@onready var general_button: TextureButton = $"widgets/tabs/general"
@onready var video_button: TextureButton = $"widgets/tabs/video"
@onready var audio_button: TextureButton = $"widgets/tabs/audio"
@onready var gameplay_button: TextureButton = $"widgets/tabs/gameplay"
@onready var controls_button: TextureButton = $"widgets/tabs/controls"
@onready var back_button: TextureButton = $"widgets/back_button"

@onready var general_panel: SettingsCategoryPanel = $"widgets/boxes/settings_general"
@onready var video_panel: SettingsCategoryPanel = $"widgets/boxes/settings_video"
@onready var audio_panel: SettingsCategoryPanel = $"widgets/boxes/settings_audio"
@onready var gameplay_panel: SettingsCategoryPanel = $"widgets/boxes/settings_gameplay"
@onready var multiplayer_panel: MultiplayerSettingsCategoryPanel = $"widgets/boxes/settings_multi"

@onready var help: Control = $"help"
@onready var help_text: Label = $"help/text"

var main_menu: Variant


func bind_menu(menu: Variant) -> void:
	self.main_menu = menu


func _ready() -> void:
	self.set_process_input(false)
	for category_panel_node: Node in $"widgets/boxes".get_children():
		var category_panel: SettingsCategoryPanel = category_panel_node as SettingsCategoryPanel
		category_panel.help_requested.connect(show_help)
		category_panel.clear_help_requested.connect(hide_help)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed('editor_menu'):
		self._on_back_button_pressed()


func _on_back_button_pressed() -> void:
	self.hide_help()
	self.audio.play("menu_back")
	self.main_menu.close_settings()


func show_panel() -> void:
	self.hide_help()
	self.general_panel.show()
	self.video_panel.hide()
	self.audio_panel.hide()
	self.gameplay_panel.hide()
	self.multiplayer_panel.hide()
	self.controls_button.show()
	self.animations.play("show")
	self.set_process_input(true)
	await self.get_tree().create_timer(0.1).timeout
	self.general_button.grab_focus()


func hide_panel() -> void:
	self.hide_help()
	self.animations.play("hide")
	self.set_process_input(false)


func hide_controls_button() -> void:
	self.controls_button.hide()


func _on_general_pressed() -> void:
	self.general_panel.show()
	self.video_panel.hide()
	self.audio_panel.hide()
	self.gameplay_panel.hide()
	self.multiplayer_panel.hide()
	self.audio.play("menu_click")


func _on_video_pressed() -> void:
	self.general_panel.hide()
	self.video_panel.show()
	self.audio_panel.hide()
	self.gameplay_panel.hide()
	self.multiplayer_panel.hide()
	self.audio.play("menu_click")


func _on_audio_pressed() -> void:
	self.video_panel.hide()
	self.general_panel.hide()
	self.audio_panel.show()
	self.gameplay_panel.hide()
	self.multiplayer_panel.hide()
	self.audio.play("menu_click")


func _on_gameplay_pressed() -> void:
	self.video_panel.hide()
	self.general_panel.hide()
	self.audio_panel.hide()
	self.gameplay_panel.show()
	self.multiplayer_panel.hide()
	self.audio.play("menu_click")


func _on_multiplayer_pressed() -> void:
	self.video_panel.hide()
	self.general_panel.hide()
	self.audio_panel.hide()
	self.gameplay_panel.hide()
	self.multiplayer_panel.show()
	self.audio.play("menu_click")


func show_help(text: String) -> void:
	self.help_text.set_text(text)
	self.help.show()


func hide_help() -> void:
	self.help.hide()


func _on_controls_pressed() -> void:
	self.audio.play("menu_click")
	self.main_menu.open_controls()
