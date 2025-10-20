extends BaseEvent
class_name AbilityUsedEvent

var consumed := false

func _init(new_type: Events.Type):
    super(new_type)
    pass

var ability: Ability
var target: Vector2i
