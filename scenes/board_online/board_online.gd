extends "res://scenes/board_multiplayer/board_multiplayer.gd"
class_name BoardOnline


func _get_network_service() -> Variant:
    return Relay as RelayService


func _close_on_end_game() -> bool:
    return true
