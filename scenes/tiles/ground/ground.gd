extends MapObject
class_name BaseGround

var mouse_collision: GroundMouseCollision = null

func prepare() -> void:
	if self.mouse_collision == null:
		self.mouse_collision = $"mouse_collision"

func bind_ground_for_mouse(map: Map, tile_position: Vector2i) -> void:
	self.prepare()
	self.mouse_collision.map = map
	self.mouse_collision.tile_position = tile_position
