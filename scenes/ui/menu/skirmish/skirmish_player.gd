extends Control
class_name SkirmishPlayerPanel

const PLAYER_HUMAN: String = "human"
const PLAYER_AI: String = "ai"
const PLAYER_HUMAN_LABEL: String = "TR_HUMAN"
const PLAYER_AI_LABEL: String = "AI"

const AP_STEP: int = 50
const AP_MAX: int = 150

@onready var blue_player: Label = $"blue_player"
@onready var red_player: Label = $"red_player"
@onready var yellow_player: Label = $"yellow_player"
@onready var green_player: Label = $"green_player"
@onready var black_player: Label = $"black_player"

@onready var blue_border: Sprite2D = $"border_blue"
@onready var red_border: Sprite2D = $"border_red"
@onready var yellow_border: Sprite2D = $"border_yellow"
@onready var green_border: Sprite2D = $"border_green"
@onready var black_border: Sprite2D = $"border_black"

@onready var type_button: Label = $"player_type/label"
@onready var ap_button: Label = $"starting_ap/label"
@onready var team_button: Label = $"team/label"
@onready var swap_button: TextureButton = $"swap"

var side: Variant = null
var ap: int = 0
var type: String = PLAYER_HUMAN
@export var team: int = 1
@export var index: int = 0
@export var swap_target: NodePath
var swap_target_node: SkirmishPlayerPanel

@onready var audio: AudioService = SimpleAudioLibrary as AudioService


func _ready() -> void:
    self.swap_target_node = self.get_node(self.swap_target) as SkirmishPlayerPanel

func fill_panel(player_side: Variant) -> void:
    self._reset_labels()

    self.side = player_side

    match player_side:
        "blue":
            self.blue_player.show()
            self.blue_border.show()
        "red":
            self.red_player.show()
            self.red_border.show()
        "yellow":
            self.yellow_player.show()
            self.yellow_border.show()
        "green":
            self.green_player.show()
            self.green_border.show()
        "black":
            self.black_player.show()
            self.black_border.show()

func _reset_labels() -> void:
    self.blue_player.hide()
    self.red_player.hide()
    self.yellow_player.hide()
    self.green_player.hide()
    self.black_player.hide()

    self.blue_border.hide()
    self.red_border.hide()
    self.yellow_border.hide()
    self.green_border.hide()
    self.black_border.hide()

    self.ap = self.AP_STEP
    self.type = self.PLAYER_HUMAN
    self.side = null

    self._update_type_label()
    self._update_ap_label()
    self._update_team_label()

    if self.index == 0:
        self.swap_button.hide()

func _update_type_label() -> void:
    if self.type == self.PLAYER_HUMAN:
        self.type_button.set_text(self.PLAYER_HUMAN_LABEL)
    else:
        self.type_button.set_text(self.PLAYER_AI_LABEL)

func _update_ap_label() -> void:
    self.ap_button.set_text(str(self.ap) + " AP")

func _update_team_label() -> void:
    self.team_button.set_text(tr("TR_TEAM") + " " + str(self.team))

func _on_player_type_pressed() -> void:
    self.audio.play("menu_click")
    if self.type == self.PLAYER_HUMAN:
        self.type = self.PLAYER_AI
    else:
        self.type = self.PLAYER_HUMAN
    self._update_type_label()


func _on_starting_ap_pressed() -> void:
    self.audio.play("menu_click")
    self.ap += self.AP_STEP
    if self.ap > self.AP_MAX:
        self.ap = 0
    self._update_ap_label()


func _on_swap_pressed() -> void:
    self.audio.play("menu_click")
    var own_side: Variant = self.side
    var own_ap: int = self.ap
    var own_type: String = self.type
    var own_team: int = self.team

    self.fill_panel(self.swap_target_node.side)
    self.ap = self.swap_target_node.ap
    self.type = self.swap_target_node.type
    self.team = self.swap_target_node.team
    self._update_type_label()
    self._update_ap_label()
    self._update_team_label()

    self.swap_target_node.fill_panel(own_side)
    self.swap_target_node.ap = own_ap
    self.swap_target_node.type = own_type
    self.swap_target_node.team = own_team
    self.swap_target_node._update_type_label()
    self.swap_target_node._update_ap_label()
    self.swap_target_node._update_team_label()

func _on_team_pressed() -> void:
    self.team += 1
    if self.team > 4:
        self.team = 1
    self._update_team_label()
