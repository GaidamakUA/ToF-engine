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
	var tile: MapTile = self.board.map.model.get_tile(self.where)
	tile.unit.clear()

	var new_unit: BaseUnit = self.board.map.builder.force_place_unit(self.where, self.template_name, self.rotation, self.side)
	new_unit.team = self.board.state.get_player_team(self.side)
	new_unit.replenish_moves()

	if self.hp > 0:
		new_unit.set_hp(self.hp)

	if self.sound:
		new_unit.sfx_effect("spawn")

	if self.promote:
		new_unit.level_up()

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
