extends Node2D
class_name EndTurnConfirmPanel

@onready var no_button: TextureButton = $"no_button"
@onready var yes_button: TextureButton = $"yes_button"

@onready var gamepad_adapter: GamepadAdapterService = GamepadAdapter as GamepadAdapterService
@onready var audio: AudioService = SimpleAudioLibrary as AudioService


var board: Board = null


func show_panel() -> void:
	self.show()
	self.gamepad_adapter.enable()
	self.no_button.grab_focus()

func _on_no_button_pressed() -> void:
	self.audio.play("menu_back")
	self.gamepad_adapter.disable()
	self.board.close_end_turn_confirm_panel()


func _on_yes_button_pressed() -> void:
	self.audio.play("menu_click")
	self.gamepad_adapter.disable()
	self.board.close_end_turn_confirm_panel()
	self.board.end_turn()
