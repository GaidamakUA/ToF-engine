extends BaseOutcome
class_name TriggerGroupOutcome

var name: String
var group: String
var action: String

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.set_trigger_group(self.name, self.group, self.action == "add")


func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.name = String(details['name'])
    self.group = String(details['group'])
    self.action = String(details['action'])
