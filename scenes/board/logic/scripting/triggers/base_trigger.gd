extends Observer
class_name BaseTrigger

var outcome: BaseOutcome
var one_off: bool = false

func execute_outcome(event: BaseEvent) -> void:
    self._execute_outcome(event)
    if self.one_off:
        self.deactivate()

func _execute_outcome(event: BaseEvent) -> void:
    self.outcome.execute(self._get_outcome_metadata(event))

func _get_outcome_metadata(_event: BaseEvent) -> Dictionary[String, Variant]:
    return {}

func ingest_details(_details: Dictionary[String, Variant]) -> void:
    return

func get_save_data() -> Dictionary[String, Variant]:
    return {
        "suspended": self.suspended
    }

func restore_from_state(state: Dictionary[String, Variant]) -> void:
    self.suspended = bool(state["suspended"])
