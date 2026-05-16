extends BaseOutcome

var where: Vector2i
var explosion: bool = false
var type: String

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var tile: MapTile = self.board.map.model.get_tile(self.where)

    if self.type == "decoration":
        tile.decoration.clear()
    elif self.type == "frame":
        tile.frame.clear()
    elif self.type == "terrain":
        tile.terrain.clear()
    elif self.type == "ground":
        tile.ground.clear()
    elif self.type == "building":
        tile.building.clear()

    if self.explosion:
        self.board.explode_a_tile(tile)
        self.board.audio.play("explosion")
    else:
        self.board.audio.play("menu_click")
    tile.is_state_modified = true

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.where = Vector2i(details['where'][0], details['where'][1])
    self.type = String(details['type'])
    if details.has('explosion'):
        self.explosion = bool(details['explosion'])
