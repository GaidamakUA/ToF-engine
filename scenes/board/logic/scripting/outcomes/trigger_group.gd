extends BaseOutcome

var name: String
var group: String
var action: String

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    if self.action == "add":
        self.board.scripting.add_to_group(self.group, self.name)
    elif self.action == "remove":
        self.board.scripting.remove_from_group(self.group, self.name)


func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.name = String(details['name'])
    self.group = String(details['group'])
    self.action = String(details['action'])
