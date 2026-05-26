class_name State

const PLAYER_HUMAN: String = "human"
const PLAYER_AI: String = "ai"


var current_player: int = 0
var turn: int = 1
var has_player_moved: bool = false

var players: Array[Dictionary] = []


func add_player(type: String, side: String, alive: bool = true, team: Variant = null, peer_id: Variant = null) -> void:
	var player_data: Dictionary[String, Variant] = {
		"type": type,
		"side": side,
		"team": team,
		"ap" : 0,
		"alive" : alive,
		"heroes" : {},
		"peer_id" : peer_id
	}
	self.players.append(player_data)


func switch_to_next_player() -> void:
	self.current_player += 1
	self.has_player_moved = false
	if self.current_player >= self.players.size():
		self.current_player = 0
		self.turn += 1

	if not self.is_current_player_alive():
		self.switch_to_next_player()

func get_current_player() -> Dictionary:
	return self.players[self.current_player]

func get_current_ap() -> int:
	return int(self.get_current_param("ap"))

func get_current_side() -> String:
	return String(self.get_current_param("side"))

func get_current_team() -> int:
	return self.get_player_team(String(self.get_current_param("side")))

func get_current_heroes() -> Dictionary[int, HeroUnit]:
	var heroes: Dictionary[int, HeroUnit]
	var raw_heroes: Dictionary = self.get_current_param("heroes")
	heroes.assign(raw_heroes)
	return heroes

func get_player_id_by_side(side: String) -> int:
	var index: int = 0

	while index < self.players.size():
		if self.players[index]['side'] == side:
			return index
		index += 1

	return -1

func get_player_side_by_id(id: int) -> String:
	return String(self.players[id]['side'])

func get_player_team_by_id(id: int) -> int:
	if id < 0:
		return id
	if self.players[id]['team'] != null:
		return int(self.players[id]['team'])

	return id

func set_player_team(side: String, team: int) -> void:
	self.players[self.get_player_id_by_side(side)]["team"] = team

func get_player_team(side: String) -> int:
	return self.get_player_team_by_id(self.get_player_id_by_side(side))

func get_current_param(param_name: String) -> Variant:
	var player_data: Dictionary = self.get_current_player()
	return player_data[param_name]

func set_player_ap(id: int, value: int) -> void:
	self.players[id]["ap"] = value

func add_player_ap(id: int, value: int) -> void:
	self.players[id]["ap"] = int(self.players[id]["ap"]) + value

	if int(self.players[id]["ap"]) < 0:
		self.players[id]["ap"] = 0

	if int(self.players[id]["ap"]) > 999:
		self.players[id]["ap"] = 999

func use_player_ap(id: int, value: int) -> void:
	self.has_player_moved = true
	self.players[id]["ap"] = int(self.players[id]["ap"]) - value

	if int(self.players[id]["ap"]) < 0:
		self.players[id]["ap"] = 0

func get_player_ap(id: int) -> int:
	return int(self.players[id]["ap"])

func use_current_player_ap(value: int) -> void:
	self.use_player_ap(self.current_player, value)

func add_current_player_ap(value: int) -> void:
	self.add_player_ap(self.current_player, value)

func can_current_player_afford(amount: int) -> bool:
	return self.get_current_ap() >= amount

func is_current_player_ai() -> bool:
	return self.get_current_param("type") == self.PLAYER_AI

func is_player_human(side: String) -> bool:
	var player_id: int = self.get_player_id_by_side(side)
	if player_id < 0:
		return false
	return self.players[player_id]["type"] == self.PLAYER_HUMAN

func is_current_player_alive() -> bool:
	return bool(self.get_current_param("alive"))

func is_current_player_active_peer(peer_id: int) -> bool:
	return self.get_current_param("peer_id") == peer_id


func is_non_observer_peer(peer_id: int) -> bool:
	for player_data: Dictionary in self.players:
		if player_data["peer_id"] == peer_id:
			return true
	return false


func clear_peer_id(peer_id: int) -> void:
	var index: int = 0

	while index < self.players.size():
		if self.players[index]['peer_id'] == peer_id:
			self.players[index]['peer_id'] = null
			return
		index += 1


func has_free_peer() -> bool:
	for player_data: Dictionary in self.players:
		if player_data["peer_id"] == null:
			return true
	return false


func assign_free_peer(peer_id: int) -> void:
	var index: int = 0

	while index < self.players.size():
		if self.players[index]['peer_id'] == null:
			self.players[index]['peer_id'] = peer_id
			return
		index += 1

func eliminate_player(side: String) -> void:
	var index: int = 0

	while index < self.players.size():
		if self.players[index]['side'] == side:
			self.players[index]['alive'] = false
			return
		index += 1

func revive_player(side: String) -> void:
	self.revive_player_by_id(self.get_player_id_by_side(side))

func revive_player_by_id(id: int) -> void:
	self.players[id]['alive'] = true

func count_alive_players() -> int:
	var amount: int = 0

	for player: Dictionary in self.players:
		if bool(player["alive"]):
			amount += 1

	return amount

func count_alive_teams() -> int:
	var amount: Dictionary[int, bool] = {}
	var team: int

	for player: Dictionary in self.players:
		if bool(player["alive"]):
			team = self.get_player_team(String(player["side"]))
			amount[team] = true

	return amount.size()

func has_current_player_a_hero() -> bool:
	return self.get_current_heroes().size() > 0

func has_side_a_hero(side: String) -> bool:
	return self.players[self.get_player_id_by_side(side)]['heroes'].size() > 0

func add_hero_for_player(id: int, hero: HeroUnit) -> void:
	var heroes: Dictionary = self.players[id]["heroes"]
	heroes[hero.get_instance_id()] = hero

func get_heroes_for_player(id: int) -> Array[HeroUnit]:
	var heroes: Array[HeroUnit] = []
	var player_heroes: Dictionary = self.players[id]["heroes"]
	heroes.assign(player_heroes.values())
	return heroes

func add_hero_for_side(side: String, hero: HeroUnit) -> void:
	self.add_hero_for_player(self.get_player_id_by_side(side), hero)

func get_heroes_for_side(side: String) -> Array[HeroUnit]:
	var side_id: int = self.get_player_id_by_side(side)
	if side_id < 0:
		return []
	return self.get_heroes_for_player(side_id)

func auto_set_hero(hero: HeroUnit) -> void:
	self.add_hero_for_side(hero.side, hero)

func add_current_hero(hero: HeroUnit) -> void:
	self.add_hero_for_player(self.current_player, hero)

func clear_hero_for_player(id: int, hero: HeroUnit) -> void:
	if id < 0 or hero == null:
		return

	var heroes: Dictionary = self.players[id]["heroes"]
	heroes.erase(hero.get_instance_id())

func clear_current_hero(hero: HeroUnit) -> void:
	self.clear_hero_for_player(self.current_player, hero)

func clear_hero_for_side(side: String, hero: HeroUnit) -> void:
	self.clear_hero_for_player(self.get_player_id_by_side(side), hero)

func register_heroes(model: MapModel) -> void:
	var index: int = 0
	var heroes: Array[HeroUnit] = []

	while index < self.players.size():
		self.players[index]['heroes'] = {}
		heroes.assign(model.get_player_heroes(String(self.players[index]['side'])))
		for hero: HeroUnit in heroes:
			self.add_hero_for_player(index, hero)
		index += 1

func get_players_state_data() -> Array[Dictionary]:
	var state_data: Array[Dictionary] = []
	for player: Dictionary in self.players:
		var player_data: Dictionary[String, Variant] = {
			"type": player["type"],
			"side": player["side"],
			"team": player["team"],
			"ap" : player["ap"],
			"alive" : player["alive"],
			"peer_id" : player["peer_id"]
		}
		state_data.append(player_data)
	return state_data

func are_all_peers_present() -> bool:
	for player: Dictionary in self.players:
		if player["type"] == "human" and player["peer_id"] == null:
			return false
	return true
