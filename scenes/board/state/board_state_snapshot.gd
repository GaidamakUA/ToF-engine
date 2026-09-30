class_name BoardStateSnapshot
extends RefCounted


var match: MatchStateSnapshot
var map: MapStateSnapshot
var scenario: ScenarioStateSnapshot


func _init(new_match: MatchStateSnapshot, new_map: MapStateSnapshot, new_scenario: ScenarioStateSnapshot) -> void:
	self.match = new_match
	self.map = new_map
	self.scenario = new_scenario
