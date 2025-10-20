class_name BaseTrigger

var board: Board
var outcome: BaseOutcome
var suspended := false
var observed_event_type: Array[Events.Type] = []
var one_off := false

func observe(event: BaseEvent) -> void:
    if self.suspended:
        return

    self._observe(event)

func _observe(_event: BaseEvent) -> void:
    return

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

func activate() -> void:
    self.suspended = false

func deactivate() -> void:
    self.suspended = true

func get_save_data() -> Dictionary[String, Variant]:
    return {
        "suspended": self.suspended
    }

func restore_from_state(state: Dictionary[String, Variant]) -> void:
    self.suspended = state["suspended"]
