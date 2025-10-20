class_name BaseOutcome

var board: Board
var delay := 0

func execute(metadata: Dictionary[String, Variant]={}) -> void:
    self._execute(metadata)

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    return

func ingest_details(details: Dictionary[String, Variant]={}) -> void:
    self._ingest_details(details)

func _ingest_details(_details: Dictionary[String, Variant]) -> void:
    return
