class_name TileFragment
var tile = null

func set_tile(new_tile: MapObject) -> void:
    if self.tile != null:
        self.clear()

    self.tile = new_tile

func clear() -> void:
    if self.tile == null:
        return

    self.tile.queue_free()
    self.tile = null

func release() -> void:
    if self.tile != null:
        self.tile = null

func is_present() -> bool:
    return self.tile != null

func get_dict() -> Dictionary[String, Variant]:
    if self.tile == null:
        return {
            "tile" : null,
            "rotation" : 0,
        }
    else:
        return self.tile.get_dict()
