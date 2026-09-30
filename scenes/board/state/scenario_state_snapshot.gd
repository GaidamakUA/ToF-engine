class_name ScenarioStateSnapshot
extends RefCounted


var objectives: Array[String]
var triggers: Dictionary[String, Variant]
var winner: String


func _init(new_objectives: Array[String] = [], new_triggers: Dictionary[String, Variant] = {}, new_winner: String = "") -> void:
	self.objectives = new_objectives.duplicate()
	self.triggers = new_triggers.duplicate(true)
	self.winner = new_winner
