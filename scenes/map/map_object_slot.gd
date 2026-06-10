class_name MapObjectSlot
var _map_object: MapObject = null

func get_map_object() -> MapObject:
    return self._map_object

func set_map_object(new_map_object: MapObject) -> void:
    assert(self._can_hold(new_map_object))
    self.clear()
    self._map_object = new_map_object

func _can_hold(map_object: MapObject) -> bool:
    return map_object != null

func clear() -> void:
    if self._map_object == null:
        return

    self._map_object.queue_free()
    self._map_object = null

func release() -> MapObject:
    var map_object: MapObject = self._map_object
    self._map_object = null
    return map_object

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
