extends BaseOutcome
class_name TriggerOutcome

var name: String = ""
var group: String = ""
var suspended: bool
var turns: int = -1

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    if self.group != "":
        self.board.scripting.suspend_group(self.group, self.suspended)
    elif self.name != "":
        self.board.scripting.suspend_trigger(self.name, self.suspended)

        if self.turns >= 0:
            var trigger: TurnTrigger = self.board.scripting.triggers[self.name] as TurnTrigger
            assert(trigger != null)
            trigger.turn_no = self.board.state.turn + self.turns

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.suspended = bool(details['suspended'])
    if details.has("name"):
        self.name = details["name"]
    if details.has("group"):
        self.group = details["group"]
    if details.has("turns"):
        self.turns = details["turns"]
