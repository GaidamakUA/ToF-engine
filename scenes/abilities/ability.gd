extends Node
class_name Ability

var TYPE := "undefined"

@export var dlc_version := 1
@export var index := 0
@export var label := ""
@export var description := ""
@export var ap_cost := 0
@export var cooldown := 0
@export var ability_range := 0
@export var draw_range := 0
@export var in_line := false
var source = null
var active_source_tile = null
var cd_turns_left := 0
var disabled := false

func _ready() -> void:
    self.signal_to_parent()

func signal_to_parent() -> void:
    self.receive_signal(self.get_parent())

func receive_signal(receiver) -> void:
    receiver.register_ability(self)
    self.source = receiver

func execute(board: Board, position: Vector2i) -> void:
    self._execute(board, position)
    board.events.emit_ability_used(self, position)
    self.activate_cooldown(board)

func _execute(_board: Board, _position: Vector2i) -> void:
    return

func is_visible(_board=null) -> bool:
    if self.disabled:
        return false

    return self._is_visible(_board)

func _is_visible(_board: Board) -> bool:
    return true

func is_available(_board=null) -> bool:
    return true

func is_on_cooldown() -> bool:
    return self.cd_turns_left > 0

func activate_cooldown(board: Board) -> void:
    var modified_cooldown := board.abilities.get_modified_cooldown(self.get_cooldown(), self.source)

    self.cd_turns_left = modified_cooldown

func reset_cooldown() -> void:
    self.cd_turns_left = 0

func cd_tick_down() -> void:
    if self.cd_turns_left > 0:
        self.cd_turns_left -= 1

func get_cost() -> int:
    return self.ap_cost

func get_cooldown() -> int:
    return self.cooldown
