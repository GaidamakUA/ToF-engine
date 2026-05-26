class_name Brains

var brains: Dictionary[String, AbstractBrain] = {
	"hq" : HqBrain.new(),
	"barracks" : BarracksBrain.new(),
	"factory" : FactoryBrain.new(),
	"airfield" : AirfieldBrain.new(),

	"infantry" : InfantryBrain.new(),
	"tank" : TankBrain.new(),
	"heli" : HeliBrain.new(),
	"mobile_infantry" : MobileInfantryBrain.new(),
	"rocket_artillery" : RocketArtilleryBrain.new(),
	"scout" : ScoutBrain.new(),

	"hero_admiral" : AdmiralBrain.new(),
	"hero_captain" : CaptainBrain.new(),
	"hero_commando" : CommandoBrain.new(),
	"hero_general" : GeneralBrain.new(),
	"hero_gentleman" : GentlemanBrain.new(),
	"hero_noble" : NobleBrain.new(),
	"hero_prince" : PrinceBrain.new(),
	"hero_warlord" : WarlordBrain.new(),

	"npc" : NpcBrain.new(),
	"hero" : HeroBrain.new()
}

var assigned_brains: Dictionary[String, AbstractBrain] = {
	"modern_airfield" : self.brains['airfield'],
	"modern_barracks" : self.brains['barracks'],
	"modern_factory" : self.brains['factory'],
	"modern_hq" : self.brains['hq'],
	"steampunk_airfield" : self.brains['airfield'],
	"steampunk_barracks" : self.brains['barracks'],
	"steampunk_factory" : self.brains['factory'],
	"steampunk_hq" : self.brains['hq'],
	"futuristic_airfield" : self.brains['airfield'],
	"futuristic_barracks" : self.brains['barracks'],
	"futuristic_factory" : self.brains['factory'],
	"futuristic_hq" : self.brains['hq'],
	"feudal_airfield" : self.brains['airfield'],
	"feudal_barracks" : self.brains['barracks'],
	"feudal_factory" : self.brains['factory'],
	"feudal_hq" : self.brains['hq'],
}

func get_brain_for_template(template_name: String) -> AbstractBrain:
	if self.assigned_brains.has(template_name):
		return self.assigned_brains[template_name]

	return null

func get_brain_for_unit(unit: BaseUnit) -> AbstractBrain:
	if unit.unit_class == "hero":
		if self.brains.has(unit.template_name):
			return self.brains[unit.template_name]

	if self.brains.has(unit.unit_class):
		return self.brains[unit.unit_class]

	return null
