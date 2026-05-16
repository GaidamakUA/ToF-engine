extends BaseOutcome
class_name AttackOutcome

var who: Vector2i
var whom: Vector2i
var damage: int = 0

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var attacker_tile: MapTile = self.board.map.model.get_tile(self.who)
    var defender_tile: MapTile = self.board.map.model.get_tile(self.whom)
    var attacker: BaseUnit = attacker_tile.unit.tile
    var defender: BaseUnit = defender_tile.unit.tile

    attacker.rotate_unit_to_direction(attacker_tile.get_direction_to_neighbour(defender_tile))

    if self.damage > 0:
        defender.receive_direct_damage(self.damage)

    attacker.sfx_effect("attack")
    await self.board.get_tree().create_timer(self.board.RETALIATION_DELAY).timeout
    defender.show_explosion()
    defender.sfx_effect("damage")

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.whom = Vector2i(details['whom'][0], details['whom'][1])
    if details.has('damage'):
        self.damage = int(details['damage'])
