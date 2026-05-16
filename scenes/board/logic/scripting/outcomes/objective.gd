extends BaseOutcome
class_name ObjectiveOutcome

var slot: Variant = null
var text: Variant = null
var clear: bool = false

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    if self.clear:
        if self.slot != null:
            self.board.ui.objectives.clear_objective_slot(self.slot)
        else:
            self.board.ui.objectives.clear()
    else:
        self.board.ui.objectives.set_objective_slot(self.slot, self.text)
        self.board.ui.objectives.flash()

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has('slot'):
        self.slot = details['slot']
    if details.has('text'):
        self.text = details['text']
    if details.has('clear'):
        self.clear = bool(details['clear'])
