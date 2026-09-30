extends BaseOutcome
class_name ApOutcome

var amount: int
var side: String
var set_ap_value: bool = false
var cap_ap_value: bool = false

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    if self.set_ap_value:
        self.model.set_player_ap(self.side, self.amount, &"set")
    elif self.cap_ap_value:
        self.model.set_player_ap(self.side, self.amount, &"cap")
    else:
        self.model.set_player_ap(self.side, self.amount)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.amount = int(details['amount'])
    self.side = String(details['side'])

    if details.has("set"):
        self.set_ap_value = bool(details["set"])
    if details.has("cap"):
        self.cap_ap_value = bool(details["cap"])
