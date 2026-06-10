extends BaseOutcome
class_name SideOutcome

var who: Vector2i
var side: String

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var tile: MapTile = self.board.map.model.get_tile(self.who)

    if tile.unit.is_present():
        var unit: BaseUnit = tile.unit.get_map_object() as BaseUnit
        assert(unit != null)
        if unit.is_hero():
            var hero: HeroUnit = unit as HeroUnit
            assert(hero != null)
            self.board.state.clear_hero_for_side(unit.side, hero)
            self.board.state.add_hero_for_side(self.side, hero)

        self.board.map.builder.set_unit_side(self.who, self.side)
        unit.sfx_effect("spawn")

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.side = String(details['side'])
