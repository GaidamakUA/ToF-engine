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
var _rotor_pivots: Array[Node3D] = []
var _rotor_axes: Array[Vector3] = []

func _ready() -> void:
    self.lens.set_size(self.viewport_size)
    self.refresh()

func _process(delta: float) -> void:
    for index: int in self._rotor_pivots.size():
        self._rotor_pivots[index].rotate_object_local(
            self._rotor_axes[index], UnitResource.ROTOR_SPEED * delta
        )

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
    self._rotor_pivots.clear()
    self._rotor_axes.clear()
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

    var unit_resource: UnitResource = source as UnitResource
    if unit_resource != null:
        self._add_rotors(unit_resource, mesh_instance)

    if source.reflection_mesh != null:
        var reflection := MeshInstance3D.new()
        reflection.mesh = source.reflection_mesh
        reflection.material_override = preview_material if preview_material != null else self.REFLECTION_MATERIAL
        preview.add_child(reflection)
    return preview

func _add_rotors(source: UnitResource, parent: Node3D) -> void:
    for rotor: RotorResource in source.rotors:
        assert(rotor.mesh != null)
        assert(not rotor.rotation_axis.is_zero_approx())
        var pivot := Node3D.new()
        pivot.transform = rotor.pivot_transform
        parent.add_child(pivot)

        var rotor_mesh := MeshInstance3D.new()
        rotor_mesh.mesh = rotor.mesh
        rotor_mesh.transform = rotor.mesh_transform
        rotor_mesh.cast_shadow = source.mesh_cast_shadow
        rotor_mesh.material_override = self.DEFAULT_MATERIAL
        pivot.add_child(rotor_mesh)

        self._rotor_pivots.append(pivot)
        self._rotor_axes.append(rotor.rotation_axis.normalized())

func clear() -> void:
    self._rotor_pivots.clear()
    self._rotor_axes.clear()
    if self.tile == null:
        return

    self.tile.free()
    self.tile = null

func hide_background() -> void:
    $"background".hide()
