extends "res://scenes/board/board.gd"
class_name BoardMultiplayer

@onready var ui_multiplayer: MultiplayerBoardOverlay = $"ui_multiplayer"

var network: Variant
var all_players_loaded: bool = false
var lock_multicall: int = 0
var match_ended: bool = false
var _last_camera_state: Variant = null


func _get_network_service() -> Variant:
    return Multiplayer as MultiplayerService


func _close_on_end_game() -> bool:
    return false


func _ready() -> void:
    self.network = self._get_network_service()
    super._ready()
    self.network.player_connected.connect(_on_player_connected)
    self.network.player_disconnected.connect(_on_player_disconnected)
    self.network.server_disconnected.connect(_on_server_disconnected)
    self.network.all_players_loaded.connect(_all_players_loaded)
    self.network.message_received.connect(_on_message_incoming)
    self.network.player_loaded()


func _ready_start() -> void:
    if self.match_setup.restore_save_id != null:
        self.restore_saved_state()


func _on_message_incoming(message: Dictionary) -> void:
    if self.match_ended or message["action"] != "message":
        return
    self._handle_message(message["payload"] as Dictionary)


func _handle_message(message: Dictionary) -> void:
    match String(message["type"]):
        "player_loaded":
            self.network.mark_player_loaded()
        "game_start":
            self._start_game()
        "player_reconnected":
            self._notify_player_reconnected(int(message.get("peer_id", 0)))
        "camera_position":
            self._update_camera_position(message["position"])
        "tile_select":
            self._update_tile_select(Vector2i(int(message["x"]), int(message["y"])))
        "activate_production_ability":
            self._notify_activate_production_ability(Vector2i(int(message["x"]), int(message["y"])), int(message["index"]))
        "activate_ability":
            self._notify_activate_ability(Vector2i(int(message["x"]), int(message["y"])), int(message["index"]))
        "cancel_ability":
            self._notify_cancel_ability()
        "unselect_tile":
            self._notify_unselect_tile()
        "collateral_damage":
            self._notify_collateral_damage(message["damage"] as Dictionary)
        "end_turn":
            self._notify_end_turn()
        "undo_unit_move":
            self._notify_undo_unit_move()


func _all_players_loaded() -> void:
    if self.match_ended:
        return
    self.network.message_broadcast({"type": "game_start"})
    self._start_game()


func _start_game() -> void:
    self.all_players_loaded = true
    self.network.match_in_progress = true
    self._manage_cinematic_bars()
    self.start_turn()


func _on_player_connected(peer_id: int, _player_info: Dictionary) -> void:
    if self.match_ended:
        return
    self.state.assign_free_peer(peer_id)
    if self.network.is_server():
        var current_state: Dictionary = self.saves_manager.compile_save_data(self)["save_data"] as Dictionary
        self.network.message_direct(peer_id, {
            "type": "match_state",
            "state": current_state,
        })


func _on_player_disconnected(peer_id: int) -> void:
    if self.match_ended:
        return
    if self.state.is_non_observer_peer(peer_id):
        self.all_players_loaded = false
        self.state.clear_peer_id(peer_id)
        self._manage_cinematic_bars()
        self._manage_ai_start()
        self.ui_multiplayer.set_announcement(tr("TR_WAITING_FOR_PLAYER_RECONNECTED"))


func _on_server_disconnected() -> void:
    if not self.match_ended:
        self.main_menu()


func perform_autosave() -> void:
    return


func cheat_capture() -> void:
    return


func cheat_kill() -> void:
    return


func _should_perform_hq_cam() -> bool:
    return false


func restore_saved_state() -> void:
    self._restore_saved_state(self.network.match_state)
    self.network.message_broadcast({
        "type": "player_reconnected",
        "peer_id": self.network.peer_id,
    })
    self._notify_player_reconnected()


func _manage_cinematic_bars() -> void:
    if self._can_current_player_perform_actions():
        if self.ui.cinematic_bars.is_extended:
            self.ui.hide_cinematic_bars()
            self.ui_multiplayer.clear_announcement()
    else:
        if not self.ui.cinematic_bars.is_extended:
            self.ui.show_cinematic_bars()
            await self.get_tree().create_timer(0.25).timeout
        if self.all_players_loaded:
            if self.state.is_current_player_ai():
                self.ui_multiplayer.set_announcement(tr("TR_AI"))
            else:
                self.ui_multiplayer.set_announcement(str(self.network.players[int(self.state.get_current_param("peer_id"))]["name"]))


func _manage_ai_start() -> void:
    if self._can_current_player_perform_actions():
        self.map.camera.ai_operated = false
        self.map.show_tile_box()
    else:
        self.map.camera.ai_operated = true
        self.map.hide_tile_box()
        if self.network.is_server() and self.state.are_all_peers_present() and self.state.is_current_player_ai():
            self.ai.run()


func _can_current_player_perform_actions() -> bool:
    return self.network.peer_id != 0 and self.all_players_loaded and self.state.is_current_player_active_peer(self.network.peer_id)


func _can_broadcast_moves() -> bool:
    return self._can_current_player_perform_actions() or (self.network.is_server() and self.state.are_all_peers_present() and self.state.is_current_player_ai())


func setup_radial_menu(context_object: Variant = null) -> void:
    if context_object != null and not self._can_current_player_perform_actions():
        return
    super.setup_radial_menu(context_object)
    if context_object == null:
        self.ui.radial.set_field_disabled(0, "X")
        self.ui.radial.set_field_disabled(2, "X")


func _show_contextual_select_radial(open_unit_abilities: bool) -> void:
    if self._can_current_player_perform_actions():
        super._show_contextual_select_radial(open_unit_abilities)


func _add_player_to_state(data: Dictionary) -> void:
    self.state.add_player(str(data["type"]), str(data["side"]), bool(data["alive"]), data["team"], data["peer_id"])


func main_menu() -> void:
    self.match_ended = true
    self.network.close_game()
    super.main_menu()


func _physics_process(_delta: float) -> void:
    if self.match_ended:
        return
    super._physics_process(_delta)
    if self._can_broadcast_moves():
        var new_camera_state: Array[float] = self.map.camera.get_position_state()
        if self._last_camera_state != new_camera_state:
            self.network.message_broadcast({
                "type": "camera_position",
                "position": new_camera_state,
            }, true)
            self._last_camera_state = new_camera_state


func _update_camera_position(camera_state: Array) -> void:
    self.map.camera.restore_from_state(camera_state)


func select_tile(tile_position: Vector2i) -> void:
    self.lock_multicall += 1
    super.select_tile(tile_position)
    self.lock_multicall -= 1
    if self._can_broadcast_moves() and self.lock_multicall == 0:
        self.network.message_broadcast({
            "type": "tile_select",
            "x": tile_position.x,
            "y": tile_position.y,
        })


func _reselect_tile(tile_position: Vector2i) -> void:
    self.lock_multicall += 1
    super.select_tile(tile_position)
    self.lock_multicall -= 1


func _update_tile_select(tile_position: Vector2i) -> void:
    self.select_tile(tile_position)


func _activate_production_ability(ability: Ability) -> void:
    super._activate_production_ability(ability)
    if self._can_broadcast_moves():
        self.network.message_broadcast({
            "type": "activate_production_ability",
            "x": self.selected_tile.position.x,
            "y": self.selected_tile.position.y,
            "index": ability.index,
        })


func _notify_activate_production_ability(tile_position: Vector2i, ability_index: int) -> void:
    var building_tile: MapTile = self.map.model.get_tile(tile_position)
    self.selected_tile = building_tile
    for ability: Ability in building_tile.building.tile.abilities:
        if ability.index == ability_index:
            self._activate_production_ability(ability)
            return


func _activate_ability(ability: Ability) -> void:
    super._activate_ability(ability)
    if self._can_broadcast_moves():
        self.network.message_broadcast({
            "type": "activate_ability",
            "x": self.selected_tile.position.x,
            "y": self.selected_tile.position.y,
            "index": ability.index,
        })


func _notify_activate_ability(tile_position: Vector2i, ability_index: int) -> void:
    var unit_tile: MapTile = self.map.model.get_tile(tile_position)
    self.selected_tile = unit_tile
    for ability: Ability in unit_tile.unit.tile.active_abilities:
        if ability.index == ability_index:
            self._activate_ability(ability)
            return


func cancel_ability() -> void:
    self.lock_multicall += 1
    super.cancel_ability()
    self.lock_multicall -= 1
    if self._can_broadcast_moves() and self.lock_multicall == 0:
        self.network.message_broadcast({"type": "cancel_ability"})


func _notify_cancel_ability() -> void:
    self.cancel_ability()


func unselect_tile() -> void:
    self.lock_multicall += 1
    super.unselect_tile()
    self.lock_multicall -= 1
    if self._can_broadcast_moves() and self.lock_multicall == 0:
        self.network.message_broadcast({"type": "unselect_tile"})


func _notify_unselect_tile() -> void:
    self.unselect_tile()


func _generate_collateral_damage(tile: MapTile) -> Dictionary[String, Variant]:
    if not self._can_broadcast_moves():
        return {}
    var damage: Dictionary = super._generate_collateral_damage(tile)
    var serialized_damage: Dictionary = {
        "collateral": [],
        "damage": null,
    }
    for damaged_tile: Vector2i in damage["collateral"]:
        serialized_damage["collateral"].append([damaged_tile.x, damaged_tile.y])
    if damage["damage"] != null:
        serialized_damage["damage"] = [
            [damage["damage"][0].x, damage["damage"][0].y],
            damage["damage"][1],
            damage["damage"][2],
        ]
    self.network.message_broadcast({
        "type": "collateral_damage",
        "damage": serialized_damage,
    })
    return damage


func _notify_collateral_damage(damage: Dictionary) -> void:
    if damage["damage"] != null:
        var position := Vector2i(int(damage["damage"][0][0]), int(damage["damage"][0][1]))
        self.collateral.apply_tile_damage(position, str(damage["damage"][1]), int(damage["damage"][2]))
    for neighbour: Array in damage["collateral"]:
        self.collateral.damage_terrain(self.map.model.get_tile(Vector2i(int(neighbour[0]), int(neighbour[1]))))


func end_turn() -> void:
    if self.ui.radial.is_visible():
        self.toggle_radial_menu()
    self._end_turn()


func _end_turn() -> void:
    var should_broadcast := self._can_broadcast_moves()
    super._end_turn()
    if should_broadcast:
        self.network.message_broadcast({"type": "end_turn"})


func _notify_end_turn() -> void:
    self._end_turn()


func end_game(winner: Variant) -> void:
    super.end_game(winner)
    self.ui.summary.disable_restart()
    self.match_ended = true
    if self._close_on_end_game():
        self.network.close_game()


func _notify_player_reconnected(peer_id: int = 0) -> void:
    if self.all_players_loaded:
        if peer_id > 0 and self._can_broadcast_moves():
            if self.selected_tile != null:
                self.network.message_direct(peer_id, {
                    "type": "tile_select",
                    "x": self.selected_tile.position.x,
                    "y": self.selected_tile.position.y,
                })
            if self.active_ability != null:
                self.network.message_direct(peer_id, {
                    "type": "activate_production_ability" if self.active_ability.TYPE == "production" else "activate_ability",
                    "x": self.selected_tile.position.x,
                    "y": self.selected_tile.position.y,
                    "index": self.active_ability.index,
                })
        return
    self.all_players_loaded = self.state.are_all_peers_present()
    self.network.players_loaded = 0
    self._manage_cinematic_bars()
    self._manage_ai_start()


func _timer_end_turn() -> void:
    if self._can_broadcast_moves():
        self._end_turn()


func _undo_unit_move() -> void:
    if self._can_broadcast_moves():
        super._undo_unit_move()
        self.network.message_broadcast({"type": "undo_unit_move"})


func _notify_undo_unit_move() -> void:
    super._undo_unit_move()
