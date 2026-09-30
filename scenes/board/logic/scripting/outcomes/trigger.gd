extends BaseOutcome
class_name TriggerOutcome

var name: String = ""
var group: String = ""
var suspended: bool
var turns: int = -1

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.set_trigger_enabled(self.name, self.group, self.suspended, self.turns)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.suspended = bool(details['suspended'])
    if details.has("name"):
        self.name = details["name"]
    if details.has("group"):
        self.group = details["group"]
    if details.has("turns"):
        self.turns = details["turns"]
