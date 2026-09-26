extends Node2D
class_name TileView

const DEFAULT_MATERIAL: Material = preload("res://assets/materials/arne32.tres")
const REFLECTION_MATERIAL: Material = preload("res://assets/materials/arne32_reflective.tres")

@export var viewport_size: int = 20

@export var is_side_tile: bool = false

@onready var screen: Sprite2D = $"screen"
@onready var viewport: SubViewport = $"SubViewport"
@onready var tile_camera: Node3D = $"SubViewport/tile_cam"
@onready var lens: Camera3D = $"SubViewport/tile_cam/pivot/arm/lens"

var tile: Node3D = null

func _ready() -> void:
    self.lens.set_size(self.viewport_size)
    self.refresh()

func refresh() -> void:
    var texture: Texture2D = self.viewport.get_texture()
    self.screen.texture = texture

func set_tile(source: MapObjectResource, requested_rotation: int, preview_material: Material = null, height_override: float = NAN) -> void:
    if self.tile != null:
        self.clear()

    self.tile = self._create_preview(source, preview_material)
    self.tile_camera.add_child(self.tile)

    var tile_rotation: Vector3 = Vector3(0, deg_to_rad(requested_rotation), 0)
    self.tile.set_rotation(tile_rotation)

    var camera_modifier: int = source.side_tile_view_cam_modifier if self.is_side_tile else source.main_tile_view_cam_modifier

    var height_modifier: float = source.tile_view_height_cam_modifier
    if not is_nan(height_override):
        height_modifier = height_override
    if height_modifier != 0:
        self.tile.position.y += height_modifier

    self.lens.set_size(self.viewport_size + camera_modifier)
    self.refresh()

func _create_preview(source: MapObjectResource, preview_material: Material = null) -> Node3D:
    var preview := Node3D.new()
    if source.mesh == null:
        return preview

    var mesh_instance := MeshInstance3D.new()
    mesh_instance.mesh = source.mesh
    mesh_instance.transform = source.mesh_transform
    mesh_instance.position.y = 0
    mesh_instance.cast_shadow = source.mesh_cast_shadow
    mesh_instance.material_override = preview_material if preview_material != null else source.mesh_material_override
    if source is TileResource and mesh_instance.material_override == null:
        mesh_instance.material_override = self.DEFAULT_MATERIAL
    preview.add_child(mesh_instance)

    if source.reflection_mesh != null:
        var reflection := MeshInstance3D.new()
        reflection.mesh = source.reflection_mesh
        reflection.material_override = preview_material if preview_material != null else self.REFLECTION_MATERIAL
        preview.add_child(reflection)
    return preview

func clear() -> void:
    if self.tile == null:
        return

    self.tile.free()
    self.tile = null

func hide_background() -> void:
    $"background".hide()
