extends MapObject
class_name MapTileHitbox

var mouse_area: MapTileMouseArea = null

func prepare() -> void:
    if self.mouse_area == null:
        self.mouse_area = $"mouse_area"

func bind_map_tile(map: Map, tile_position: Vector2i) -> void:
    self.prepare()
    self.mouse_area.map = map
    self.mouse_area.tile_position = tile_position
