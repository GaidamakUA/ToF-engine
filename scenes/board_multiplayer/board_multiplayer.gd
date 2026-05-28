extends "res://scenes/board/board.gd"
class_name BoardMultiplayer

@onready var multiplayer_srv: MultiplayerService = Multiplayer as MultiplayerService

@onready var ui_multiplayer: MultiplayerBoardOverlay = $"ui_multiplayer"

var all_players_loaded: bool = false
var lock_multicall: int = 0
var match_ended: bool = false


func _ready() -> void:
    super._ready()
    self.multiplayer_srv.player_connected.connect(_on_player_connected)
    self.multiplayer_srv.player_disconnected.connect(_on_player_disconnected)
    self.multiplayer_srv.server_disconnected.connect(_on_server_disconnected)
    self.multiplayer_srv.all_players_loaded.connect(_all_players_loaded)

    self.multiplayer_srv.player_loaded.rpc_id(1)


func _ready_start() -> void:
    if self.match_setup.restore_save_id != null:
        self.restore_saved_state()


func _all_players_loaded() -> void:
    _start_game.rpc()


@rpc("call_local", "reliable")
func _start_game() -> void:
    self.all_players_loaded = true
    self.multiplayer_srv.match_in_progress = true
    _manage_cinematic_bars()
    start_turn()


func _on_player_connected(peer_id: int, _player_info: Dictionary) -> void:
    self.state.assign_free_peer(peer_id)
    var current_state: Dictionary = self.saves_manager.compile_save_data(self)["save_data"] as Dictionary
    self.multiplayer_srv._set_match_state.rpc_id(peer_id, current_state)


func _on_player_disconnected(peer_id: int) -> void:
    if self.match_ended:
        return

    if self.state.is_non_observer_peer(peer_id):
        self.all_players_loaded = false
        self.state.clear_peer_id(peer_id)
        _manage_cinematic_bars()
        _manage_ai_start()
        self.ui_multiplayer.set_announcement(tr("TR_WAITING_FOR_PLAYER_RECONNECTED"))


func _on_server_disconnected() -> void:
    if not self.match_ended:
        self.main_menu()


# function overrides
# disable save/load for multiplayer
func perform_autosave() -> void:
    return
func cheat_capture() -> void:
    return
func cheat_kill() -> void:
    return


func _should_perform_hq_cam() -> bool:
    return false


func restore_saved_state() -> void:
    _restore_saved_state(self.multiplayer_srv.match_state)
    _notify_player_reconnected.rpc()


func _manage_cinematic_bars() -> void:
    if _can_current_player_perform_actions():
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
                self.ui_multiplayer.set_announcement(str(self.multiplayer_srv.players[int(self.state.get_current_param("peer_id"))]["name"]))


func _manage_ai_start() -> void:
    if _can_current_player_perform_actions():
        self.map.camera.ai_operated = false
        self.map.show_tile_box()
    else:
        self.map.camera.ai_operated = true
        self.map.hide_tile_box()

        if self.multiplayer.is_server() and self.state.are_all_peers_present() and self.state.is_current_player_ai():
            self.ai.run()


func _can_current_player_perform_actions() -> bool:
    if multiplayer.multiplayer_peer == null:
        return false

    return self.all_players_loaded and self.state.is_current_player_active_peer(multiplayer.get_unique_id())


func _can_broadcast_moves() -> bool:
    if multiplayer.multiplayer_peer == null:
        return false
    return _can_current_player_perform_actions() or (self.multiplayer.is_server() and self.state.are_all_peers_present() and self.state.is_current_player_ai())


func setup_radial_menu(context_object: Variant = null) -> void:
    if context_object != null and not _can_current_player_perform_actions():
        return

    super.setup_radial_menu(context_object)

    if context_object == null:
        self.ui.radial.set_field_disabled(0, "X")
        self.ui.radial.set_field_disabled(2, "X")


func _show_contextual_select_radial(open_unit_abilities: bool) -> void:
    if _can_current_player_perform_actions():
        super._show_contextual_select_radial(open_unit_abilities)


func _add_player_to_state(data: Dictionary) -> void:
    self.state.add_player(str(data["type"]), str(data["side"]), bool(data["alive"]), data["team"], data["peer_id"])


func main_menu() -> void:
    self.multiplayer_srv.close_game()
    super.main_menu()


func _physics_process(_delta: float) -> void:
    super._physics_process(_delta)

    if _can_broadcast_moves():
        _update_camera_position.rpc(self.map.camera.get_position_state())


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _update_camera_position(camera_state: Array) -> void:
    self.map.camera.restore_from_state(camera_state)


func select_tile(tile_position: Vector2i) -> void:
    self.lock_multicall += 1
    super.select_tile(tile_position)
    self.lock_multicall -= 1

    if _can_broadcast_moves() and self.lock_multicall == 0:
        _update_tile_select.rpc(tile_position)


func _reselect_tile(tile_position: Vector2i) -> void:
    self.lock_multicall += 1
    super.select_tile(tile_position)
    self.lock_multicall -= 1


@rpc("any_peer", "call_remote", "reliable")
func _update_tile_select(tile_position: Vector2i) -> void:
    select_tile(tile_position)


func _activate_production_ability(ability: Ability) -> void:
    super._activate_production_ability(ability)
    if _can_broadcast_moves():
        _notify_activate_production_ability.rpc(self.selected_tile.position, ability.index)


@rpc("any_peer", "call_remote", "reliable")
func _notify_activate_production_ability(tile_position: Vector2i, ability_index: int) -> void:
    for ability: Ability in self.map.model.get_tile(tile_position).building.get_map_object().abilities:
        if ability.index == ability_index:
            _activate_production_ability(ability)
            return


func _activate_ability(ability: Ability) -> void:
    super._activate_ability(ability)
    if _can_broadcast_moves():
        _notify_activate_ability.rpc(self.selected_tile.position, ability.index)


@rpc("any_peer", "call_remote", "reliable")
func _notify_activate_ability(tile_position: Vector2i, ability_index: int) -> void:
    var unit_tile: MapTile = self.map.model.get_tile(tile_position)
    for ability: Ability in unit_tile.unit.get_map_object().active_abilities:
        if ability.index == ability_index:
            ability.active_source_tile = unit_tile
            _activate_ability(ability)
            return


func cancel_ability() -> void:
    self.lock_multicall += 1
    super.cancel_ability()
    self.lock_multicall -= 1
    if _can_broadcast_moves() and self.lock_multicall == 0:
        _notify_cancel_ability.rpc()


@rpc("any_peer", "call_remote", "reliable")
func _notify_cancel_ability() -> void:
    self.cancel_ability()


func unselect_tile() -> void:
    self.lock_multicall += 1
    super.unselect_tile()
    self.lock_multicall -= 1
    if _can_broadcast_moves() and self.lock_multicall == 0:
        _notify_unselect_tile.rpc()


@rpc("any_peer", "call_remote", "reliable")
func _notify_unselect_tile() -> void:
    self.unselect_tile()


func _generate_collateral_damage(tile: MapTile) -> Dictionary[String, Variant]:
    if _can_broadcast_moves():
        var damage: Dictionary[String, Variant] = super._generate_collateral_damage(tile)
        _notify_collateral_damage.rpc(damage)

        return damage
    return {}


@rpc("any_peer", "call_remote", "reliable")
func _notify_collateral_damage(damage: Dictionary) -> void:
    if damage["damage"] != null:
        self.collateral.apply_tile_damage(damage["damage"][0] as Vector2i, str(damage["damage"][1]), int(damage["damage"][2]))
    for neighbour: Vector2i in damage["collateral"]:
        self.collateral.damage_terrain(self.map.model.get_tile(neighbour))


func end_turn() -> void:
    if self.ui.radial.is_visible():
        self.toggle_radial_menu()
    _end_turn()


func _end_turn() -> void:
    if _can_broadcast_moves():
        super._end_turn()
        _notify_end_turn.rpc()
    else:
        super._end_turn()


@rpc("any_peer", "call_remote", "reliable")
func _notify_end_turn() -> void:
    _end_turn()


func end_game(winner: Variant) -> void:
    super.end_game(winner)
    self.ui.summary.disable_restart()
    self.match_ended = true


@rpc("any_peer", "call_local", "reliable")
func _notify_player_reconnected() -> void:
    if self.all_players_loaded:
        if _can_broadcast_moves():
            if self.selected_tile != null:
                _update_tile_select.rpc_id(multiplayer.get_remote_sender_id(), self.selected_tile.position)
            if self.active_ability != null:
                if self.active_ability.TYPE == "production":
                    _notify_activate_production_ability.rpc_id(multiplayer.get_remote_sender_id(), self.selected_tile.position, self.active_ability.index)
                else:
                    _notify_activate_ability.rpc_id(multiplayer.get_remote_sender_id(), self.selected_tile.position, self.active_ability.index)
        return
    self.all_players_loaded = self.state.are_all_peers_present()
    _manage_cinematic_bars()
    _manage_ai_start()


func _timer_end_turn() -> void:
    if _can_broadcast_moves():
        _end_turn()


func _undo_unit_move() -> void:
    if _can_broadcast_moves():
        super._undo_unit_move()
        _notify_end_turn.rpc()


@rpc("any_peer", "call_remote", "reliable")
func _notify_undo_unit_move() -> void:
    super._undo_unit_move()
