extends "res://scenes/ui/menu/base_menu_panel.gd"
class_name MultiplayerLobbyPanel

@onready var online: OnlineService = Online as OnlineService
@onready var map_list_service: MapManagerService = MapManager as MapManagerService
@onready var switcher: SceneSwitcherService = SceneSwitcher as SceneSwitcherService
@onready var match_setup: MatchSetupData = MatchSetup as MatchSetupData
@onready var start_button: TextureButton = $"widgets/start_button"
@onready var back_button: TextureButton = $"widgets/back_button"
@onready var minimap: MinimapView = $"widgets/minimap"
@onready var join_code_label: Label = get_node_or_null("widgets/join_code/label") as Label
@onready var widgets: Control = $"widgets"
@onready var downloading_label: Label = $"downloading"
@onready var turn_config: TurnConfigView = $"widgets/TurnConfig"
@onready var player_panels: Array[MultiplayerLobbyPlayerPanel] = [
    $"widgets/lobby_player_0",
    $"widgets/lobby_player_1",
    $"widgets/lobby_player_2",
    $"widgets/lobby_player_3",
]
@onready var player_labels: Array[ConnectedPlayerPanel] = [
    $"widgets/player_labels/labels_grid/player_0",
    $"widgets/player_labels/labels_grid/player_1",
    $"widgets/player_labels/labels_grid/player_2",
    $"widgets/player_labels/labels_grid/player_3",
    $"widgets/player_labels/labels_grid/player_4",
    $"widgets/player_labels/labels_grid/player_5",
    $"widgets/player_labels/labels_grid/player_6",
    $"widgets/player_labels/labels_grid/player_7",
]

var network: Variant
var hq_templates: Array[String] = [
    "modern_hq",
    "steampunk_hq",
    "futuristic_hq",
    "feudal_hq",
]
var server_state: Dictionary = {}


func _get_network_service() -> Variant:
    return Multiplayer as MultiplayerService


func _open_board() -> void:
    self.switcher.board_multiplayer()


func _close_lobby() -> void:
    self.main_menu.close_multiplayer_lobby()


func _should_reset_turn_config() -> bool:
    return true


func _get_join_code() -> String:
    return ""


func _start_network_game() -> bool:
    self.network.message_broadcast({"type": "lobby_game_start"})
    return true


func _ready() -> void:
    self.network = self._get_network_service()
    super._ready()
    self.network.player_connected.connect(_on_player_connected)
    self.network.player_disconnected.connect(_on_player_disconnected)
    self.network.server_disconnected.connect(_on_server_disconnected)
    self.network.message_received.connect(_on_message_incoming)
    self.turn_config.configuration_changed.connect(_on_turn_config_changed)

    for panel: MultiplayerLobbyPlayerPanel in self.player_panels:
        panel.network = self.network
        panel.player_joined.connect(_on_player_joined_side)
        panel.player_left.connect(_on_player_left_side)
        panel.state_changed.connect(_on_panel_state_changed)
        panel.swap_happened.connect(_on_panel_swap)
    for label: ConnectedPlayerPanel in self.player_labels:
        label.kick_requested.connect(_on_player_kick_requested)


func show_panel() -> void:
    super.show_panel()
    if self._should_reset_turn_config():
        self.turn_config.reset()
    if self.map_list_service._is_bundled(self.network.selected_map) or self.map_list_service._is_online(self.network.selected_map):
        self._prepare_initial_panel_state(self.network.selected_map)
    else:
        self._download_map_data(self.network.selected_map)


func _download_map_data(map_name: String) -> void:
    self.widgets.hide()
    self.downloading_label.show()
    var result: bool = await self.online.download_map(map_name)
    self.downloading_label.hide()
    self.widgets.show()
    if result:
        self._prepare_initial_panel_state(map_name)
    else:
        self._on_back_button_pressed()


func _prepare_initial_panel_state(map_name: String) -> void:
    if self.network.match_in_progress:
        self.widgets.hide()
        while not self.network.match_state_available:
            await self.get_tree().create_timer(0.1).timeout
        self.load_game_from_state(self.network.match_state)
        return

    self._fill_map_data(map_name)
    if self.join_code_label != null:
        self.join_code_label.set_text(tr("TR_JOIN_CODE") + " " + self._get_join_code())
    self._fill_player_labels()
    self._apply_server_state()
    if self.network.is_server():
        self.turn_config.unlock_buttons()
    else:
        self.turn_config.lock_buttons()
    await self.get_tree().create_timer(0.1).timeout
    self._manage_start_button(true)


func _manage_start_button(grab: bool) -> void:
    if self.network.is_server() and self._is_ready_to_start():
        self.start_button.show()
        if grab:
            self.start_button.grab_focus()
    else:
        self.start_button.hide()
        if grab:
            self.back_button.grab_focus()


func _is_ready_to_start() -> bool:
    var player_spots: int = 0
    var players_assigned: int = 0
    var ai_assigned: int = 0
    for panel: MultiplayerLobbyPlayerPanel in self.player_panels:
        if panel.is_visible():
            player_spots += 1
            if panel.type == "human" and panel.player_peer_id != null:
                players_assigned += 1
            elif panel.type == "ai":
                ai_assigned += 1
    return players_assigned + ai_assigned == player_spots


func _fill_map_data(fill_name: String) -> void:
    self.minimap.fill_minimap(fill_name)
    $"widgets/minimap/map_name/label".set_text(fill_name)
    self._fill_player_panels(fill_name)


func _fill_player_labels() -> void:
    for label: ConnectedPlayerPanel in self.player_labels:
        label.hide()
    var index: int = 0
    for player_peer_id: int in self.network.players:
        self.player_labels[index].show()
        self.player_labels[index].bind_player(player_peer_id, self.network.players[player_peer_id])
        index += 1


func _hide_player_panels() -> void:
    for panel: MultiplayerLobbyPlayerPanel in self.player_panels:
        panel.hide()
        panel._reset_labels()


func _fill_player_panels(fill_name: String) -> void:
    self._hide_player_panels()
    var sides: Dictionary[String, String] = self._gather_player_sides(self.map_list_service.get_map_data(fill_name))
    var index: int = 0
    for side: String in sides:
        if index >= self.player_panels.size():
            continue
        self.player_panels[index].fill_panel(side)
        self.player_panels[index].show()
        index += 1


func _gather_player_sides(map_data: Dictionary) -> Dictionary[String, String]:
    var sides: Dictionary[String, String] = {}
    for y: int in range(self.map_list_service.MAX_MAP_SIZE):
        for x: int in range(self.map_list_service.MAX_MAP_SIZE):
            var key := str(x) + "_" + str(y)
            if map_data["tiles"].has(key):
                var side := self._lookup_side(map_data["tiles"][key])
                if side != "":
                    sides[side] = side
    return sides


func _lookup_side(data: Dictionary) -> String:
    if data["building"]["tile"] != null and data["building"]["tile"] in self.hq_templates:
        return String(data["building"]["side"])
    return ""


func _on_back_button_pressed() -> void:
    if self.downloading_label.is_visible():
        return
    super._on_back_button_pressed()
    self.network.close_game()
    self._close_lobby()


func _on_player_connected(peer_id: int, _player_info: Dictionary) -> void:
    if not self.is_visible():
        return
    self._fill_player_labels()
    if self.network.is_server() and peer_id != self.network.peer_id:
        var state: Dictionary = {
            "turn_limit": self.turn_config.turn_limit,
            "time_limit": self.turn_config.time_limit,
            "panels": {},
        }
        for panel: MultiplayerLobbyPlayerPanel in self.player_panels:
            state["panels"][panel.index] = {
                "type": panel.type,
                "side": panel.side,
                "peer_id": panel.player_peer_id,
                "ap": panel.ap,
                "team": panel.team,
            }
        self.network.message_direct(peer_id, {
            "type": "state",
            "state": state,
        })
    for panel: MultiplayerLobbyPlayerPanel in self.player_panels:
        panel._update_join_label()


func _on_player_disconnected(peer_id: int) -> void:
    if not self.is_visible():
        return
    self._fill_player_labels()
    for panel: MultiplayerLobbyPlayerPanel in self.player_panels:
        if panel.player_peer_id == peer_id:
            panel._set_peer_id(null)
    self._manage_start_button(false)


func _on_server_disconnected() -> void:
    if self.is_visible():
        self._on_back_button_pressed()


func _on_start_button_pressed() -> void:
    self.audio.play("menu_click")
    if self._start_network_game():
        self._load_multiplayer_game()


func _on_message_incoming(message: Dictionary) -> void:
    if message["action"] == "game_start":
        self._load_multiplayer_game()
    elif message["action"] == "message":
        self._handle_message(message["payload"] as Dictionary)


func _handle_message(message: Dictionary) -> void:
    match String(message["type"]):
        "lobby_game_start":
            self._load_multiplayer_game()
        "state":
            self._set_lobby_state(message["state"])
        "player_joined_side":
            self._player_joined_a_side(int(message["peer_id"]), int(message["index"]))
        "player_left_side":
            self._player_left_a_side(int(message["index"]))
        "player_panel_updated":
            self._update_panel_state(int(message["index"]), int(message["ap"]), message["team"], String(message["ptype"]))
        "player_panel_swap":
            self._swap_panel(int(message["index"]))
        "match_state":
            self.network._set_match_state(message["state"])
        "kick":
            self._kick_player()
        "turn_config_updated":
            self._update_turn_config(int(message["turn_limit"]), int(message["time_limit"]))


func _load_multiplayer_game() -> void:
    self.match_setup.reset()
    self.match_setup.map_name = self.network.selected_map
    self.match_setup.is_multiplayer = true
    self.match_setup.turn_limit = self.turn_config.turn_limit
    self.match_setup.time_limit = self.turn_config.time_limit
    for player: MultiplayerLobbyPlayerPanel in self.player_panels:
        if player.player_peer_id != null or player.type == "ai":
            self.match_setup.add_player(player.side, player.ap, player.type, true, player.team, player.player_peer_id)
    self.hide()
    self._open_board()


func _on_player_joined_side(index: int) -> void:
    for panel: MultiplayerLobbyPlayerPanel in self.player_panels:
        if panel.index != index:
            if self.network.is_server():
                panel.switch_to_ai()
            else:
                panel.lock_side()
    self.network.message_broadcast({
        "type": "player_joined_side",
        "peer_id": self.network.peer_id,
        "index": index,
    })
    self._manage_start_button(false)


func _on_player_left_side(index: int) -> void:
    for panel: MultiplayerLobbyPlayerPanel in self.player_panels:
        if panel.index != index:
            panel.unlock_side()
    self.network.message_broadcast({
        "type": "player_left_side",
        "index": index,
    })
    self._manage_start_button(false)


func _on_panel_state_changed(index: int) -> void:
    self.network.message_broadcast({
        "type": "player_panel_updated",
        "index": index,
        "ap": self.player_panels[index].ap,
        "team": self.player_panels[index].team,
        "ptype": self.player_panels[index].type,
    })
    self._manage_start_button(false)


func _on_panel_swap(index: int) -> void:
    self.network.message_broadcast({
        "type": "player_panel_swap",
        "index": index,
    })


func _player_joined_a_side(peer_id: int, index: int) -> void:
    self.player_panels[index]._set_peer_id(peer_id)
    self._manage_start_button(false)


func _player_left_a_side(index: int) -> void:
    self.player_panels[index]._set_peer_id(null)
    self._manage_start_button(false)


func _set_lobby_state(state: Dictionary) -> void:
    self.server_state = state


func _apply_server_state() -> void:
    if not self.server_state.is_empty():
        self.turn_config.set_turn_limit(int(self.server_state["turn_limit"]))
        self.turn_config.set_time_limit(int(self.server_state["time_limit"]))
        var panels_state: Dictionary = self.server_state["panels"]
        for index: Variant in panels_state:
            var int_index := int(index)
            if self.player_panels[int_index].is_visible():
                self.player_panels[int_index].fill_panel(panels_state[index]["side"])
                if panels_state[index]["peer_id"] != null:
                    self.player_panels[int_index]._set_peer_id(int(panels_state[index]["peer_id"]))
                self.player_panels[int_index]._set_ap(int(panels_state[index]["ap"]))
                self.player_panels[int_index]._set_team(panels_state[index]["team"])
                self.player_panels[int_index]._set_type(panels_state[index]["type"])
    self.server_state.clear()


func _update_panel_state(index: int, ap: int, team: Variant, type: String) -> void:
    self.player_panels[index]._set_ap(ap)
    self.player_panels[index]._set_team(team)
    self.player_panels[index]._set_type(type)


func _swap_panel(index: int) -> void:
    self.player_panels[index]._perform_panel_swap()


func load_game_from_state(state: Dictionary) -> void:
    self.match_setup.reset()
    self.match_setup.map_name = String(state["map_name"])
    self.match_setup.restore_save_id = "multiplayer"
    self.match_setup.is_multiplayer = true
    if state.has("turn_limit"):
        self.match_setup.turn_limit = int(state["turn_limit"])
    if state.has("time_limit"):
        self.match_setup.time_limit = int(state["time_limit"])
    for player: Dictionary in state["players"]:
        var peer_id: Variant = player["peer_id"]
        if peer_id != null:
            peer_id = int(peer_id)
        self.match_setup.add_player(player["side"], player["ap"], player["type"], player["alive"], player["team"], peer_id)
    self._open_board()


func _on_player_kick_requested(player_peer_id: int) -> void:
    if self.network.is_server():
        self.network.message_direct(player_peer_id, {"type": "kick"})
        self.back_button.grab_focus()


func _kick_player() -> void:
    self._on_back_button_pressed()


func _update_turn_config(turn_limit: int, time_limit: int) -> void:
    self.turn_config.set_turn_limit(turn_limit)
    self.turn_config.set_time_limit(time_limit)


func _on_turn_config_changed() -> void:
    if self.network.is_server():
        self.network.message_broadcast({
            "type": "turn_config_updated",
            "turn_limit": self.turn_config.turn_limit,
            "time_limit": self.turn_config.time_limit,
        })


func _on_copy_button_pressed() -> void:
    DisplayServer.clipboard_set(self._get_join_code())
    self.audio.play("menu_click")
