class_name TileSlot
var _map_object: MapObject = null

func get_map_object() -> MapObject:
    return self._map_object

func set_map_object(new_map_object: MapObject) -> void:
    if self._map_object != null:
        self.clear()

    self._map_object = new_map_object

func clear() -> void:
    if self._map_object == null:
        return

    self._map_object.queue_free()
    self._map_object = null

func release() -> void:
    if self._map_object != null:
        self._map_object = null

func is_present() -> bool:
    return self._map_object != null

func get_dict() -> Dictionary[String, Variant]:
    if self._map_object == null:
        return {
            "tile" : null,
            "rotation" : 0,
        }
    else:
        return self._map_object.get_dict()
