class_name UnitStateSnapshot
extends MapObjectStateSnapshot


var id: int
var side: String
var team: Variant
var hp: int
var max_hp: int
var move: int
var max_move: int
var attacks: int
var max_attacks: int
var attack: int
var armor: int
var ai_paused: bool
var level: int
var experience: int
var kills: int
var modifiers: Dictionary[String, Variant]
var scripting_tags: Dictionary[String, Variant]
var abilities: Array[AbilityStateSnapshot]
var disable_active_abilities: bool
var passenger: UnitStateSnapshot


func _init(
	new_id: int,
	new_template_key: String,
	new_rotation: int,
	new_side: String,
	new_team: Variant,
	stats: Dictionary[String, int],
	new_ai_paused: bool,
	new_modifiers: Dictionary[String, Variant],
	new_scripting_tags: Dictionary[String, Variant],
	new_abilities: Array[AbilityStateSnapshot],
	new_disable_active_abilities: bool,
	new_passenger: UnitStateSnapshot = null
) -> void:
	super._init(new_template_key, new_rotation)
	self.id = new_id
	self.side = new_side
	self.team = new_team
	self.hp = int(stats.get("hp", 0))
	self.max_hp = int(stats.get("max_hp", 0))
	self.move = int(stats.get("move", 0))
	self.max_move = int(stats.get("max_move", 0))
	self.attacks = int(stats.get("attacks", 0))
	self.max_attacks = int(stats.get("max_attacks", 0))
	self.attack = int(stats.get("attack", 0))
	self.armor = int(stats.get("armor", 0))
	self.ai_paused = new_ai_paused
	self.level = int(stats.get("level", 0))
	self.experience = int(stats.get("experience", 0))
	self.kills = int(stats.get("kills", 0))
	self.modifiers = new_modifiers.duplicate(true)
	self.scripting_tags = new_scripting_tags.duplicate(true)
	self.abilities = new_abilities.duplicate()
	self.disable_active_abilities = new_disable_active_abilities
	self.passenger = new_passenger
