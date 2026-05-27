extends Control
class_name MapEditorUi

@onready var settings: SettingsService = Settings as SettingsService

@onready var radial: Radial = $"radial/radial"
@onready var picker: MapPickerPanel = $"picker/picker"
@onready var controls: Control = $"controls/editor"
@onready var story: MapEditorStoryEditor = $"story/StoryEditor"
@onready var minimap: MinimapView = $"minimap"
@onready var minimap_animations: AnimationPlayer = $"minimap/animations"

@onready var position_label: Label = $"position/label"
@onready var map_name_wrapper: MarginContainer = $"map_name"
@onready var map_name_label: Label = $"map_name/inner/label"

@onready var tile_animations: AnimationPlayer = $"tile/animations"
@onready var tile_prev: TileView = $"tile/wrapper/tile_view_prev"
@onready var tile_current: TileView = $"tile/wrapper/tile_view_current"
@onready var tile_next: TileView = $"tile/wrapper/tile_view_next"
@onready var type_prev: TileView = $"tile/wrapper/tile_type_prev"
@onready var type_next: TileView = $"tile/wrapper/tile_type_next"

# Edge pan
@onready var edge_pan_left: Control = $"edge_pan/left"
@onready var edge_pan_right: Control = $"edge_pan/right"
@onready var edge_pan_top: Control = $"edge_pan/top"
@onready var edge_pan_bottom: Control = $"edge_pan/bottom"

var icons: IconsFactory = IconsFactory.new()

func _ready() -> void:
    self.map_name_label.set_message_translation(false)
    self.map_name_label.notification(NOTIFICATION_TRANSLATION_CHANGED)
    self.show_controls()

func update_position(x: int, y: int) -> void:
    self.position_label.set_text("[" + str(x) + ", " + str(y) + "]")

func set_tile_prev(tile: MapObject, t_rotation: int) -> void:
    self.tile_prev.set_tile(tile, t_rotation)

func set_tile_current(tile: MapObject, t_rotation: int) -> void:
    self.tile_current.set_tile(tile, t_rotation)

func set_tile_next(tile: MapObject, t_rotation: int) -> void:
    self.tile_next.set_tile(tile, t_rotation)

func set_type_prev(tile: MapObject, t_rotation: int) -> void:
    self.type_prev.set_tile(tile, t_rotation)

func set_type_next(tile: MapObject, t_rotation: int) -> void:
    self.type_next.set_tile(tile, t_rotation)

func toggle_radial() -> void:
    if self.radial.is_visible():
        self.hide_radial()
        self.show_tiles()
        self.show_position()
    else:
        self.show_radial()
        self.hide_tiles()
        self.hide_position()


func show_tiles() -> void:
    self.tile_animations.play("show")
    self.show_minimap()
    self.show_controls()

func hide_tiles() -> void:
    self.tile_animations.play("hide")
    self.hide_minimap()
    self.hide_controls()

func show_minimap() -> void:
    self.minimap_animations.play("show")
    if self.map_name_label.get_text() != "":
        self.map_name_wrapper.show()

func hide_minimap() -> void:
    self.minimap_animations.play("hide")
    self.map_name_wrapper.hide()

func show_radial() -> void:
    self.radial.show_menu()

func hide_radial() -> void:
    self.radial.hide_menu()

func show_picker() -> void:
    self.picker.show_picker()

func hide_picker() -> void:
    self.picker.hide_picker()

func show_position() -> void:
    self.position_label.show()

func hide_position() -> void:
    self.position_label.hide()

func close_all_popups() -> void:
    if self.picker.is_visible():
        self.hide_picker()
    if self.story.is_visible():
        self.hide_story()

func is_radial_open() -> bool:
    return self.radial.is_visible()

func is_popup_open() -> bool:
    if self.picker.is_visible():
        return true
    if self.story.is_visible():
        return true

    return false

func is_panel_open() -> bool:
    if self.radial.is_visible():
        return true
    if self.is_popup_open():
        return true

    return false

func set_map_name(map_name: String, skip_show: bool = false) -> void:
    self.map_name_label.set_text(map_name)
    self.picker.set_map_name(map_name)

    if map_name != "" and not skip_show:
        self.map_name_wrapper.show()
    else:
        self.map_name_wrapper.hide()

func load_minimap(map_name: String) -> void:
    self.minimap.remove_from_cache(map_name)
    self.minimap.fill_minimap(map_name)

func wipe_minimap() -> void:
    self.minimap.wipe()

func show_controls() -> void:
    if self.settings.get_option("show_controls"):
        self.controls.show()

func hide_controls() -> void:
    self.controls.hide()

func show_story() -> void:
    self.story.show_panel()

func hide_story() -> void:
    self.story.hide()
