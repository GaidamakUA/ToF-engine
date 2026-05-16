extends BaseOutcome
class_name ApOutcome

var amount: int
var side: String
var set_ap_value: bool = false
var cap_ap_value: bool = false

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var player_id: int = self.board.state.get_player_id_by_side(self.side)
    if self.set_ap_value:
        self.board.state.set_player_ap(player_id, self.amount)
    elif self.cap_ap_value:
        if self.board.state.get_current_ap() > self.amount:
            self.board.state.set_player_ap(player_id, self.amount)
    else:
        self.board.state.add_player_ap(player_id, self.amount)
    self.board.ui.update_resource_value(self.board.state.get_current_ap())

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.amount = int(details['amount'])
    self.side = String(details['side'])

    if details.has("set"):
        self.set_ap_value = bool(details["set"])
    if details.has("cap"):
        self.cap_ap_value = bool(details["cap"])
