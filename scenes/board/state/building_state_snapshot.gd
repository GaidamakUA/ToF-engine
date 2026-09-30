class_name BuildingStateSnapshot
extends MapObjectStateSnapshot


var id: int
var side: String
var abilities: Array[AbilityStateSnapshot]


func _init(
	new_id: int,
	new_template_key: String,
	new_rotation: int,
	new_side: String,
	new_abilities: Array[AbilityStateSnapshot]
) -> void:
	super._init(new_template_key, new_rotation)
	self.id = new_id
	self.side = new_side
	self.abilities = new_abilities.duplicate()
