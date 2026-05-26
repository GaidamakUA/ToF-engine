extends Control
class_name ObjectivesUi

@onready var wrapper: Control = $"objective_wrapper"
@onready var animations: AnimationPlayer = $"animations"
@onready var background: NinePatchRect = $"objective_wrapper/background"

@onready var objectives: Array[Label] = [
	$"objective_wrapper/obj1",
	$"objective_wrapper/obj2",
	$"objective_wrapper/obj3",
	$"objective_wrapper/obj4"
]
var raw_text := [null, null, null, null]


func clear() -> void:
	for slot: Label in self.objectives:
		self._clear_slot(slot)

func set_objective_slot(slot: int, text: String) -> void:
	self.raw_text[slot] = text
	self.objectives[slot].set_text(text)
	self.objectives[slot].show()

func clear_objective_slot(slot: int) -> void:
	self._clear_slot(self.objectives[slot])

func _clear_slot(slot: Label) -> void:
	slot.set_text("")
	slot.hide()

func restore_from_state(state: Array) -> void:
	for i: int in range(self.objectives.size()):
		if state[i] != null:
			self.set_objective_slot(i, state[i])

func flash() -> void:
	if not self.animations.is_playing():
		self.animations.play("flash")

func fade_in() -> void:
	if not self.background.is_visible():
		self.animations.play("show")

func fade_out() -> void:
	if self.background.is_visible():
		self.animations.play("hide")
