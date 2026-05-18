extends Node2D
class_name Radial

signal close_requested

@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var animations: AnimationPlayer = $"animations"
@onready var label_node: Node2D = $"label"
@onready var label_text: Label = $"label/label"

@export var analog_axis_x: int = JOY_AXIS_LEFT_X
@export var analog_axis_y: int = JOY_AXIS_LEFT_Y
@export var device_id: int = 0

var fields: Array[RadialField] = []
var focused_field: RadialField = null

var mouse_mode: bool = false
var opening: bool = false

func _ready() -> void:
    self.fields.assign([
        $"fields/field1",
        $"fields/field2",
        $"fields/field3",
        $"fields/field4",
        $"fields/field5",
        $"fields/field6",
        $"fields/field7",
        $"fields/field8",
    ])
    self.set_process_input(false)

    var index: int = 0
    while index < self.fields.size():
        self.fields[index].bind_radial(self, index)
        index += 1

func _input(event: InputEvent) -> void:
    if not get_window().has_focus():
        return

    var axis_value := Vector2()

    axis_value.x = Input.get_joy_axis(self.device_id, self.analog_axis_x)
    axis_value.y = Input.get_joy_axis(self.device_id, self.analog_axis_y)

    if axis_value.length() > 0.5:
        self.mouse_mode = false
        var angle: float = rad_to_deg(axis_value.angle()) + 112.5
        if angle < 0.0:
            angle += 360

        var rounded_angle: int = int(round(angle))

        var option: int = int((rounded_angle - (rounded_angle % 45)) / 45)

        self.focus_field(option)

        if event.is_action_pressed("ui_accept"):
            self.execute_focused_field()

    else:
        if not self.mouse_mode:
            self.unfocus_field()

    if event.is_action_released("mouse_click"):
        if self.is_field_focused():
            self.execute_focused_field()
        else:
            self.close_requested.emit()

func show_menu() -> void:
    self.opening = true
    self.animations.play("show")
    self.set_process_input(true)

func _show_menu_done() -> void:
    self.opening = false
    self.set_process_input(true)


func hide_menu() -> void:
    self.animations.play("hide")
    self.set_process_input(false)
    self.unfocus_field()

func set_field(icon: Node, new_label: String, index: int, new_bound_object: Object = null, new_bound_method: StringName = &"", new_bound_args: Array = []) -> void:
    self.fields[index].set_field(icon, new_label, new_bound_object, new_bound_method, new_bound_args)

func set_field_disabled(index: int, cooldown: Variant = null, ignore_disabled_state: bool = false) -> void:
    self.fields[index].set_disabled(cooldown)
    self.fields[index].ignore_disabled = ignore_disabled_state

func clear_field_disabled(index: int) -> void:
    self.fields[index].clear_disabled()

func clear_fields() -> void:
    for field: RadialField in self.fields:
        field.clear()

func clear_field(index: int) -> void:
    self.fields[index].clear()

func focus_field(index: int) -> void:
    if index >= self.fields.size():
        return
    if self.fields[index].focused:
        return

    self.unfocus_field()

    if not self.fields[index].is_assigned():
        return

    self.fields[index].focus()
    self.show_label(self.fields[index].label)
    self.focused_field = self.fields[index]

func unfocus_field() -> void:
    if self.focused_field != null:
        self.focused_field.unfocus()
    self.hide_label()
    self.focused_field = null

func show_label(new_label: String) -> void:
    self.label_node.show()
    self.label_text.set_text(new_label)

func hide_label() -> void:
    self.label_node.hide()

func is_field_focused() -> bool:
    return self.focused_field != null

func execute_focused_field() -> void:
    if not self.is_field_focused():
        return

    if not self.is_visible():
        return

    self.audio.play("menu_click")
    self.focused_field.execute_bound_method()
