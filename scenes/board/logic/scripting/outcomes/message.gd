extends BaseOutcome
class_name MessageOutcome

var text: String
var portrait: Variant = null
var name: String
var side: String = "left"
var colour: Variant = null
var font_size: int = 16
var sound: Variant = null

func _execute(_metadata: Dictionary[String, Variant]) -> void:
	var portrait_tile: MapObject = self.board.map.templates.get_template(self.portrait)
	var actor: Dictionary[String, Variant] = {
		'portrait' : self.portrait,
		'portrait_tile' : portrait_tile,
		'name' : self.name,
		'side' : self.side
	}

	portrait_tile.tile_view_height_cam_modifier = -0.2

	if self.colour != null:
		var material_type: String = self.board.map.templates.MATERIAL_NORMAL
		var portrait_unit: BaseUnit = portrait_tile as BaseUnit
		if portrait_unit != null and portrait_unit.uses_metallic_material:
			material_type = self.board.map.templates.MATERIAL_METALLIC
		var portrait_building: BaseBuilding = portrait_tile as BaseBuilding
		if portrait_building != null and portrait_building.uses_metallic_material:
			material_type = self.board.map.templates.MATERIAL_METALLIC

		portrait_tile.set_side_materials(self.board.map.templates.get_side_material(self.colour, material_type), self.board.map.templates.get_side_material(self.colour, material_type))

	self.board.ui.show_story_dialog(text, actor, self.font_size)

	if self.sound != null:
		self.board.audio.play(self.sound)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
	self.name = String(details['name'])
	if details.has("portrait"):
		self.portrait = details['portrait']
	if details.has("side"):
		self.side = String(details['side'])
	if details.has("colour"):
		self.colour = details['colour']
	if details.has("font_size"):
		self.font_size = int(details['font_size'])
	if details.has("sound"):
		self.sound = details['sound']
	self.text = String(details['text'])
