class_name State
extends RefCounted


const PLAYER_HUMAN: String = "human"
const PLAYER_AI: String = "ai"

var current_player: int = 0
var turn: int = 1
var has_player_moved: bool = false
var players: Array[PlayerState] = []


func add_player(type: String, side: String, alive: bool = true, team: Variant = null, peer_id: Variant = null) -> void:
    self.players.append(PlayerState.new(type, side, alive, team, peer_id))


func switch_to_next_player() -> void:
    self.current_player += 1
    self.has_player_moved = false
    if self.current_player >= self.players.size():
        self.current_player = 0
        self.turn += 1
    if not self.is_current_player_alive():
        self.switch_to_next_player()


func get_current_player() -> PlayerState:
    return self.players[self.current_player]


func get_current_ap() -> int:
    return self.get_current_player().ap


func get_current_side() -> String:
    return self.get_current_player().side


func get_current_team() -> int:
    return self.get_player_team(self.get_current_side())


func get_current_heroes() -> Dictionary[int, HeroUnit]:
    return self.get_current_player().heroes


func get_player_id_by_side(side: String) -> int:
    for index: int in range(self.players.size()):
        if self.players[index].side == side:
            return index
    return -1


func get_player_side_by_id(id: int) -> String:
    return self.players[id].side


func get_player_team_by_id(id: int) -> int:
    if id < 0:
        return id
    if self.players[id].team != null:
        return int(self.players[id].team)
    return id


func set_player_team(side: String, team: int) -> void:
    self.players[self.get_player_id_by_side(side)].team = team


func get_player_team(side: String) -> int:
    return self.get_player_team_by_id(self.get_player_id_by_side(side))


func set_player_ap(id: int, value: int) -> void:
    self.players[id].ap = value


func add_player_ap(id: int, value: int) -> void:
    self.players[id].ap = clampi(self.players[id].ap + value, 0, 999)


func use_player_ap(id: int, value: int) -> void:
    self.has_player_moved = true
    self.players[id].ap = maxi(0, self.players[id].ap - value)


func get_player_ap(id: int) -> int:
    return self.players[id].ap


func use_current_player_ap(value: int) -> void:
    self.use_player_ap(self.current_player, value)


func add_current_player_ap(value: int) -> void:
    self.add_player_ap(self.current_player, value)


func can_current_player_afford(amount: int) -> bool:
    return self.get_current_ap() >= amount


func is_current_player_ai() -> bool:
    return self.get_current_player().type == self.PLAYER_AI


func is_player_human(side: String) -> bool:
    var player_id: int = self.get_player_id_by_side(side)
    return player_id >= 0 and self.players[player_id].type == self.PLAYER_HUMAN


func is_current_player_alive() -> bool:
    return self.get_current_player().alive


func is_current_player_active_peer(peer_id: int) -> bool:
    return self.get_current_player().peer_id == peer_id


func is_non_observer_peer(peer_id: int) -> bool:
    for player: PlayerState in self.players:
        if player.peer_id == peer_id:
            return true
    return false


func clear_peer_id(peer_id: int) -> void:
    for player: PlayerState in self.players:
        if player.peer_id == peer_id:
            player.peer_id = null
            return


func has_free_peer() -> bool:
    for player: PlayerState in self.players:
        if player.peer_id == null:
            return true
    return false


func assign_free_peer(peer_id: int) -> void:
    for player: PlayerState in self.players:
        if player.peer_id == null:
            player.peer_id = peer_id
            return


func eliminate_player(side: String) -> void:
    var player_id: int = self.get_player_id_by_side(side)
    if player_id >= 0:
        self.players[player_id].alive = false


func revive_player(side: String) -> void:
    self.revive_player_by_id(self.get_player_id_by_side(side))


func revive_player_by_id(id: int) -> void:
    self.players[id].alive = true


func count_alive_players() -> int:
    var amount: int = 0
    for player: PlayerState in self.players:
        if player.alive:
            amount += 1
    return amount


func count_alive_teams() -> int:
    var teams: Dictionary[int, bool] = {}
    for player: PlayerState in self.players:
        if player.alive:
            teams[self.get_player_team(player.side)] = true
    return teams.size()


func has_current_player_a_hero() -> bool:
    return not self.get_current_heroes().is_empty()


func has_side_a_hero(side: String) -> bool:
    return not self.players[self.get_player_id_by_side(side)].heroes.is_empty()


func add_hero_for_player(id: int, hero: HeroUnit) -> void:
    self.players[id].heroes[hero.get_instance_id()] = hero


func get_heroes_for_player(id: int) -> Array[HeroUnit]:
    var heroes: Array[HeroUnit] = []
    heroes.assign(self.players[id].heroes.values())
    return heroes


func add_hero_for_side(side: String, hero: HeroUnit) -> void:
    self.add_hero_for_player(self.get_player_id_by_side(side), hero)


func get_heroes_for_side(side: String) -> Array[HeroUnit]:
    var side_id: int = self.get_player_id_by_side(side)
    return [] if side_id < 0 else self.get_heroes_for_player(side_id)


func auto_set_hero(hero: HeroUnit) -> void:
    self.add_hero_for_side(hero.side, hero)


func add_current_hero(hero: HeroUnit) -> void:
    self.add_hero_for_player(self.current_player, hero)


func clear_hero_for_player(id: int, hero: HeroUnit) -> void:
    if id >= 0 and hero != null:
        self.players[id].heroes.erase(hero.get_instance_id())


func clear_current_hero(hero: HeroUnit) -> void:
    self.clear_hero_for_player(self.current_player, hero)


func clear_hero_for_side(side: String, hero: HeroUnit) -> void:
    self.clear_hero_for_player(self.get_player_id_by_side(side), hero)


func register_heroes(model: MapModel) -> void:
    for index: int in range(self.players.size()):
        self.players[index].heroes.clear()
        for hero: HeroUnit in model.get_player_heroes(self.players[index].side):
            self.add_hero_for_player(index, hero)


func are_all_peers_present() -> bool:
    for player: PlayerState in self.players:
        if player.type == self.PLAYER_HUMAN and player.peer_id == null:
            return false
    return true
