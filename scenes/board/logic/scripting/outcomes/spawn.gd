extends BaseOutcome
class_name SpawnOutcome

var where: Vector2i
var template_name: String
var side: String
var rotation: int = 0
var hp: int = 0
var sound: bool = true
var promote: bool = false

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.scripted_spawn_unit(self.where, self.template_name, self.side, self.rotation, self.hp, self.promote)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.where = Vector2i(details['where'][0], details['where'][1])
    self.template_name = String(details['template'])
    self.side = String(details['side'])
    if details.has('rotation'):
        self.rotation = int(details['rotation'])
    if details.has('hp'):
        self.hp = int(details['hp'])
    if details.has('sound'):
        self.sound = bool(details['sound'])
    if details.has('promote'):
        self.promote = bool(details['promote'])
