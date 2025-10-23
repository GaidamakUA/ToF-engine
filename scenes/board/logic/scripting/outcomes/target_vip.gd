extends BaseOutcome

var trigger_id: String
var vip: Vector2i

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.board.scripting.triggers[self.trigger_id].set_vip(self.vip[0], self.vip[1])

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.trigger_id = details['trigger_id']
    self.vip = details['vip']
