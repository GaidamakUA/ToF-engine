extends Control
class_name OnlineLobbyPlayerPanel

signal player_joined(index: int)
signal player_left(index: int)
signal state_changed(index: int)
signal swap_happened(index: int)

const PLAYER_HUMAN: String = "human"
const PLAYER_AI: String = "ai"
const AP_STEP: int = 50
const AP_MAX: int = 150

@onready var player: Label = $"player"

@onready var icon_anchor: Control = $"icon"

@onready var join_button: TextureButton = $"join"
@onready var join_button_label: Label = $"join/label"
@onready var ap_button: TextureButton = $"starting_ap"
@onready var ap_button_label: Label = $"starting_ap/label"
@onready var ap_button_label2: Label = $"starting_ap_label"
@onready var team_button: TextureButton = $"team"
@onready var team_button_label: Label = $"team/label"
@onready var team_button_label2: Label = $"team_label"
@onready var swap_button: TextureButton = $"swap"

var type: String = PLAYER_HUMAN
var side: Variant = null
var ap: int = 0

var player_peer_id: Variant = null

@export var team: int = 1
var original_team: int = 1
@export var index: int = 0
@export var swap_target: NodePath
var swap_target_node: OnlineLobbyPlayerPanel
var attached_icon: Node = null
var locked_out: bool = false
var ai_mode: bool = false

@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var relay: RelayService = Relay as RelayService
var icons: IconsFactory = IconsFactory.new()

func _ready() -> void:
    self.swap_target_node = self.get_node(self.swap_target) as OnlineLobbyPlayerPanel
    self.original_team = self.team

func fill_panel(player_side: Variant) -> void:
    self._reset_labels()

    self.side = player_side
    self._set_icon(self.icons.get_named_icon(str(side) + "_gem"))

    if not relay.is_server():
        self.ap_button.hide()
        self.ap_button_label2.show()
        self.team_button.hide()
        self.team_button_label2.show()
        self.swap_button.hide()

func _reset_labels() -> void:
    if self.attached_icon != null:
        self.attached_icon.queue_free()
        self.attached_icon = null

    self.ap = self.AP_STEP
    self.side = null
    self.team = self.original_team
    self.type = self.PLAYER_HUMAN
    self.player_peer_id = null
    self.locked_out = false
    self.ai_mode = false

    self._update_join_label()
    self._update_ap_label()
    self._update_team_label()

    self.ap_button.show()
    self.ap_button_label2.hide()
    self.team_button.show()
    self.team_button_label2.hide()
    self.swap_button.show()

    if self.index == 0:
        self.swap_button.hide()

func _set_icon(new_icon: Node) -> void:
    if self.attached_icon != null:
        self.attached_icon.queue_free()
        self.attached_icon = null

    if new_icon != null:
        self.icon_anchor.add_child(new_icon)
        self.attached_icon = new_icon

func _update_join_label() -> void:
    self.join_button.show()
    if self.player_peer_id == null:
        if self.ai_mode:
            if self.type == self.PLAYER_HUMAN:
                self.join_button_label.set_text(tr("TR_HUMAN"))
            else:
                self.join_button_label.set_text(tr("TR_AI"))
        else:
            self.join_button_label.set_text(tr("TR_JOIN"))
    else:
        self.join_button_label.set_text(tr("TR_LEAVE"))
        if self.player_peer_id != self.relay.peer_id:
            self.join_button.hide()
    if self.locked_out or (self.type == self.PLAYER_AI and not self.relay.is_server()):
        self.join_button.hide()

    if self.player_peer_id == null:
        if self.type == self.PLAYER_HUMAN:
            self.player.set_text(tr("TR_UNASSIGNED"))
        else:
            self.player.set_text(tr("TR_AI"))
    else:
        if self.relay.players.has(self.player_peer_id):
            self.player.set_text(str(self.relay.players[self.player_peer_id]["name"]))

func lock_side() -> void:
    self.locked_out = true
    _update_join_label()

func unlock_side() -> void:
    self.locked_out = false
    self.ai_mode = false
    _update_join_label()

func switch_to_ai() -> void:
    self.ai_mode = true
    _update_join_label()

func _update_ap_label() -> void:
    self.ap_button_label.set_text(str(self.ap) + " AP")
    self.ap_button_label2.set_text(str(self.ap) + " AP")

func _update_team_label() -> void:
    self.team_button_label.set_text(tr("TR_TEAM") + " " + str(self.team))
    self.team_button_label2.set_text(tr("TR_TEAM") + " " + str(self.team))

func _on_starting_ap_pressed() -> void:
    self.audio.play("menu_click")
    self.ap += self.AP_STEP
    if self.ap > self.AP_MAX:
        self.ap = 0
    self._update_ap_label()
    state_changed.emit(self.index)


func _on_swap_pressed() -> void:
    self.audio.play("menu_click")
    _perform_panel_swap()
    swap_happened.emit(self.index)

func _perform_panel_swap() -> void:
    var own_type: String = self.type
    var own_side: Variant = self.side
    var own_ap: int = self.ap
    var own_team: int = self.team
    var own_peer_id: Variant = self.player_peer_id
    var own_lock: bool = self.locked_out
    var own_ai: bool = self.ai_mode

    self.fill_panel(self.swap_target_node.side)
    self.type = self.swap_target_node.type
    self.ap = self.swap_target_node.ap
    self.team = self.swap_target_node.team
    self.player_peer_id = self.swap_target_node.player_peer_id
    self.locked_out = self.swap_target_node.locked_out
    self.ai_mode = self.swap_target_node.ai_mode
    self._update_join_label()
    self._update_ap_label()
    self._update_team_label()

    self.swap_target_node.fill_panel(own_side)
    self.swap_target_node.type = own_type
    self.swap_target_node.ap = own_ap
    self.swap_target_node.team = own_team
    self.swap_target_node.player_peer_id = own_peer_id
    self.swap_target_node.locked_out = own_lock
    self.swap_target_node.ai_mode = own_ai
    self.swap_target_node._update_join_label()
    self.swap_target_node._update_ap_label()
    self.swap_target_node._update_team_label()

func _on_team_pressed() -> void:
    self.team += 1
    if self.team > 4:
        self.team = 1
    self._update_team_label()
    state_changed.emit(self.index)


func _on_join_pressed() -> void:
    if self.player_peer_id == null:
        if self.ai_mode:
            if self.type == self.PLAYER_HUMAN:
                _set_type(self.PLAYER_AI)
            else:
                _set_type(self.PLAYER_HUMAN)
            state_changed.emit(self.index)
        else:
            _set_peer_id(self.relay.peer_id)
            player_joined.emit(self.index)
    else:
        _set_peer_id(null)
        player_left.emit(self.index)

func _set_peer_id(peer_id: Variant) -> void:
    self.type = self.PLAYER_HUMAN
    self.player_peer_id = peer_id
    _update_join_label()

func _set_ap(new_ap: int) -> void:
    self.ap = new_ap
    _update_ap_label()

func _set_team(new_team: int) -> void:
    self.team = new_team
    _update_team_label()

func _set_type(new_type: String) -> void:
    self.type = new_type
    _update_join_label()
