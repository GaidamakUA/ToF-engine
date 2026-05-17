extends Node2D
class_name RadialField

@onready var background: Sprite2D = $"background"
@onready var white_outline: Sprite2D = $"white"
@onready var disabled: Sprite2D = $"disabled"
@onready var cd_label: Label = $"disabled/cd"

var default_background: Color
var full_background: Color

var icon: Node = null
var label: String = ""

var focused: bool = false

var bound_object: Object = null
var bound_method: StringName = &""
var bound_args: Array = []
var ignore_disabled: bool = false

var radial: Radial
var index: int

func _ready() -> void:
	self.default_background = self.background.get_modulate()
	self.full_background = Color(1, 1, 1, 1)

func bind_radial(_radial: Radial, _index: int) -> void:
	self.radial = _radial
	self.index = _index

func set_field(new_icon: Node, new_label: String, new_bound_object: Object = null, new_bound_method: StringName = &"", new_bound_args: Array = []) -> void:
	self.icon = new_icon
	self.label = new_label
	self.set_visible(true)

	if self.icon != null:
		$"icon_anchor".add_child(self.icon)

	self.bound_object = new_bound_object
	self.bound_method = new_bound_method
	self.bound_args = new_bound_args

func set_disabled(cooldown: Variant = null) -> void:
	self.disabled.show()

	if cooldown != null:
		self.cd_label.set_text(str(cooldown))
	else:
		self.cd_label.set_text("")

func clear_disabled() -> void:
	self.disabled.hide()

func clear() -> void:
	if self.icon != null:
		self.icon.queue_free()

	self.icon = null
	self.label = ""
	self.set_visible(false)
	self.disabled.hide()

	self.bound_object = null
	self.bound_method = &""
	self.bound_args = []
	self.ignore_disabled = false

func focus() -> void:
	self.background.set_modulate(self.full_background)
	self.white_outline.show()
	self.focused = true

func unfocus() -> void:
	self.background.set_modulate(self.default_background)
	self.white_outline.hide()
	self.focused = false

func is_assigned() -> bool:
	return self.label != ""

func execute_bound_method() -> void:
	if self.disabled.is_visible() and not self.ignore_disabled:
		return

	if self.bound_object != null:
		if self.bound_args.size() > 0:
			self.bound_object.call_deferred(self.bound_method, self.bound_args)
		else:
			self.bound_object.call_deferred(self.bound_method)


func _on_mouse_click_mouse_entered() -> void:
	self.radial.focus_field(self.index)
	self.radial.mouse_mode = true


func _on_mouse_click_mouse_exited() -> void:
	self.radial.unfocus_field()
