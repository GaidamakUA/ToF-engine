extends BaseOutcome
class_name TerrainRemoveOutcome

var where: Vector2i
var explosion: bool = false
var type: String

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.change_tile_layer(
        self.where, StringName(self.type), "", 0, "",
        &"explosion" if self.explosion else &"menu_click"
    )

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.where = Vector2i(details['where'][0], details['where'][1])
    self.type = String(details['type'])
    if details.has('explosion'):
        self.explosion = bool(details['explosion'])
