extends BaseOutcome
class_name EndGameOutcome

var winner: Variant = null

func _execute(metadata: Dictionary[String, Variant]) -> void:
    if self.winner == null:
        self.winner = metadata['new_side']

    self.model.end_game(String(self.winner))

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has('winner'):
        self.winner = details['winner']
