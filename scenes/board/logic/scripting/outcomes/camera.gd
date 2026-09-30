extends BaseOutcome
class_name CameraOutcome

var where: Vector2i
var zoom: Variant = null

func _init() -> void:
    self.delay = 1

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.request_presentation(FocusPresentationEvent.new(
        self.where, float(self.zoom) if self.zoom != null else -1.0
    ))

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.where = Vector2i(details['where'][0], details['where'][1])
    if details.has('zoom'):
        self.zoom = details['zoom']
