extends BaseOutcome
class_name ClaimOutcome

var what: Vector2i
var side: String

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var tile: MapTile = self.board.map.model.get_tile(self.what)

    self.board.map.builder.set_building_side(self.what, self.side, self.board.state.get_player_team(self.side))
    self.board.smoke_a_tile(tile)
    tile.building.get_map_object().sfx_effect("capture")

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.what = Vector2i(details['what'][0], details['what'][1])
    self.side = String(details['side'])
