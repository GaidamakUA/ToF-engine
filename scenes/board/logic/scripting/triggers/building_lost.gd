extends BaseTrigger
class_name BuildingLostTrigger

var building: Variant = null
var building_type: Variant = null

func _init() -> void:
    self.observed_event_type = BuildingCapturedEvent

func _observe(_event: BaseEvent) -> void:
    var event: BuildingCapturedEvent = _event as BuildingCapturedEvent
    if self.building != null and event.building == self.building:
        self.execute_outcome(event)
    elif self.building_type != null and event.building.template_name == self.building_type:
        self.execute_outcome(event)

func _get_outcome_metadata(_event: BaseEvent) -> Dictionary[String, Variant]:
    var event: BuildingCapturedEvent = _event as BuildingCapturedEvent
    return {
        'old_side' : event.old_side,
        'new_side' : event.new_side
    }
