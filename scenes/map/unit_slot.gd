class_name UnitSlot
extends MapObjectSlot

func get_unit() -> BaseUnit:
    return self.get_map_object() as BaseUnit

func _can_hold(map_object: MapObject) -> bool:
    return map_object is BaseUnit
