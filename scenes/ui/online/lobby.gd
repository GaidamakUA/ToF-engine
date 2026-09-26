extends "res://scenes/ui/multiplayer/lobby.gd"
class_name OnlineLobbyPanel


func _get_network_service() -> Variant:
    return Relay as RelayService


func _open_board() -> void:
    self.switcher.board_online()


func _close_lobby() -> void:
    self.main_menu.close_online_lobby()


func _should_reset_turn_config() -> bool:
    return false


func _get_join_code() -> String:
    return String((Relay as RelayService).join_code)


func _start_network_game() -> bool:
    (Relay as RelayService).game_start()
    return false
