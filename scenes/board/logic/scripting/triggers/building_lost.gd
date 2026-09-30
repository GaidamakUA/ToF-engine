extends BaseTrigger
class_name BuildingLostTrigger

var building: Variant = null
var building_type: Variant = null

func _init() -> void:
    self.observed_event_type = BuildingCapturedDomainEvent

func _observe(_event: BoardDomainEvent) -> void:
    var event := _event as BuildingCapturedDomainEvent
    var captured: BaseBuilding = self.model.map_model.get_tile(event.position).building.tile
    if self.building != null and captured == self.building:
        self.execute_outcome(event)
    elif self.building_type != null and captured.template_name == self.building_type:
        self.execute_outcome(event)

func _get_outcome_metadata(_event: BoardDomainEvent) -> Dictionary[String, Variant]:
    var event := _event as BuildingCapturedDomainEvent
    return {
        'old_side' : event.old_side,
        'new_side' : event.new_side
    }
