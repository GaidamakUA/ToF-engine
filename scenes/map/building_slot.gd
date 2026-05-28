class_name BuildingSlot
extends MapObjectSlot

func get_building() -> BaseBuilding:
    return self.get_map_object() as BaseBuilding

func _can_hold(map_object: MapObject) -> bool:
    return map_object is BaseBuilding
