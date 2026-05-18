extends Control
class_name ServerDiscoveryPanel

signal server_selected(address: String, port: int)

@onready var join_button: TextureButton = $"join"
@onready var name_label: Label = $"name"
@onready var capacity_label: Label = $"capacity"

@onready var audio: AudioService = SimpleAudioLibrary as AudioService

var address: String = ""
var port: int = 0


func set_labels(server_name: String, capacity: String) -> void:
	self.name_label.set_text(server_name)
	self.capacity_label.set_text(capacity)


func _on_join_pressed() -> void:
	self.audio.play("menu_click")
	self.server_selected.emit(self.address, self.port)
