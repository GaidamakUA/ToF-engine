class_name BoardModel
extends RefCounted


signal updated(snapshot: BoardStateSnapshot, domain_events: Array[BoardDomainEvent])
signal command_requested(command: BoardCommand)
signal command_completed


var _state: State = State.new()
var map_model: MapModel
var abilities: Abilities = Abilities.new(self._state)
var events: Events = Events.new()
var scripting: Scripting
var templates: MapTemplates = MapTemplates.new()
var reserved_ap: int = 0
var random_collateral_enabled: bool = true

var turn_limit: int = 0
var time_limit: int = 0
var objectives: Array[String] = []
var winner: String = ""

var _next_entity_id: int = 1
var _pending_events: Array[BoardDomainEvent] = []
var _last_unit_move: Dictionary[String, Variant] = {}
var _command_in_progress: bool = false
var _applying_command: bool = false
var _pending_command: BoardCommand
var _story_queue: Array[Dictionary] = []
var _story_running: bool = false

const COLLATERAL_CHANCE: float = 0.5
const GROUND_DAMAGE_TEMPLATES: Array[String] = [
    "deco_ground_dmg1", "deco_ground_dmg2", "deco_ground_dmg5", "deco_ground_dmg6"
]


func _init(new_map_model: MapModel = null) -> void:
    self.scripting = Scripting.new(self)
    self.map_model = new_map_model
    if self.map_model != null:
        self._assign_entity_ids()


func set_map_model(new_map_model: MapModel) -> void:
    self.map_model = new_map_model
    self._assign_entity_ids()


func load_scripts(script_definitions: Variant) -> void:
    self._command_in_progress = true
    self.scripting.ingest_scripts(script_definitions)
    self._command_in_progress = false


func publish_state() -> void:
    self._commit_update()


func restore_match(snapshot: MatchStateSnapshot) -> void:
    self._state.players.clear()
    for player: PlayerStateSnapshot in snapshot.players:
        self._state.players.append(PlayerState.new(
            player.type, player.side, player.alive, player.team, player.peer_id, player.ap
        ))
    self._state.current_player = snapshot.current_player
    self._state.turn = snapshot.turn
    self._state.has_player_moved = snapshot.has_player_moved
    self.turn_limit = snapshot.turn_limit
    self.time_limit = snapshot.time_limit


func clear_undo() -> void:
    self._last_unit_move.clear()


func submit_command(
    animation: BoardAnimation.Kind,
    apply: Callable,
    source_id: int = 0,
    origin: Vector2i = Vector2i(-1, -1),
    target: Vector2i = Vector2i(-1, -1),
    path: Array[Vector2i] = [],
    directions: Array[String] = []
) -> bool:
    if self._applying_command or self._command_in_progress:
        return bool(apply.call())
    if self._pending_command != null:
        return false
    var command := BoardCommand.new(
        animation, apply, source_id, origin, target, path, directions
    )
    self._pending_command = command
    if not self.command_requested.get_connections().is_empty():
        self.command_requested.emit(command)
        return true
    var applied: bool = self.commit_pending_command()
    self.complete_pending_command()
    return applied


func _should_submit_command() -> bool:
    return not self._applying_command and not self._command_in_progress


func commit_pending_command() -> bool:
    if self._pending_command == null:
        return false
    self._applying_command = true
    var result: Variant = self._pending_command.apply.call()
    self._applying_command = false
    return bool(result) if result is bool else true


func complete_pending_command() -> void:
    if self._pending_command == null:
        return
    self._pending_command = null
    self.command_completed.emit()
    self._start_next_story()


func wait_for_command() -> void:
    while self._pending_command != null:
        await self.command_completed


func queue_story(story: StoryOutcome, metadata: Dictionary[String, Variant]) -> void:
    self._story_queue.append({"story": story, "metadata": metadata.duplicate(true)})
    self._start_next_story()


func _start_next_story() -> void:
    if self._story_running or self._pending_command != null or self._command_in_progress or self._story_queue.is_empty():
        return
    self._story_running = true
    var entry: Dictionary = self._story_queue.pop_front()
    await (entry["story"] as StoryOutcome).run(entry["metadata"] as Dictionary[String, Variant])
    self._story_running = false
    self._start_next_story()


func set_objective(slot: int, text: String, clear_all: bool = false) -> void:
    if self._should_submit_command():
        self.submit_command(
            BoardAnimation.Kind.NONE, self.set_objective.bind(slot, text, clear_all)
        )
        return
    if clear_all:
        self.objectives.clear()
    elif text.is_empty():
        if slot >= 0 and slot < self.objectives.size():
            self.objectives[slot] = ""
    else:
        while self.objectives.size() <= slot:
            self.objectives.append("")
        self.objectives[slot] = text
    self.request_presentation(ObjectivesPresentationEvent.new())


func request_presentation(event: ScriptPresentationEvent) -> void:
    if self._should_submit_command():
        self.submit_command(
            BoardAnimation.Kind.NONE,
            self.request_presentation.bind(event)
        )
        return
    self._pending_events.append(event)
    self._commit_if_standalone()


func set_player_ap(side: String, amount: int, mode: StringName = &"add") -> bool:
    var player_id: int = self._state.get_player_id_by_side(side)
    if player_id < 0:
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.NONE, self.set_player_ap.bind(side, amount, mode)
        )
    var old_value: int = self._state.get_player_ap(player_id)
    if mode == &"set":
        self._state.set_player_ap(player_id, amount)
    elif mode == &"cap":
        self._state.set_player_ap(player_id, mini(old_value, amount))
    else:
        self._state.add_player_ap(player_id, amount)
    self._commit_if_standalone()
    return true


func scripted_attack(attacker_position: Vector2i, defender_position: Vector2i, damage: int) -> bool:
    var attacker_tile: MapTile = self._get_tile_at(attacker_position)
    var defender_tile: MapTile = self._get_tile_at(defender_position)
    if attacker_tile == null or defender_tile == null or not attacker_tile.unit.is_present() or not defender_tile.unit.is_present():
        return false
    var attacker: BaseUnit = attacker_tile.unit.tile
    var defender: BaseUnit = defender_tile.unit.tile
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.ATTACK,
            self.scripted_attack.bind(attacker_position, defender_position, damage),
            attacker.model_id, attacker_position, defender_position
        )
    var was_nested: bool = self._command_in_progress
    self._command_in_progress = true
    if damage > 0 and not defender.ai_paused:
        defender.state.receive_direct_damage(damage)
    self._pending_events.append(AttackResolvedEvent.new(
        attacker_position, defender_position, false, attacker.model_id, defender.model_id
    ))
    if not defender.is_alive():
        self._destroy_unit(defender_tile, attacker.model_id, true)
    self._command_in_progress = was_nested
    self._commit_if_standalone()
    return true


func set_building_side(position: Vector2i, side: String) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.building.is_present():
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.CAPTURE, self.set_building_side.bind(position, side),
            0, position, position
        )
    var building: BaseBuilding = tile.building.tile
    var old_side: String = building.side
    building.side = side
    building.team = self.get_player_team(side)
    self._pending_events.append(BuildingCapturedDomainEvent.new(position, side, old_side))
    self._commit_if_standalone()
    return true


func set_unit_side(position: Vector2i, side: String) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.unit.is_present():
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.SMOKE, self.set_unit_side.bind(position, side),
            tile.unit.tile.model_id, position, position
        )
    var unit: BaseUnit = tile.unit.tile
    if unit is HeroUnit:
        self._state.clear_hero_for_side(unit.side, unit as HeroUnit)
        self._state.add_hero_for_side(side, unit as HeroUnit)
    unit.side = side
    unit.team = self.get_player_team(side)
    self.request_presentation(TileEffectPresentationEvent.new(
        TileEffectPresentationEvent.Kind.SMOKE, position
    ))
    return true


func set_unit_ai_paused(position: Vector2i, paused: bool) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.unit.is_present():
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.NONE, self.set_unit_ai_paused.bind(position, paused)
        )
    var unit: BaseUnit = tile.unit.tile
    unit.state.ai_paused = paused
    if paused:
        unit.state.remove_moves()
    else:
        unit.state.replenish_moves(unit.get_stats_with_modifiers())
    self._commit_if_standalone()
    return true


func set_unit_tether(position: Vector2i, length: int) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.unit.is_present():
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.NONE, self.set_unit_tether.bind(position, length)
        )
    tile.unit.tile.tether_point = position
    tile.unit.tile.tether_length = length
    self._commit_if_standalone()
    return true


func level_up_unit(position: Vector2i) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.unit.is_present():
        return false
    if tile.unit.tile.is_max_level() or not tile.unit.tile.allow_level_up:
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.LEVEL_UP, self.level_up_unit.bind(position),
            tile.unit.tile.model_id, position, position
        )
    var leveled_up: bool = self._level_up_unit(tile.unit.tile, position)
    self._commit_if_standalone()
    return leveled_up


func set_building_ability_disabled(position: Vector2i, ability_index: int, disabled: bool) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.building.is_present():
        return false
    var ability_found: bool = false
    for ability: Ability in tile.building.tile.abilities:
        if ability.index == ability_index:
            ability_found = true
            break
    if not ability_found:
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.NONE,
            self.set_building_ability_disabled.bind(position, ability_index, disabled)
        )
    for ability: Ability in tile.building.tile.abilities:
        if ability.index == ability_index:
            tile.building.tile.get_ability_state(ability).disabled = disabled
            self._commit_if_standalone()
            return true
    return false


func set_hero_abilities_disabled(side: String, disabled: bool) -> void:
    if self._should_submit_command():
        self.submit_command(
            BoardAnimation.Kind.NONE, self.set_hero_abilities_disabled.bind(side, disabled)
        )
        return
    for hero: HeroUnit in self._state.get_heroes_for_side(side):
        for ability: Ability in hero.active_abilities:
            hero.get_ability_state(ability).disabled = disabled
    self._commit_if_standalone()


func eliminate_player(side: String, winning_side: String = "") -> bool:
    if self._state.get_player_id_by_side(side) < 0:
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.NONE, self.eliminate_player.bind(side, winning_side)
        )
    self._state.eliminate_player(side)
    if not winning_side.is_empty() and (
        self._state.count_alive_players() == 1 or self._state.count_alive_teams() == 1
    ):
        self.winner = winning_side
        self.request_presentation(EndGamePresentationEvent.new(winning_side))
    else:
        self._commit_if_standalone()
    return true


func end_game(winning_side: String) -> void:
    if self._should_submit_command():
        self.submit_command(BoardAnimation.Kind.NONE, self.end_game.bind(winning_side))
        return
    self.winner = winning_side
    self.request_presentation(EndGamePresentationEvent.new(winning_side))


func revive_player(side: String) -> bool:
    if self._state.get_player_id_by_side(side) < 0:
        return false
    if self._should_submit_command():
        return self.submit_command(BoardAnimation.Kind.NONE, self.revive_player.bind(side))
    self._state.revive_player(side)
    self._commit_if_standalone()
    return true


func register_hero_at(position: Vector2i) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.unit.is_present() or not (tile.unit.tile is HeroUnit):
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.NONE, self.register_hero_at.bind(position)
        )
    self._state.auto_set_hero(tile.unit.tile as HeroUnit)
    self._commit_if_standalone()
    return true


func scripted_spawn_unit(position: Vector2i, template_key: String, side: String, rotation: int, hp: int, promote: bool) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not (self.templates.get_template_source(template_key) is UnitResource):
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.SPAWN,
            self.scripted_spawn_unit.bind(position, template_key, side, rotation, hp, promote),
            0, position, position
        )
    var was_nested: bool = self._command_in_progress
    self._command_in_progress = true
    if tile.unit.is_present():
        self._destroy_unit(tile, 0, false)
    var unit: BaseUnit = self._spawn_unit(position, template_key, side, rotation)
    if unit == null:
        self._command_in_progress = was_nested
        return false
    unit.state.replenish_moves(unit.get_stats_with_modifiers())
    if hp > 0:
        unit.state.set_hp(hp)
    if promote:
        self._level_up_unit(unit, position)
    self._command_in_progress = was_nested
    self._commit_if_standalone()
    return true


func set_trigger_enabled(name: String, group: String, suspended: bool, turns: int = -1) -> void:
    if self._should_submit_command():
        self.submit_command(
            BoardAnimation.Kind.NONE,
            self.set_trigger_enabled.bind(name, group, suspended, turns)
        )
        return
    if not group.is_empty():
        self.scripting.suspend_group(group, suspended)
    elif not name.is_empty():
        self.scripting.suspend_trigger(name, suspended)
        if turns >= 0 and self.scripting.triggers.get(name) is TurnTrigger:
            (self.scripting.triggers[name] as TurnTrigger).turn_no = self._state.turn + turns
    self._commit_if_standalone()


func set_trigger_group(name: String, group: String, add: bool) -> void:
    if self._should_submit_command():
        self.submit_command(
            BoardAnimation.Kind.NONE, self.set_trigger_group.bind(name, group, add)
        )
        return
    if add:
        self.scripting.add_to_group(group, name)
    else:
        self.scripting.remove_from_group(group, name)
    self._commit_if_standalone()


func change_tile_layer(position: Vector2i, layer: StringName, template_key: String, rotation: int = 0, side: String = "", effect: StringName = &"") -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not [&"ground", &"frame", &"decoration", &"terrain", &"damage", &"building"].has(layer):
        return false
    if not template_key.is_empty() and self.templates.get_template_source(template_key) == null:
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.TILE_CHANGE,
            self.change_tile_layer.bind(position, layer, template_key, rotation, side, effect),
            0, position, position
        )
    if template_key.is_empty():
        self._clear_tile_layer(tile, layer)
    else:
        var object: MapObject = self.templates.get_template(template_key)
        if object == null:
            return false
        object.current_rotation = rotation
        object.rotation_degrees.y = rotation
        match layer:
            &"ground": tile.ground.set_tile(object as BaseTile)
            &"frame": tile.frame.set_tile(object as BaseTile)
            &"decoration": tile.decoration.set_tile(object as BaseTile)
            &"terrain": tile.terrain.set_tile(object as BaseTile)
            &"damage": tile.damage.set_tile(object as BaseTile)
            &"building":
                var building := object as BaseBuilding
                if building == null:
                    return false
                building.side = side
                building.team = self.get_player_team(side)
                tile.building.set_tile(building)
                self._assign_entity_ids()
            _:
                return false
    tile.is_state_modified = true
    self._pending_events.append(TileLayerChangedEvent.new(position, layer, rotation, effect))
    self._commit_if_standalone()
    return true


func _clear_tile_layer(tile: MapTile, layer: StringName) -> void:
    match layer:
        &"ground": tile.ground.clear()
        &"frame": tile.frame.clear()
        &"decoration": tile.decoration.clear()
        &"terrain": tile.terrain.clear()
        &"damage": tile.damage.clear()
        &"building": tile.building.clear()


func add_player(type: String, side: String, alive: bool, team: Variant, ap: int = 0, peer_id: Variant = null) -> void:
    self._state.add_player(type, side, alive, team, peer_id)
    var player_id: int = self._state.players.size() - 1
    self._state.add_player_ap(player_id, ap)
    self._state.set_player_team(side, self._state.get_player_team(side))


func get_current_side() -> String:
    return self._state.get_current_side()


func get_current_team() -> int:
    return self._state.get_current_team()


func get_current_ap() -> int:
    return self._state.get_current_ap()


func get_player_team(side: String) -> int:
    return self._state.get_player_team(side)


func add_current_player_ap(value: int) -> bool:
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.NONE, self.add_current_player_ap.bind(value)
        )
    self._state.add_current_player_ap(value)
    self._commit_update()
    return true


func use_current_player_ap(value: int) -> bool:
    if value < 0 or not self._state.can_current_player_afford(value):
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.NONE, self.use_current_player_ap.bind(value)
        )
    self._use_current_player_ap(value)
    self._commit_update()
    return true


func can_current_player_afford(amount: int) -> bool:
    return self._state.can_current_player_afford(amount)


func end_turn() -> bool:
    if self._state.players.is_empty():
        return false
    if self._should_submit_command():
        return self.submit_command(BoardAnimation.Kind.NONE, self.end_turn)
    self.clear_undo()
    self._command_in_progress = true
    self._state.switch_to_next_player()
    self._prepare_current_turn()
    if self.turn_limit > 0 and self._state.turn > self.turn_limit:
        self.winner = "none"
        self.request_presentation(EndGamePresentationEvent.new(self.winner))
    self.events.emit_event(TurnStartedEvent.new(self._state.turn, self._state.current_player))
    self._command_in_progress = false
    self._commit_update()
    return true


func start_match() -> bool:
    if self._state.players.is_empty():
        return false
    if self._should_submit_command():
        return self.submit_command(BoardAnimation.Kind.NONE, self.start_match)
    self._command_in_progress = true
    self._prepare_current_turn()
    self.events.emit_event(TurnStartedEvent.new(self._state.turn, self._state.current_player))
    self._command_in_progress = false
    self._commit_update()
    return true


func is_current_player_ai() -> bool:
    return self._state.is_current_player_ai()


func _get_tile_at(position: Vector2i) -> MapTile:
    if self.map_model == null:
        return null
    return self.map_model.get_tile(position)


func is_tile_selectable_for_current_player(position: Vector2i) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    return tile != null and tile.is_selectable(self._state.get_current_side())


func get_legal_moves(source_position: Vector2i) -> Dictionary[Vector2i, Array]:
    var result: Dictionary[Vector2i, Array] = {}
    var source: MapTile = self._get_tile_at(source_position)
    if source == null or not source.unit.is_present():
        return result
    var unit: BaseUnit = source.unit.tile
    if unit.side != self._state.get_current_side():
        return result

    var max_cost: int = min(unit.get_move(), self._state.get_current_ap())
    var costs: Dictionary[Vector2i, int] = {source.position: 0}
    var paths: Dictionary[Vector2i, Array] = {source.position: [source.position]}
    var queue: Array[MapTile] = [source]

    while not queue.is_empty():
        var tile: MapTile = queue.pop_front()
        var cost: int = costs[tile.position]
        if cost >= max_cost:
            continue
        if tile != source and not tile.can_pass_through(unit):
            continue

        for neighbour: MapTile in tile.neighbours.values():
            var new_cost: int = cost + 1
            if costs.has(neighbour.position) and costs[neighbour.position] <= new_cost:
                continue
            costs[neighbour.position] = new_cost
            var path: Array = paths[tile.position].duplicate()
            path.append(neighbour.position)
            paths[neighbour.position] = path
            if neighbour.can_acommodate_unit(unit):
                result[neighbour.position] = path
            if neighbour.can_pass_through(unit):
                queue.append(neighbour)

    return result


func get_legal_interactions(source_position: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var source: MapTile = self._get_tile_at(source_position)
    if source == null or not source.unit.is_present() or not self._state.can_current_player_afford(1):
        return result
    var unit: BaseUnit = source.unit.tile
    if not unit.has_moves():
        return result
    for target: MapTile in source.neighbours.values():
        if target.has_enemy_unit(unit.side, unit.team) and unit.has_attacks() and unit.can_attack_unit(target.unit.tile):
            result.append(target.position)
        elif target.has_enemy_building(unit.side, unit.team) and unit.can_capture:
            result.append(target.position)
    return result


func get_legal_ability_targets(origin_position: Vector2i, ability_key: String) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var origin: MapTile = self._get_tile_at(origin_position)
    if origin == null:
        return result
    var source: Variant = self._get_ability_source(origin)
    var ability: Ability = self._find_ability(source, ability_key)
    if source == null or ability == null or not self.is_ability_visible(origin_position, ability_key):
        return result
    if source.side != self._state.get_current_side():
        return result
    if source is BaseUnit and not source.has_moves():
        return result
    var ability_state: AbilityState = source.get_ability_state(ability)
    if ability_state.is_on_cooldown():
        return result
    var cost: int = ability.get_cost(source)
    var spawn_ability := ability as SpawnUnit
    if spawn_ability != null:
        cost = self.abilities.get_modified_cost(cost, spawn_ability.template_name, source)
    if not self._state.can_current_player_afford(cost):
        return result

    if ability.TYPE == "production":
        for neighbour: MapTile in origin.neighbours.values():
            if neighbour.can_acommodate_unit():
                result.append(neighbour.position)
        return result

    var visited: Dictionary[Vector2i, int] = {origin.position: 0}
    var queue: Array[MapTile] = [origin]
    while not queue.is_empty():
        var tile: MapTile = queue.pop_front()
        var distance: int = visited[tile.position]
        if ability.is_tile_applicable(tile, origin, source):
            result.append(tile.position)
        if distance >= ability.ability_range:
            continue
        for neighbour: MapTile in tile.neighbours.values():
            if not visited.has(neighbour.position):
                visited[neighbour.position] = distance + 1
                queue.append(neighbour)
    return result


func is_ability_visible(origin_position: Vector2i, ability_key: String) -> bool:
    var origin: MapTile = self._get_tile_at(origin_position)
    if origin == null:
        return false
    var source: Variant = self._get_ability_source(origin)
    var ability: Ability = self._find_ability(source, ability_key)
    if source == null or ability == null:
        return false
    var ability_state: AbilityState = source.get_ability_state(ability)
    if ability_state.disabled:
        return false
    return ability.is_visible(ability_state, self, source)


func move_unit(source_position: Vector2i, destination_position: Vector2i) -> bool:
    var legal_moves: Dictionary[Vector2i, Array] = self.get_legal_moves(source_position)
    if not legal_moves.has(destination_position):
        return false
    var source: MapTile = self._get_tile_at(source_position)
    var destination: MapTile = self._get_tile_at(destination_position)
    var unit: BaseUnit = source.unit.tile
    var raw_path: Array = legal_moves[destination_position]
    var path: Array[Vector2i] = []
    path.assign(raw_path)
    var move_cost: int = path.size() - 1

    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.MOVE,
            self.move_unit.bind(source_position, destination_position),
            unit.model_id, source_position, destination_position, path
        )

    self._command_in_progress = true
    if self._state.is_current_player_ai():
        self.clear_undo()
    else:
        self._last_unit_move = {
            "source": source_position,
            "destination": destination_position,
            "cost": move_cost,
            "path": path,
            "player": self._state.current_player,
            "unit": unit.model_id,
        }
    destination.unit.set_tile(unit)
    source.unit.release()
    unit.state.use_move(move_cost)
    self._use_current_player_ap(move_cost)
    self._publish_event(UnitMovedDomainEvent.new(unit.model_id, destination_position, path))
    self._command_in_progress = false
    self._commit_update()
    return true


func attack_unit(attacker_position: Vector2i, defender_position: Vector2i) -> bool:
    if not self.get_legal_interactions(attacker_position).has(defender_position):
        return false
    var attacker_tile: MapTile = self._get_tile_at(attacker_position)
    var defender_tile: MapTile = self._get_tile_at(defender_position)
    if not defender_tile.unit.is_present():
        return false
    var attacker: BaseUnit = attacker_tile.unit.tile
    var defender: BaseUnit = defender_tile.unit.tile
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.ATTACK,
            self.attack_unit.bind(attacker_position, defender_position),
            attacker.model_id, attacker_position, defender_position
        )
    self.clear_undo()
    self._command_in_progress = true
    attacker.state.use_move(1)
    attacker.state.use_attack()
    if not defender.ai_paused:
        defender.state.receive_direct_damage(max(0, attacker.get_attack() - defender.get_armor()))
    var retaliated := false

    if defender.is_alive() and defender.can_retaliate(attacker):
        retaliated = true
        defender.state.remove_moves()
        attacker.state.receive_direct_damage(max(0, defender.get_attack() - attacker.get_armor()))

    self._use_current_player_ap(1)
    self._publish_event(AttackResolvedEvent.new(
        attacker_position, defender_position, retaliated, attacker.model_id, defender.model_id
    ))
    if not defender.is_alive():
        self._destroy_unit(defender_tile, attacker.model_id, true)
    elif not attacker.is_alive():
        self._destroy_unit(attacker_tile, defender.model_id, true)
    self._command_in_progress = false
    self._commit_update()
    return true


func capture_building(attacker_position: Vector2i, building_position: Vector2i) -> bool:
    if not self.get_legal_interactions(attacker_position).has(building_position):
        return false
    var attacker_tile: MapTile = self._get_tile_at(attacker_position)
    var building_tile: MapTile = self._get_tile_at(building_position)
    if not building_tile.building.is_present():
        return false
    var attacker: BaseUnit = attacker_tile.unit.tile
    var building: BaseBuilding = building_tile.building.tile
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.CAPTURE,
            self.capture_building.bind(attacker_position, building_position),
            attacker.model_id, attacker_position, building_position
        )
    self.clear_undo()
    self._command_in_progress = true
    var old_side: String = building.side
    attacker.state.remove_moves()
    building.side = attacker.side
    building.team = attacker.team
    self._use_current_player_ap(1)
    self._publish_event(BuildingCapturedDomainEvent.new(
        building_position, building.side, old_side
    ))
    if building.require_crew and not self.abilities.can_intimidate_crew(attacker):
        self._destroy_unit(attacker_tile)
    self._command_in_progress = false
    self._commit_update()
    return true


func undo_last_move() -> bool:
    if self._last_unit_move.is_empty() or self._last_unit_move["player"] != self._state.current_player:
        return false
    var source_position: Vector2i = self._last_unit_move["source"]
    var destination_position: Vector2i = self._last_unit_move["destination"]
    var move_cost: int = int(self._last_unit_move["cost"])
    var source: MapTile = self._get_tile_at(source_position)
    var destination: MapTile = self._get_tile_at(destination_position)
    if source == null or destination == null or source.unit.is_present() or not destination.unit.is_present():
        return false
    var unit: BaseUnit = destination.unit.tile
    if unit.model_id != self._last_unit_move["unit"]:
        return false
    var undo_path: Array[Vector2i] = []
    undo_path.assign(self._last_unit_move["path"])
    undo_path.reverse()
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.MOVE, self.undo_last_move,
            unit.model_id, destination_position, source_position, undo_path
        )
    source.unit.set_tile(unit)
    destination.unit.release()
    unit.state.restore_move(move_cost)
    self._state.add_current_player_ap(move_cost)
    self._pending_events.append(UnitMovedDomainEvent.new(unit.model_id, source_position, undo_path))
    self._last_unit_move.clear()
    self._commit_update()
    return true


func reserve_ap(amount: int) -> void:
    self.reserved_ap += max(0, amount)


func use_ability(origin_position: Vector2i, ability_key: String, target_position: Vector2i) -> bool:
    if not self.get_legal_ability_targets(origin_position, ability_key).has(target_position):
        return false
    var origin: MapTile = self._get_tile_at(origin_position)
    var source: Variant = self._get_ability_source(origin)
    var ability: Ability = self._find_ability(source, ability_key)
    if source == null or ability == null:
        return false
    var ability_state: AbilityState = source.get_ability_state(ability)
    if ability_state.disabled or ability_state.is_on_cooldown():
        return false
    var cost: int = ability.get_cost(source)
    var spawn_ability := ability as SpawnUnit
    if spawn_ability != null:
        cost = self.abilities.get_modified_cost(cost, spawn_ability.template_name, source)
    if not self._state.can_current_player_afford(cost):
        return false

    if self._should_submit_command():
        return self.submit_command(
            ability.animation,
            self.use_ability.bind(origin_position, ability_key, target_position),
            source.model_id, origin_position, target_position
        )

    self.clear_undo()
    self._command_in_progress = true
    self._use_current_player_ap(cost)
    var ability_event_index: int = self._pending_events.size()
    var affected_positions: Array[Vector2i] = ability.execute_model(self, source, origin, target_position)
    if source is BaseUnit:
        source.state.use_move(1)
    ability_state.cd_turns_left = self.abilities.get_modified_cooldown(ability.get_cooldown(source), source)
    var source_id: int = source.model_id
    self._publish_event(AbilityUsedDomainEvent.new(
        source_id, origin_position, target_position, ability.animation,
        affected_positions, ability.get_key()
    ), ability_event_index)
    self._command_in_progress = false
    self._commit_update()
    return true


func scripted_use_ability(
    origin_position: Vector2i,
    ability_key: String,
    target_position: Vector2i,
    apply_cooldown: bool = false
) -> bool:
    var origin: MapTile = self._get_tile_at(origin_position)
    if origin == null:
        return false
    var source: Variant = self._get_ability_source(origin)
    var ability: Ability = self._find_ability(source, ability_key)
    if source == null or ability == null:
        return false

    if self._should_submit_command():
        return self.submit_command(
            ability.animation,
            self.scripted_use_ability.bind(
                origin_position, ability_key, target_position, apply_cooldown
            ),
            source.model_id, origin_position, target_position
        )

    var was_nested: bool = self._command_in_progress
    self._command_in_progress = true
    var ability_event_index: int = self._pending_events.size()
    var affected_positions: Array[Vector2i] = ability.execute_model(self, source, origin, target_position)
    if apply_cooldown:
        source.get_ability_state(ability).cd_turns_left = self.abilities.get_modified_cooldown(
            ability.get_cooldown(source), source
        )
    self._publish_event(AbilityUsedDomainEvent.new(
        source.model_id, origin_position, target_position, ability.animation,
        affected_positions, ability.get_key()
    ), ability_event_index)
    self._command_in_progress = was_nested
    self._commit_if_standalone()
    return true


func _spawn_unit(position: Vector2i, template_key: String, side: String, rotation: int = 0, ai_paused: bool = false) -> BaseUnit:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.can_acommodate_unit():
        return null
    var unit: BaseUnit = self.templates.get_template(template_key) as BaseUnit
    if unit == null:
        return null
    unit.side = side
    unit.team = self._state.get_player_team(side)
    unit.current_rotation = rotation
    unit.state.ai_paused = ai_paused
    unit.state.reset_from_stats(unit.get_stats_with_modifiers())
    self._assign_unit_id(unit)
    tile.unit.set_tile(unit)
    if unit is HeroUnit:
        self._state.auto_set_hero(unit as HeroUnit)
    self._publish_event(UnitSpawnedDomainEvent.new(unit.model_id, position, template_key, side))
    return unit


func destroy_unit(position: Vector2i, attacker_id: int = 0, generate_collateral: bool = true) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.unit.is_present():
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.DESTROY,
            self.destroy_unit.bind(position, attacker_id, generate_collateral),
            tile.unit.tile.model_id, position, position
        )
    var was_nested: bool = self._command_in_progress
    self._command_in_progress = true
    self._destroy_unit(tile, attacker_id, generate_collateral)
    self._command_in_progress = was_nested
    self._commit_if_standalone()
    return true


func destroy_units(positions: Array[Vector2i]) -> bool:
    var present_positions: Array[Vector2i] = []
    for position: Vector2i in positions:
        var tile: MapTile = self._get_tile_at(position)
        if tile != null and tile.unit.is_present():
            present_positions.append(position)
    if present_positions.is_empty():
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.DESTROY, self.destroy_units.bind(present_positions),
            0, present_positions[0], present_positions[0]
        )
    var was_nested: bool = self._command_in_progress
    self._command_in_progress = true
    for position: Vector2i in present_positions:
        self._destroy_unit(self._get_tile_at(position), 0, false)
    self._command_in_progress = was_nested
    self._commit_if_standalone()
    return true


func damage_unit(position: Vector2i, damage: int, direct: bool = false, attacker_id: int = 0) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.unit.is_present():
        return false
    var unit: BaseUnit = tile.unit.tile
    if unit.ai_paused:
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.NONE,
            self.damage_unit.bind(position, damage, direct, attacker_id),
            unit.model_id, position, position
        )
    var was_nested: bool = self._command_in_progress
    self._command_in_progress = true
    var final_damage: int = damage if direct else max(0, damage - unit.get_armor())
    unit.state.receive_direct_damage(final_damage)
    if not unit.is_alive():
        self._destroy_unit(tile, attacker_id, true)
    self._command_in_progress = was_nested
    self._commit_if_standalone()
    return true


func heal_unit(position: Vector2i, value: int) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.unit.is_present():
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.HEAL, self.heal_unit.bind(position, value),
            tile.unit.tile.model_id, position, position
        )
    var unit: BaseUnit = tile.unit.tile
    unit.state.heal(value, unit.get_stats_with_modifiers())
    self._commit_if_standalone()
    return true


func relocate_unit(
    source_position: Vector2i,
    destination_position: Vector2i,
    directions: Array[String] = []
) -> bool:
    var source: MapTile = self._get_tile_at(source_position)
    var destination: MapTile = self._get_tile_at(destination_position)
    if source == null or destination == null or not source.unit.is_present() or not destination.can_acommodate_unit(source.unit.tile):
        return false
    var unit: BaseUnit = source.unit.tile
    var path: Array[Vector2i] = [source_position]
    var path_tile: MapTile = source
    var route: Array[String] = directions.duplicate()
    if not route.is_empty():
        route.pop_back()
    for direction: String in route:
        path_tile = path_tile.get_neighbour(direction)
        if path_tile == null:
            return false
        path.append(path_tile.position)
    if not directions.is_empty() and path_tile != destination:
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.MOVE,
            self.relocate_unit.bind(source_position, destination_position, directions.duplicate()),
            unit.model_id, source_position, destination_position, path, directions
        )
    var was_nested: bool = self._command_in_progress
    self._command_in_progress = true
    destination.unit.set_tile(unit)
    source.unit.release()
    self._publish_event(UnitMovedDomainEvent.new(
        unit.model_id, destination_position, path, directions
    ))
    self._command_in_progress = was_nested
    self._commit_if_standalone()
    return true


func damage_terrain(position: Vector2i) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.terrain.is_present():
        return false
    var terrain: BaseTile = tile.terrain.tile
    if not terrain.is_damageable():
        return false
    var template_key: String = terrain.next_damage_stage_template
    var rotation: int = terrain.current_rotation
    if not (self.templates.get_template_source(template_key) is TileResource):
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.TILE_DAMAGE, self.damage_terrain.bind(position),
            0, position, position
        )
    return self.apply_tile_damage_result(position, &"terrain", template_key, rotation)


func place_ground_damage(position: Vector2i, template_key: String, rotation: int) -> bool:
    var tile: MapTile = self._get_tile_at(position)
    if tile == null or not tile.ground.is_present() or tile.terrain.is_present():
        return false
    if not (self.templates.get_template_source(template_key) is TileResource):
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.TILE_DAMAGE,
            self.place_ground_damage.bind(position, template_key, rotation),
            0, position, position
        )
    var damage: BaseTile = self.templates.get_template(template_key) as BaseTile
    if damage == null:
        return false
    if tile.decoration.is_present():
        tile.decoration.clear()
    damage.current_rotation = rotation
    damage.rotation_degrees.y = rotation
    tile.damage.set_tile(damage)
    tile.is_state_modified = true
    self._pending_events.append(TileDamagedEvent.new(position, &"damage", template_key, rotation))
    self._commit_if_standalone()
    return true


func apply_tile_damage_result(position: Vector2i, layer: StringName, template_key: String, rotation: int) -> bool:
    if layer == &"damage":
        return self.place_ground_damage(position, template_key, rotation)
    if layer != &"terrain":
        return false
    var tile: MapTile = self._get_tile_at(position)
    if tile == null:
        return false
    if not (self.templates.get_template_source(template_key) is TileResource):
        return false
    if self._should_submit_command():
        return self.submit_command(
            BoardAnimation.Kind.TILE_DAMAGE,
            self.apply_tile_damage_result.bind(position, layer, template_key, rotation),
            0, position, position
        )
    var replacement: BaseTile = self.templates.get_template(template_key) as BaseTile
    if replacement == null:
        return false
    replacement.current_rotation = rotation
    replacement.rotation_degrees.y = rotation
    tile.terrain.set_tile(replacement)
    tile.is_state_modified = true
    self._pending_events.append(TileDamagedEvent.new(position, layer, template_key, rotation))
    self._commit_if_standalone()
    return true


func _replenish_unit_actions(side: String = "") -> void:
    if self.map_model == null:
        return
    if side.is_empty():
        side = self.get_current_side()
    for unit: BaseUnit in self.map_model.get_player_units(side):
        unit.state.clear_modifiers()
        self.abilities.apply_passive_modifiers(unit)
        unit.state.replenish_moves(unit.get_stats_with_modifiers())
        unit.ability_cd_tick_down()
        unit.team = self._state.get_player_team(side)


func _prepare_current_turn() -> void:
    self._replenish_unit_actions()
    var ap_gain: int = 0
    if self.map_model != null:
        for building: BaseBuilding in self.map_model.get_player_buildings(self.get_current_side()):
            ap_gain += self.abilities.get_modified_ap_gain(building.ap_gain, building)
            building.team = self.get_current_team()
    if ap_gain != 0:
        self._state.add_current_player_ap(ap_gain)


func get_snapshot() -> BoardStateSnapshot:
    self._assign_entity_ids()
    var player_snapshots: Array[PlayerStateSnapshot] = []
    for player: PlayerState in self._state.players:
        player_snapshots.append(self._snapshot_player(player))
    var match_snapshot := MatchStateSnapshot.new(
        self._state.current_player, self._state.turn, self._state.has_player_moved,
        player_snapshots, self.turn_limit, self.time_limit
    )
    var empty_tiles: Dictionary[Vector2i, TileStateSnapshot] = {}
    var map_snapshot := MapStateSnapshot.new(empty_tiles)
    if self.map_model != null:
        var tile_snapshots: Dictionary[Vector2i, TileStateSnapshot] = {}
        for tile: MapTile in self.map_model.tiles.values():
            if tile.has_content() or tile.is_state_modified:
                tile_snapshots[tile.position] = self._snapshot_tile(tile)
        map_snapshot = MapStateSnapshot.new(tile_snapshots)
    var trigger_state: Dictionary[String, Variant] = {}
    if not self.scripting.triggers.is_empty():
        trigger_state = self.scripting.get_save_data()
    return BoardStateSnapshot.new(
        match_snapshot,
        map_snapshot,
        ScenarioStateSnapshot.new(self.objectives, trigger_state, self.winner)
    )


func _snapshot_player(player: PlayerState) -> PlayerStateSnapshot:
    return PlayerStateSnapshot.new(
        player.type, player.side, player.team, player.ap, player.alive, player.peer_id
    )


func _snapshot_tile(tile: MapTile) -> TileStateSnapshot:
    return TileStateSnapshot.new(
        tile.position,
        self._snapshot_map_object(tile.ground.tile), self._snapshot_map_object(tile.frame.tile),
        self._snapshot_map_object(tile.decoration.tile), self._snapshot_map_object(tile.terrain.tile),
        self._snapshot_map_object(tile.damage.tile), self._snapshot_unit(tile), self._snapshot_building(tile)
    )


func _snapshot_map_object(object: MapObject) -> MapObjectStateSnapshot:
    if object == null:
        return null
    return MapObjectStateSnapshot.new(object.template_name, object.current_rotation)


func _snapshot_unit(tile: MapTile) -> UnitStateSnapshot:
    if not tile.unit.is_present():
        return null
    return self._snapshot_unit_instance(tile.unit.tile)


func _snapshot_unit_instance(unit: BaseUnit) -> UnitStateSnapshot:
    var passenger_snapshot: UnitStateSnapshot = null
    if unit.passenger != null:
        passenger_snapshot = self._snapshot_unit_instance(unit.passenger)
    var disable_active_abilities: bool = unit is HeroUnit and (unit as HeroUnit).disable_active_abilities
    return UnitStateSnapshot.new(
        unit.model_id, unit.template_name, unit.current_rotation, unit.side, unit.team,
        unit.get_stats_with_modifiers(), unit.ai_paused, unit.modifiers, unit.scripting_tags,
        self._snapshot_abilities(unit.active_abilities, unit.ability_states),
        disable_active_abilities, passenger_snapshot
    )


func _snapshot_building(tile: MapTile) -> BuildingStateSnapshot:
    if not tile.building.is_present():
        return null
    var building: BaseBuilding = tile.building.tile
    return BuildingStateSnapshot.new(
        building.model_id, building.template_name, building.current_rotation, building.side,
        self._snapshot_abilities(building.abilities, building.ability_states)
    )


func _snapshot_abilities(definitions: Array, states: Dictionary) -> Array[AbilityStateSnapshot]:
    var result: Array[AbilityStateSnapshot] = []
    for ability: Ability in definitions:
        var ability_state: AbilityState = states.get(ability, AbilityState.new())
        result.append(AbilityStateSnapshot.new(
            ability.index, ability_state.disabled, ability_state.cd_turns_left
        ))
    return result


func _get_ability_source(origin: MapTile) -> Variant:
    if origin.unit.is_present():
        return origin.unit.tile
    if origin.building.is_present():
        return origin.building.tile
    return null


func _find_ability(source: Variant, ability_key: String) -> Ability:
    if source == null:
        return null
    var definitions: Array = source.active_abilities if source is BaseUnit else source.abilities
    for ability: Ability in definitions:
        if ability.get_key() == ability_key:
            return ability
    return null


func _use_current_player_ap(value: int) -> void:
    self._state.use_current_player_ap(value)


func _destroy_unit(tile: MapTile, attacker_id: int = 0, generate_collateral: bool = false) -> void:
    var unit: BaseUnit = tile.unit.tile
    if unit == null:
        return
    var attacker: BaseUnit = self.find_unit_by_id(attacker_id)
    if attacker != null:
        attacker.state.score_kill()
        self._grant_unit_experience(attacker)
    if unit is HeroUnit:
        self._state.clear_hero_for_side(unit.side, unit as HeroUnit)
    tile.unit.release()
    self._publish_event(UnitDestroyedDomainEvent.new(
        unit.model_id, tile.position, unit.template_name, unit.side, attacker_id
    ))
    if unit.is_inside_tree():
        unit.queue_free()
    else:
        unit.free()
    if generate_collateral:
        self._generate_collateral_damage(tile)


func _generate_collateral_damage(tile: MapTile) -> void:
    if not self.random_collateral_enabled:
        return
    var was_nested: bool = self._command_in_progress
    self._command_in_progress = true
    for neighbour: MapTile in tile.neighbours.values():
        if randf() <= self.COLLATERAL_CHANCE:
            self.damage_terrain(neighbour.position)
    if tile.ground.is_present() and not tile.damage.is_present() and not tile.terrain.is_present():
        var ground: BaseTile = tile.ground.tile
        if not ground.unit_can_fly:
            self.place_ground_damage(
                tile.position,
                String(self.GROUND_DAMAGE_TEMPLATES.pick_random()),
                int([0, 90, 180, 270].pick_random())
            )
    self._command_in_progress = was_nested


func _assign_entity_ids() -> void:
    if self.map_model == null:
        return
    for tile: MapTile in self.map_model.tiles.values():
        if tile.unit.is_present():
            self._assign_unit_id(tile.unit.tile)
        if tile.building.is_present():
            var building: BaseBuilding = tile.building.tile
            if building.model_id <= 0:
                building.model_id = self._take_entity_id()
            else:
                self._next_entity_id = max(self._next_entity_id, building.model_id + 1)


func _assign_unit_id(unit: BaseUnit) -> void:
    if unit.model_id <= 0:
        unit.model_id = self._take_entity_id()
    else:
        self._next_entity_id = max(self._next_entity_id, unit.model_id + 1)
    if unit.passenger != null:
        self._assign_unit_id(unit.passenger)


func find_map_object_by_id(id: int) -> MapObject:
    if id <= 0 or self.map_model == null:
        return null
    for tile: MapTile in self.map_model.tiles.values():
        if tile.unit.is_present() and tile.unit.tile.model_id == id:
            return tile.unit.tile
        if tile.building.is_present() and tile.building.tile.model_id == id:
            return tile.building.tile
    return null


func find_unit_by_id(id: int) -> BaseUnit:
    return self.find_map_object_by_id(id) as BaseUnit


func _grant_unit_experience(unit: BaseUnit) -> void:
    if unit.level < unit.MAX_LEVEL and unit.state.gain_exp(unit.EXP_PER_LEVEL) and unit.allow_level_up:
        var raw_position: Variant = self.map_model.get_unit_position(unit)
        if raw_position != null:
            self._level_up_unit(unit, Vector2i(int(raw_position[0]), int(raw_position[1])))


func _level_up_unit(unit: BaseUnit, position: Vector2i) -> bool:
    if unit == null or unit.is_max_level() or not unit.allow_level_up:
        return false
    unit.state.level_up()
    self._pending_events.append(UnitLeveledUpDomainEvent.new(unit.model_id, position))
    return true


func _publish_event(event: BoardDomainEvent, index: int = -1) -> void:
    if index < 0:
        self._pending_events.append(event)
    else:
        self._pending_events.insert(index, event)
    self.events.emit_event(event)


func _take_entity_id() -> int:
    var result: int = self._next_entity_id
    self._next_entity_id += 1
    return result


func _commit_update() -> void:
    var emitted_events: Array[BoardDomainEvent] = self._pending_events.duplicate()
    self._pending_events.clear()
    self.updated.emit(self.get_snapshot(), emitted_events)


func _commit_if_standalone() -> void:
    if not self._command_in_progress:
        self._commit_update()
