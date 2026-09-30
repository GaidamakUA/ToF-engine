class_name BoardAnimationPlayer
extends Node


const DEEP_STRIKE_EXECUTOR := preload("res://scenes/abilities/hero/active/deep_strike_executor.tscn")
const PRECISION_STRIKE_EXECUTOR := preload("res://scenes/abilities/hero/active/precision_strike_executor.tscn")
const BUILDING_CAPTURE_STREAM := preload("res://assets/audio/building_capture_drum_2.wav")
const UNIT_AUDIO_BUSES: Dictionary[String, StringName] = {
	"attack": &"Attack",
	"die": &"Explosion",
}

var board: Variant
var _registry: Dictionary = {}
var _handled_events: Dictionary = {}
var _lead_in_executor: Variant


func _init(board_view: Variant = null) -> void:
	self.board = board_view
	self._registry = {
		BoardAnimation.Kind.MOVE: self._play_move,
		BoardAnimation.Kind.ATTACK: self._play_attack,
		BoardAnimation.Kind.CAPTURE: self._play_capture,
		BoardAnimation.Kind.SPAWN: self._play_spawn,
		BoardAnimation.Kind.DESTROY: self._play_destroy,
		BoardAnimation.Kind.TILE_DAMAGE: self._play_tile_damage,
		BoardAnimation.Kind.TILE_CHANGE: self._play_tile_change,
		BoardAnimation.Kind.SMOKE: self._play_smoke,
		BoardAnimation.Kind.BLESS: self._play_bless,
		BoardAnimation.Kind.HEAL: self._play_heal,
		BoardAnimation.Kind.LEVEL_UP: self._play_level_up,
		BoardAnimation.Kind.PROJECTILE: self._play_projectile.bind(false),
		BoardAnimation.Kind.LOB_PROJECTILE: self._play_projectile.bind(true),
		BoardAnimation.Kind.PICK_UP: self._play_pick_up,
		BoardAnimation.Kind.DROP_OFF: self._play_drop_off,
		BoardAnimation.Kind.DEEP_STRIKE: self._play_deep_strike,
		BoardAnimation.Kind.PRECISION_STRIKE: self._play_precision_strike,
	}


func has_animation(kind: BoardAnimation.Kind) -> bool:
	return kind == BoardAnimation.Kind.NONE or self._registry.has(kind)


func play_lead_in(command: BoardCommand) -> void:
	match command.animation:
		BoardAnimation.Kind.MOVE:
			await self._play_move_lead_in(command.source_id, command.path, command.directions)
		BoardAnimation.Kind.PROJECTILE:
			await self._play_projectile_lead_in(command.origin, command.target, false)
		BoardAnimation.Kind.LOB_PROJECTILE:
			await self._play_projectile_lead_in(command.origin, command.target, true)
		BoardAnimation.Kind.DEEP_STRIKE:
			self._lead_in_executor = await self._play_strike_lead_in(
				self.DEEP_STRIKE_EXECUTOR, command.source_id, command.target
			)
		BoardAnimation.Kind.PRECISION_STRIKE:
			self._lead_in_executor = await self._play_strike_lead_in(
				self.PRECISION_STRIKE_EXECUTOR, command.source_id, command.target
			)


func play(
	events: Array[BoardDomainEvent],
	command: BoardCommand = null
) -> void:
	self._handled_events.clear()
	if command != null and command.animation == BoardAnimation.Kind.MOVE:
		for event: BoardDomainEvent in events:
			if event is UnitMovedDomainEvent:
				self._handled_events[event] = true
	var ability_event: AbilityUsedDomainEvent = self._find_ability_event(events)
	if ability_event != null and ability_event.animation != BoardAnimation.Kind.NONE:
		if command != null and command.animation == ability_event.animation:
			await self._play_ability_impact(command, ability_event, events)
		else:
			await self._play(ability_event.animation, ability_event, events)
		self._handled_events[ability_event] = true

	for event: BoardDomainEvent in events:
		if self._handled_events.has(event) or event is AbilityUsedDomainEvent:
			continue
		var kind: BoardAnimation.Kind = self._get_event_animation(event)
		if kind != BoardAnimation.Kind.NONE:
			await self._play(kind, event, events)
	self._refresh_unit_views()


func _play_move_lead_in(
	source_id: int,
	path: Array[Vector2i],
	directions: Array[String]
) -> void:
	var unit: BaseUnit = self.board.board_model.find_unit_by_id(source_id)
	if unit == null or path.size() < 2:
		return
	var marker_path: Array[String] = []
	for path_position: Vector2i in path:
		marker_path.push_front(str(path_position.x) + "_" + str(path_position.y))
	self._play_unit_audio(unit.template_name, "move")
	if directions.is_empty():
		unit.animate_path(self.board.path_markers.convert_path_to_directions(marker_path))
	else:
		unit.animate_path(directions)
	await unit.move_finished


func _play_projectile_lead_in(origin: Vector2i, target: Vector2i, lob: bool) -> void:
	var source: MapTile = self.board.map.model.get_tile(origin)
	if source == null:
		return
	if lob:
		self.board.smoke_a_tile(source)
	if source.unit.is_present():
		self._play_unit_audio(source.unit.tile.template_name, "attack")
	var projectile: ProjectileFx = self.board._spawn_temporary_projectile_instance_on_tile(source)
	var target_position: Vector3 = self.board.map.map_to_local(target)
	if lob:
		await projectile.lob_at_position(Vector3(target_position.x, 0, target_position.z), 0.5)
	else:
		await projectile.shoot_at_position(Vector3(target_position.x, 0, target_position.z), 0.1)


func _play_strike_lead_in(
	executor_scene: PackedScene,
	source_id: int,
	target: Vector2i
) -> Variant:
	var source: BaseUnit = self.board.board_model.find_unit_by_id(source_id)
	if source == null:
		return null
	var executor: Variant = executor_scene.instantiate()
	executor.set_up(self.board, target, source)
	self.board.ability_markers.add_child(executor)
	executor.position = self.board.map.map_to_local(target)
	self._play_unit_resource_audio(executor.heli_resource, "move")
	await executor.impact
	return executor


func _play_ability_impact(
	command: BoardCommand,
	event: AbilityUsedDomainEvent,
	events: Array[BoardDomainEvent]
) -> void:
	var executor: Variant = self._lead_in_executor
	self._lead_in_executor = null
	match command.animation:
		BoardAnimation.Kind.PROJECTILE, BoardAnimation.Kind.LOB_PROJECTILE:
			self._play_projectile_impact(event, events)
		BoardAnimation.Kind.DEEP_STRIKE:
			await self._play_deep_strike_impact(executor, event, events)
		BoardAnimation.Kind.PRECISION_STRIKE:
			await self._play_precision_strike_impact(executor, event, events)
		_:
			await self._play(command.animation, event, events)


func _play_projectile_impact(event: AbilityUsedDomainEvent, events: Array[BoardDomainEvent]) -> void:
	var target: MapTile = self.board.map.model.get_tile(event.target)
	if target != null:
		self.board.explode_a_tile(target)
	self._consume_destroyed_positions(event.affected_positions, events)
	self._present_tile_damage_consequences(events)


func _play_deep_strike_impact(
	executor: Variant,
	event: AbilityUsedDomainEvent,
	events: Array[BoardDomainEvent]
) -> void:
	self._present_spawn_at(event.target, events)
	var target: MapTile = self.board.map.model.get_tile(event.target)
	if target != null:
		self.board.smoke_a_tile(target)
	if executor != null:
		await executor.finished


func _play_precision_strike_impact(
	executor: Variant,
	event: AbilityUsedDomainEvent,
	events: Array[BoardDomainEvent]
) -> void:
	if executor != null:
		self._play_unit_resource_audio(executor.heli_resource, "attack")
	for position: Vector2i in event.affected_positions:
		var tile: MapTile = self.board.map.model.get_tile(position)
		if tile != null:
			self.board.explode_a_tile(tile)
	self._consume_destroyed_positions(event.affected_positions, events)
	self._present_tile_damage_consequences(events)
	if executor != null:
		await executor.finished


func _play(kind: BoardAnimation.Kind, event: BoardDomainEvent, events: Array[BoardDomainEvent]) -> void:
	assert(self._registry.has(kind), "No board animation registered for %s" % BoardAnimation.Kind.keys()[kind])
	var animation: Callable = self._registry[kind]
	await animation.call(event, events)
	self._handled_events[event] = true


func _get_event_animation(event: BoardDomainEvent) -> BoardAnimation.Kind:
	if event is UnitMovedDomainEvent:
		return BoardAnimation.Kind.MOVE
	if event is AttackResolvedEvent:
		return BoardAnimation.Kind.ATTACK
	if event is BuildingCapturedDomainEvent:
		return BoardAnimation.Kind.CAPTURE
	if event is UnitSpawnedDomainEvent:
		return BoardAnimation.Kind.SPAWN
	if event is UnitDestroyedDomainEvent:
		return BoardAnimation.Kind.DESTROY
	if event is TileDamagedEvent:
		return BoardAnimation.Kind.TILE_DAMAGE
	if event is TileLayerChangedEvent:
		return BoardAnimation.Kind.TILE_CHANGE
	if event is UnitLeveledUpDomainEvent:
		return BoardAnimation.Kind.LEVEL_UP
	return BoardAnimation.Kind.NONE


func _find_ability_event(events: Array[BoardDomainEvent]) -> AbilityUsedDomainEvent:
	for event: BoardDomainEvent in events:
		if event is AbilityUsedDomainEvent:
			return event as AbilityUsedDomainEvent
	return null


func _play_move(base_event: BoardDomainEvent, _events: Array[BoardDomainEvent]) -> void:
	var event := base_event as UnitMovedDomainEvent
	await self._play_move_lead_in(event.unit_id, event.path, event.directions)


func _play_attack(base_event: BoardDomainEvent, events: Array[BoardDomainEvent]) -> void:
	var event := base_event as AttackResolvedEvent
	var attacker_tile: MapTile = self.board.map.model.get_tile(event.attacker_position)
	var defender_tile: MapTile = self.board.map.model.get_tile(event.defender_position)
	if attacker_tile != null and attacker_tile.unit.is_present():
		self._play_unit_audio(attacker_tile.unit.tile.template_name, "attack")
	if defender_tile != null:
		self.board.explode_a_tile(defender_tile)
	if event.retaliated:
		await self.get_tree().create_timer(0.1).timeout
		if defender_tile != null and defender_tile.unit.is_present():
			self._play_unit_audio(defender_tile.unit.tile.template_name, "attack")
		if attacker_tile != null:
			self.board.explode_a_tile(attacker_tile)
	var combat_positions: Array[Vector2i] = [event.attacker_position, event.defender_position]
	self._consume_destroyed_positions(combat_positions, events)
	self._present_tile_damage_consequences(events)


func _play_capture(base_event: BoardDomainEvent, _events: Array[BoardDomainEvent]) -> void:
	var event := base_event as BuildingCapturedDomainEvent
	var tile: MapTile = self.board.map.model.get_tile(event.position)
	if tile == null or not tile.building.is_present():
		return
	self.board.map.builder.set_building_side(event.position, event.new_side, self.board.state.get_player_team(event.new_side))
	self.board.smoke_a_tile(tile)
	self.board.audio.play_stream(self.BUILDING_CAPTURE_STREAM, &"Units")


func _play_spawn(base_event: BoardDomainEvent, _events: Array[BoardDomainEvent]) -> void:
	var event := base_event as UnitSpawnedDomainEvent
	var unit: BaseUnit = self.board.board_model.find_unit_by_id(event.unit_id)
	if unit == null:
		return
	if unit.get_parent() == null:
		self.board.map.anchor_unit(unit, event.position)
	unit.show()
	if self.board.map.builder.enable_health and self.board.map.settings.get_option("show_health"):
		unit.enable_health()
	self.board.map.builder.configure_unit_side(unit, event.side)
	self._play_unit_audio(event.template_key, "spawn")


func _play_destroy(base_event: BoardDomainEvent, _events: Array[BoardDomainEvent]) -> void:
	var event := base_event as UnitDestroyedDomainEvent
	var tile: MapTile = self.board.map.model.get_tile(event.position)
	if tile != null:
		self._play_unit_audio(event.template_key, "die")
		self.board.explode_a_tile(tile)


func _play_tile_damage(base_event: BoardDomainEvent, _events: Array[BoardDomainEvent]) -> void:
	var event := base_event as TileDamagedEvent
	var tile: MapTile = self.board.map.model.get_tile(event.position)
	if tile == null:
		return
	var object: BaseTile = tile.terrain.tile if event.layer == &"terrain" else tile.damage.tile
	if object == null or object.get_parent() != null:
		return
	var anchor: Node3D = self.board.map.tiles_terrain_anchor if event.layer == &"terrain" else self.board.map.tiles_frames_anchor
	anchor.add_child(object)
	var object_position: Vector3 = self.board.map.map_to_local(event.position)
	object_position.y = float(self.board.map.GROUND_HEIGHT)
	if event.layer != &"terrain":
		object_position.y -= 0.05
	object.position = object_position
	object.rotation_degrees.y = event.rotation
	if event.layer == &"terrain" and object is DamagedTile:
		(object as DamagedTile).show_explosion()


func _play_tile_change(base_event: BoardDomainEvent, _events: Array[BoardDomainEvent]) -> void:
	var event := base_event as TileLayerChangedEvent
	var tile: MapTile = self.board.map.model.get_tile(event.position)
	if tile == null:
		return
	var object: MapObject = null
	var anchor: Node3D = self.board.map.tiles_frames_anchor
	var height: float = self.board.map.GROUND_HEIGHT
	match event.layer:
		&"ground":
			object = tile.ground.tile
			anchor = self.board.map.tiles_ground_anchor
			height = 0.0
		&"frame": object = tile.frame.tile
		&"decoration": object = tile.decoration.tile
		&"terrain":
			object = tile.terrain.tile
			anchor = self.board.map.tiles_terrain_anchor
		&"damage":
			object = tile.damage.tile
			height -= 0.05
		&"building":
			object = tile.building.tile
			anchor = self.board.map.tiles_buildings_anchor
	if object != null and object.get_parent() == null:
		anchor.add_child(object)
		var object_position: Vector3 = self.board.map.map_to_local(event.position)
		object_position.y = height
		object.position = object_position
		object.rotation_degrees.y = event.rotation
		if event.layer == &"building":
			self.board.map.builder.set_building_side(event.position, tile.building.tile.side, tile.building.tile.team)
	if event.effect == &"smoke":
		self.board.smoke_a_tile(tile)
	elif event.effect == &"explosion":
		self.board.explode_a_tile(tile)
	elif event.effect == &"menu_click":
		self.board.audio.play("menu_click")


func _play_smoke(base_event: BoardDomainEvent, events: Array[BoardDomainEvent]) -> void:
	var event := base_event as AbilityUsedDomainEvent
	for position: Vector2i in event.affected_positions:
		var tile: MapTile = self.board.map.model.get_tile(position)
		if tile != null:
			self.board.smoke_a_tile(tile)
	for candidate: BoardDomainEvent in events:
		var moved := candidate as UnitMovedDomainEvent
		if moved == null or moved.unit_id != event.source_id:
			continue
		var unit: BaseUnit = self.board.board_model.find_unit_by_id(moved.unit_id)
		if unit != null:
			self._place_unit(unit, moved.finish)
		self._handled_events[candidate] = true


func _play_bless(base_event: BoardDomainEvent, events: Array[BoardDomainEvent]) -> void:
	var event := base_event as AbilityUsedDomainEvent
	var level_units: Array[BaseUnit] = []
	for position: Vector2i in event.affected_positions:
		var tile: MapTile = self.board.map.model.get_tile(position)
		if tile != null:
			self.board.bless_a_tile(tile)
	for candidate: BoardDomainEvent in events:
		var level_event := candidate as UnitLeveledUpDomainEvent
		if level_event == null or not event.affected_positions.has(level_event.position):
			continue
		var unit: BaseUnit = self._start_level_up(level_event)
		if unit != null:
			level_units.append(unit)
		self._handled_events[candidate] = true
	if not level_units.is_empty():
		await level_units[0].animations.animation_finished


func _play_heal(base_event: BoardDomainEvent, _events: Array[BoardDomainEvent]) -> void:
	var event := base_event as AbilityUsedDomainEvent
	for position: Vector2i in event.affected_positions:
		var tile: MapTile = self.board.map.model.get_tile(position)
		if tile != null:
			self.board.heal_a_tile(tile)
			if tile.unit.is_present():
				self._play_unit_audio(tile.unit.tile.template_name, "spawn")


func _play_level_up(base_event: BoardDomainEvent, _events: Array[BoardDomainEvent]) -> void:
	var unit: BaseUnit = self._start_level_up(base_event as UnitLeveledUpDomainEvent)
	if unit != null:
		await unit.animations.animation_finished


func _start_level_up(event: UnitLeveledUpDomainEvent) -> BaseUnit:
	var unit: BaseUnit = self.board.board_model.find_unit_by_id(event.unit_id)
	if unit == null:
		return null
	self._play_unit_audio(unit.template_name, "level_up")
	unit.animate_level_up()
	return unit


func _play_projectile(
	base_event: BoardDomainEvent,
	events: Array[BoardDomainEvent],
	lob: bool
) -> void:
	var event := base_event as AbilityUsedDomainEvent
	if self.board.map.model.get_tile(event.origin) == null or self.board.map.model.get_tile(event.target) == null:
		return
	await self._play_projectile_lead_in(event.origin, event.target, lob)
	self._play_projectile_impact(event, events)


func _play_pick_up(base_event: BoardDomainEvent, _events: Array[BoardDomainEvent]) -> void:
	var event := base_event as AbilityUsedDomainEvent
	var source: BaseUnit = self.board.board_model.find_unit_by_id(event.source_id)
	if source != null and source.passenger != null:
		var passenger: BaseUnit = source.passenger
		self._play_unit_audio(passenger.template_name, "move")
		if passenger.get_parent() == self.board.map.tiles_units_anchor:
			self.board.map.detach_unit(passenger)
	var target: MapTile = self.board.map.model.get_tile(event.target)
	if target != null:
		self.board.smoke_a_tile(target)


func _play_drop_off(base_event: BoardDomainEvent, _events: Array[BoardDomainEvent]) -> void:
	var event := base_event as AbilityUsedDomainEvent
	var target: MapTile = self.board.map.model.get_tile(event.target)
	if target == null or not target.unit.is_present():
		return
	var unit: BaseUnit = target.unit.tile
	if unit.get_parent() == null:
		self.board.map.anchor_unit(unit, target.position)
	if self.board.map.builder.enable_health and self.board.map.settings.get_option("show_health"):
		unit.enable_health()
	self._play_unit_audio(unit.template_name, "move")
	self.board.smoke_a_tile(target)


func _play_deep_strike(base_event: BoardDomainEvent, events: Array[BoardDomainEvent]) -> void:
	var event := base_event as AbilityUsedDomainEvent
	var executor: Variant = await self._play_strike_lead_in(
		self.DEEP_STRIKE_EXECUTOR, event.source_id, event.target
	)
	if executor == null:
		return
	await self._play_deep_strike_impact(executor, event, events)


func _play_precision_strike(base_event: BoardDomainEvent, events: Array[BoardDomainEvent]) -> void:
	var event := base_event as AbilityUsedDomainEvent
	var executor: Variant = await self._play_strike_lead_in(
		self.PRECISION_STRIKE_EXECUTOR, event.source_id, event.target
	)
	if executor == null:
		return
	await self._play_precision_strike_impact(executor, event, events)


func _present_spawn_at(position: Vector2i, events: Array[BoardDomainEvent]) -> void:
	for candidate: BoardDomainEvent in events:
		var spawn_event := candidate as UnitSpawnedDomainEvent
		if spawn_event != null and spawn_event.position == position:
			self._play_spawn(spawn_event, events)
			self._handled_events[candidate] = true


func _consume_destroyed_positions(positions: Array[Vector2i], events: Array[BoardDomainEvent]) -> void:
	for candidate: BoardDomainEvent in events:
		var destroyed := candidate as UnitDestroyedDomainEvent
		if destroyed != null and positions.has(destroyed.position):
			self._play_unit_audio(destroyed.template_key, "die")
			self._handled_events[candidate] = true


func _present_tile_damage_consequences(events: Array[BoardDomainEvent]) -> void:
	for candidate: BoardDomainEvent in events:
		if candidate is TileDamagedEvent:
			self._play_tile_damage(candidate, events)
			self._handled_events[candidate] = true


func _place_unit(unit: BaseUnit, position: Vector2i) -> void:
	var world_position: Vector3 = self.board.map.map_to_local(position)
	world_position.y = self.board.map.GROUND_HEIGHT
	unit.position = world_position


func _play_unit_audio(template_key: String, cue: String) -> void:
	self._play_unit_resource_audio(self.board.map.templates.get_template_source(template_key) as UnitResource, cue)


func _play_unit_resource_audio(resource: UnitResource, cue: String) -> void:
	if resource == null or not resource.audio_streams.has(cue):
		return
	var bus: StringName = self.UNIT_AUDIO_BUSES.get(cue, &"Units")
	self.board.audio.play_stream(resource.audio_streams[cue], bus)


func _refresh_unit_views() -> void:
	for tile: MapTile in self.board.map.model.tiles.values():
		if tile.unit.is_present():
			tile.unit.tile.refresh_state_view()
