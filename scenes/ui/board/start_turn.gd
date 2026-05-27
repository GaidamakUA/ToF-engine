extends Node2D
class_name StartTurnView

@onready var animations: AnimationPlayer = $"animations"

@onready var blue_player: Label = $"background/blue_player"
@onready var red_player: Label = $"background/red_player"
@onready var yellow_player: Label = $"background/yellow_player"
@onready var green_player: Label = $"background/green_player"
@onready var black_player: Label = $"background/black_player"

@onready var turn_label: Label = $"background/turn"

func flash(player: String, turn: int) -> void:
    self._reset_labels()
    self.turn_label.set_text(tr("TR_TURN") + " " + str(turn))

    match player:
        "blue":
            self.blue_player.show()
        "red":
            self.red_player.show()
        "yellow":
            self.yellow_player.show()
        "green":
            self.green_player.show()
        "black":
            self.black_player.show()

    self.animations.play("show")

func _reset_labels() -> void:
    self.blue_player.hide()
    self.red_player.hide()
    self.yellow_player.hide()
    self.green_player.hide()
    self.black_player.hide()
