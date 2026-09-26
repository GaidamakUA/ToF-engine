extends GutTest

const BOARD_MULTIPLAYER: Script = preload("res://scenes/board_multiplayer/board_multiplayer.gd")
const BOARD_ONLINE: Script = preload("res://scenes/board_online/board_online.gd")
const LOBBY_MULTIPLAYER: Script = preload("res://scenes/ui/multiplayer/lobby.gd")
const LOBBY_ONLINE: Script = preload("res://scenes/ui/online/lobby.gd")
const LOBBY_PLAYER: Script = preload("res://scenes/ui/multiplayer/lobby_player.gd")
const ONLINE_LOBBY: PackedScene = preload("res://scenes/ui/online/lobby.tscn")


func test_online_modes_reuse_multiplayer_implementations() -> void:
    assert_same(BOARD_ONLINE.get_base_script(), BOARD_MULTIPLAYER)
    assert_same(LOBBY_ONLINE.get_base_script(), LOBBY_MULTIPLAYER)


func test_online_lobby_reuses_shared_player_panel() -> void:
    var lobby := ONLINE_LOBBY.instantiate()
    var player := lobby.get_node("widgets/lobby_player_0")
    add_child_autofree(lobby)

    assert_same(player.get_script(), LOBBY_PLAYER)
    assert_same(player.network, Relay)
