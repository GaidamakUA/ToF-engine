extends Node3D
class_name Map

const TILE_SIZE: int = 8
const GROUND_HEIGHT: int = 4

@onready var tile_box: TileBox = $"tiles/tile_box"
@onready var camera: GameCamera = $"camera"
@onready var campaign: CampaignService = Campaign as CampaignService
@onready var mouse_layer: MouseLayerService = MouseLayer as MouseLayerService
@onready var settings: SettingsService = Settings as SettingsService

var tile_box_space_size: int
var tile_box_position := Vector2i(0, 0)
var tile_box_mouse := false

var templates := MapTemplates.new()
var model := MapModel.new()
var builder := MapBuilder.new(self)
var loader: MapLoader = MapLoader.new(self)

@onready var tiles_ground_anchor: Node3D = $"tiles/ground"
@onready var tiles_frames_anchor: Node3D = $"tiles/frames"
@onready var tiles_terrain_anchor: Node3D = $"tiles/terrain"
@onready var tiles_buildings_anchor: Node3D = $"tiles/buildings"
@onready var tiles_units_anchor: Node3D = $"tiles/units"

func _ready() -> void:
    self.tile_box_space_size = self.camera.camera_space_size - self.TILE_SIZE

    self.settings.changed.connect(_settings_changed)
    for i: String in self.model.tiles.keys():
        self.model.tiles[i].settings = self.settings
        self.settings.changed.connect(self.model.tiles[i]._settings_changed)

    if not self.settings.get_option("decorations"):
        self.tiles_frames_anchor.hide()

func _input(raw_event: InputEvent) -> void:
    if raw_event is InputEventMouseMotion:
        var event: InputEventMouseMotion = raw_event as InputEventMouseMotion
        if event.relative.length_squared() > 0.01:
            self.tile_box_mouse = true

func _physics_process(_delta: float) -> void:
    self._manage_mouse_input()
    self.update_tile_box_position_from_camera()
    self.snap_tile_box()

func _manage_mouse_input() -> void:
    var gamepad_offset: Vector2 = Vector2(
        Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
        Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
    )
    if gamepad_offset.length_squared() > 0.1:
        self.tile_box_mouse = false


func update_tile_box_position_from_camera() -> void:
    if self.camera.snap_tile_box_to_camera:
        self.tile_box_position = self.local_to_map(self.camera.get_position())

func set_tile_box_position(box_position: Vector2i) -> void:
    self.camera.snap_tile_box_to_camera = false
    self.tile_box_position = box_position

func set_mouse_box_position(box_position: Vector2i) -> void:
    if self.tile_box_mouse:
        self.set_tile_box_position(box_position)


func snap_tile_box() -> void:
    var box_position: Vector3 = self.tile_box.get_position()
    var placement: Vector3 = Map.map_to_local(self.tile_box_position)

    placement.y = box_position.y

    self.tile_box.set_position(placement)

static func map_to_local(queried_position: Vector2i) -> Vector3:
    return Vector3(queried_position.x * TILE_SIZE, 0, queried_position.y * TILE_SIZE)

func local_to_map(queried_position: Vector3) -> Vector2i:
    var tile_position := Vector2i(0, 0)

    if queried_position.x == self.camera.camera_space_size:
        queried_position.x = self.tile_box_space_size
    if queried_position.z == self.camera.camera_space_size:
        queried_position.z = self.tile_box_space_size

    var camera_position_x: int = int(queried_position.x)
    var camera_position_z: int = int(queried_position.z)

    @warning_ignore('integer_division')
    tile_position.x = int((camera_position_x - (camera_position_x % self.TILE_SIZE)) / self.TILE_SIZE)
    @warning_ignore('integer_division')
    tile_position.y = int((camera_position_z - (camera_position_z % self.TILE_SIZE)) / self.TILE_SIZE)

    return tile_position


func set_tile_box_side(side: String) -> void:
    self.tile_box.set_mesh_material(self.templates.get_side_material(side))

func show_tile_box() -> void:
    self.tile_box.show()

func hide_tile_box() -> void:
    self.tile_box.hide()

func move_camera_to_position(destination: Variant) -> void:
    if destination == null:
        return

    var destination_position: Vector2 = Vector2(destination)
    self.camera.move_camera_to_position(destination_position * self.TILE_SIZE * 1.0 + Vector2(0.5, 0.5) * self.TILE_SIZE)

func move_camera_to_position_if_far_away(destination: Variant, tolerance: int = 5, zoom: Variant = null) -> bool:
    if zoom != null:
        self.camera.set_camera_zoom(zoom)

    if destination == null:
        return false

    var destination_position: Vector2i = Vector2i(destination)
    self.camera.snap_tile_box_to_camera = true
    self.update_tile_box_position_from_camera()
    var adj_tol: float = tolerance * self.camera.get_zoom_fraction()
    if self.tile_box_position.distance_squared_to(destination_position) > (adj_tol * adj_tol) or zoom != null:
        self.move_camera_to_position(destination_position)

    return true

func snap_camera_to_position(destination: Vector2i) -> void:
    self.camera.set_camera_position(Vector2(destination) * self.TILE_SIZE + Vector2(0.5, 0.5) * self.TILE_SIZE)

func anchor_unit(unit: BaseUnit, unit_position: Vector2i) -> void:
    var world_position: Vector3 = Map.map_to_local(unit_position)
    world_position.y = self.GROUND_HEIGHT
    self.tiles_units_anchor.add_child(unit)
    unit.set_position(world_position)


func detach_unit(unit: BaseUnit) -> void:
    self.tiles_units_anchor.remove_child(unit)

func hide_invisible_tiles() -> void:
    for i: String in self.model.tiles.keys():
        self.model.tiles[i].apply_invisibility()


func _settings_changed(key: String, new_value: Variant) -> void:
    if key == "decorations":
        if new_value:
            self.tiles_frames_anchor.show()
        else:
            self.tiles_frames_anchor.hide()
