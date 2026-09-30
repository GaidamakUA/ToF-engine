extends BaseOutcome
class_name ObjectiveOutcome

var slot: Variant = null
var text: Variant = null
var clear: bool = false

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.set_objective(int(self.slot) if self.slot != null else 0, "" if self.text == null else String(self.text), self.clear and self.slot == null)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has('slot'):
        self.slot = details['slot']
    if details.has('text'):
        self.text = details['text']
    if details.has('clear'):
        self.clear = bool(details['clear'])
