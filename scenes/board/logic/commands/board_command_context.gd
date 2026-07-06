class_name BoardCommandContext
extends RefCounted


var state: State
var map_model: MapModel
var events: Events
var scripting: Scripting
var abilities: Abilities
var collateral: Collateral


func _init(
	state_object: State,
	map_model_object: MapModel,
	events_object: Events,
	scripting_object: Scripting,
	abilities_object: Abilities = null,
	collateral_object: Collateral = null
) -> void:
	self.state = state_object
	self.map_model = map_model_object
	self.events = events_object
	self.scripting = scripting_object
	self.abilities = abilities_object
	self.collateral = collateral_object
