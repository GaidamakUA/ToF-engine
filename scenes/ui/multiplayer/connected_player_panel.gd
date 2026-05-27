class_name ConnectedPlayerPanel
extends NinePatchRect


signal kick_requested(peer_id: int)


@export var is_online_relay: bool = false
var player_peer_id: int = 0

@onready var multiplayer_srv: MultiplayerService = Multiplayer as MultiplayerService
@onready var relay: RelayService = Relay as RelayService
@onready var label: Label = $"label"
@onready var kick_button: TextureButton = $"kick_button"


func bind_player(peer_id: int, player_info: Dictionary) -> void:
    player_peer_id = peer_id
    set_player_name(str(player_info["name"]))
    if ((not is_online_relay and self.multiplayer_srv.is_server()) or (is_online_relay and self.relay.is_server())) and player_peer_id > 1:
        show_kick_button()
    else:
        hide_kick_button()


func set_player_name(player_name: String) -> void:
    self.label.set_text(player_name)


func show_kick_button() -> void:
    self.kick_button.show()


func hide_kick_button() -> void:
    self.kick_button.hide()


func _on_kick_button_pressed() -> void:
    kick_requested.emit(player_peer_id)
