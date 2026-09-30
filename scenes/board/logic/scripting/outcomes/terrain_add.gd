extends BaseOutcome
class_name TerrainAddOutcome

var where: Vector2i
var template_name: String
var type: String
var side: String
var smoke: bool = false
var rotation: int = 0

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.change_tile_layer(
        self.where, StringName(self.type), self.template_name, self.rotation, self.side,
        &"smoke" if self.smoke else &"menu_click"
    )

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.where = Vector2i(details['where'][0], details['where'][1])
    self.template_name = String(details['template'])
    self.type = String(details['type'])
    if details.has('rotation'):
        self.rotation = int(details['rotation'])
    if details.has('side'):
        self.side = String(details['side'])
    if details.has('smoke'):
        self.smoke = bool(details['smoke'])
