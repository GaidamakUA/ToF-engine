extends Node2D
class_name Element3DView

@onready var animations: AnimationPlayer = $"animations"
@onready var screen: Sprite2D = $"screen"
@onready var viewport: SubViewport = $"SubViewport"
@onready var tile_camera: Node3D = $"SubViewport/tile_cam"
@onready var lens: Camera3D = $"SubViewport/tile_cam/pivot/arm/lens"

@export var zoom_value: float = 10

var model: Node = null

func _ready() -> void:
    var lens_distance: Vector3 = Vector3(0, 0, self.zoom_value)
    self.lens.set_position(lens_distance)
    self.refresh()

func refresh() -> void:

    var texture: Texture2D = self.viewport.get_texture()
    self.screen.texture = texture

func set_model(new_model: Node) -> void:
    if self.model != null:
        self.clear()

    self.model = new_model
    self.tile_camera.add_child(new_model)

    self.refresh()

func clear() -> void:
    if self.model == null:
        return

    self.model.queue_free()
    self.model = null

func hide_background() -> void:
    $"background".hide()

func flash() -> void:
    self.animations.play("flash")

func stop_flash() -> void:
    self.animations.play("RESET")
