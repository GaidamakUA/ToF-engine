extends BaseUnit
class_name Heli

var passenger: BaseUnit = null

func get_dict() -> Dictionary[String, Variant]:
    var new_dict: Dictionary[String, Variant] = super.get_dict()

    if self.passenger != null:
        new_dict["passenger"] = self.passenger.get_dict()

    return new_dict
