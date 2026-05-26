extends Node3D
class_name Board

const RETALIATION_DELAY: float = 0.1

@onready var map: Map = $"map"
@onready var ui: Ui = $"ui"

@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var switcher: SceneSwitcherService = SceneSwitcher as SceneSwitcherService
@onready var match_setup: MatchSetupData = MatchSetup as MatchSetupData
@onready var settings: SettingsService = Settings as SettingsService
@onready var campaign: CampaignService = Campaign as CampaignService
@onready var saves_manager: SavesManagerService = SavesManager as SavesManagerService

var state: State = State.new()
var radial_abilities: RadialAbilities = RadialAbilities.new()
var abilities: Abilities = Abilities.new(self)
var events: Events = Events.new()
var observers: Observers = Observers.new(self)
var scripting: Scripting = Scripting.new()
var ai: Ai = Ai.new(self)
var collateral: Collateral = Collateral.new(self)


var selected_tile: MapTile = null
var active_ability: Ability = null
var last_hover_tile: MapTile = null
@onready var selected_tile_marker: Node3D = $"marker_anchor/tile_marker"
@onready var movement_markers: MovementMarkers = $"marker_anchor/movement_markers"
@onready var interaction_markers: InteractionMarkers = $"marker_anchor/interaction_markers"
@onready var path_markers: PathMarkers = $"marker_anchor/path_markers"
@onready var ability_markers: AbilityMarkers = $"marker_anchor/ability_markers"
@onready var explosion_anchor: Node3D = $"marker_anchor"
@onready var explosion: Node3D = $"marker_anchor/explosion"

var explosion_template: PackedScene = preload("res://scenes/fx/explosion.tscn")
var projectile_template: PackedScene = preload("res://scenes/fx/projectile.tscn")

var ending_turn_in_progress: bool = false
var ending_turn_multiplier: int = 1
var initial_hq_cam_skipped: bool = false
var mouse_click_position: Variant = null

var last_unit_move: Dictionary[String, Variant] = {}


func _ready() -> void:
	self.set_up_ui()
	self.set_up_map()
	self.set_up_board()
	_ready_start()


func _ready_start() -> void:
	if self.match_setup.restore_save_id == null:
		self.match_setup.store_setup()
		self.start_turn()
	else:
		self.restore_saved_state()


func _input(event: InputEvent) -> void:
	if not get_window().has_focus():
		return

	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton

	if not self.ui.is_panel_open():
		if _can_current_player_perform_actions():
			if event.is_action_pressed("ui_accept"):
				self.select_tile(self.map.tile_box_position)

			if event.is_action_pressed("ui_cancel"):
				if mouse_button_event != null:
					self.mouse_click_position = mouse_button_event.position

			if event.is_action_released("ui_cancel"):
				if mouse_button_event == null or (self.mouse_click_position != null and mouse_button_event.position.distance_squared_to(self.mouse_click_position) < self.map.camera.MOUSE_MOVE_THRESHOLD):
					self.unselect_action()
				self.mouse_click_position = null

			if event.is_action_pressed("end_turn"):
				self.start_ending_turn()
			elif event.is_action_released("end_turn"):
				self.abort_ending_turn()

			if event.is_action_pressed("mouse_click") and mouse_button_event != null:
				self.mouse_click_position = mouse_button_event.position

			if event.is_action_released("mouse_click"):
				if mouse_button_event != null and self.mouse_click_position != null and mouse_button_event.position.distance_squared_to(self.mouse_click_position) < self.map.camera.MOUSE_MOVE_THRESHOLD:
					self.select_tile(self.map.tile_box_position)
				self.mouse_click_position = null

			if event.is_action_pressed("game_context"):
				self.audio.play("menu_click")
				self.open_context_panel()

			if event.is_action_pressed("undo_move"):
				self.audio.play("menu_click")
				self._undo_unit_move()

			if OS.is_debug_build():
				if event.is_action_pressed("cheat_capture"):
					self.audio.play("menu_click")
					self.cheat_capture()
				if event.is_action_pressed("cheat_kill"):
					self.audio.play("menu_click")
					self.cheat_kill()
				if event.is_action_pressed("cheat_level_up"):
					self.audio.play("menu_click")
					self.cheat_level_up()

		if event.is_action_pressed("editor_menu"):
			self.audio.play("menu_click")
			self.toggle_radial_menu()
	else:
		if self.ui.radial.is_visible() and not self.ui.is_popup_open():
			if event.is_action_pressed("ui_cancel"):
				self.audio.play("menu_back")
				self.toggle_radial_menu()

			if event.is_action_pressed("editor_menu"):
				self.audio.play("menu_click")
				self.toggle_radial_menu()

		if self.ui.unit_stats.is_visible():
			if event.is_action_pressed("ui_cancel") or event.is_action_pressed("editor_menu") or event.is_action_pressed("game_context"):
				self.close_context_panel()
		if self.ui.end_turn_confirm.is_visible():
			if event.is_action_pressed("ui_cancel"):
				self.close_end_turn_confirm_panel()


func _can_current_player_perform_actions() -> bool:
	return not self.state.is_current_player_ai()


func _physics_process(_delta: float) -> void:
	self.hover_tile()


func hover_tile() -> void:
	if not _can_current_player_perform_actions():
		return

	if not self.ui.is_panel_open():
		var tile: MapTile = self.map.model.get_tile(self.map.tile_box_position)

		if tile != self.last_hover_tile or true:
			self.last_hover_tile = tile

			self.update_tile_highlight(tile)

			self.path_markers.reset()
			if self.should_draw_move_path(tile):
				var path: Array[String] = self.movement_markers.get_path_to_tile(tile)
				self.path_markers.draw_path(path)


func set_up_ui() -> void:
	self.ui.settings_panel.bind_menu(self)
	self.ui.hover_menu.board = self
	self.ui.unit_stats.board = self
	self.ui.end_turn_confirm.board = self
	self.ui.summary.board = self
	self.ui.radial.close_requested.connect(self.toggle_radial_menu)

	self.ui.edge_pan_left.mouse_entered.connect(self.map.camera._on_edge_pan.bind([1, null]))
	self.ui.edge_pan_left.mouse_exited.connect(self.map.camera._on_edge_pan.bind([0, null]))

	self.ui.edge_pan_right.mouse_entered.connect(self.map.camera._on_edge_pan.bind([-1, null]))
	self.ui.edge_pan_right.mouse_exited.connect(self.map.camera._on_edge_pan.bind([0, null]))

	self.ui.edge_pan_top.mouse_entered.connect(self.map.camera._on_edge_pan.bind([null, 1]))
	self.ui.edge_pan_top.mouse_exited.connect(self.map.camera._on_edge_pan.bind([null, 0]))

	self.ui.edge_pan_bottom.mouse_entered.connect(self.map.camera._on_edge_pan.bind([null, -1]))
	self.ui.edge_pan_bottom.mouse_exited.connect(self.map.camera._on_edge_pan.bind([null, 0]))

	self.ui.turn_timer.turn_timeout.connect(_timer_end_turn)


func set_up_map() -> void:
	self.map.builder.enable_health = true
	if self.match_setup.campaign_name != null:
		self.load_campaign_map()
	else:
		self.load_skirmish_map()
	self.map.hide_invisible_tiles()


func set_up_board() -> void:
	self.ui.objectives.clear()
	self.scripting.ingest_scripts(self, self.map.model.scripts)
	self.start_music_track()

	var index: int = 0
	for player_setup: Dictionary in self.match_setup.setup:
		var typed_player_setup: Dictionary[String, Variant]
		typed_player_setup.assign(player_setup)
		var side: String = String(typed_player_setup["side"])
		if side != self.map.templates.PLAYER_NEUTRAL:
			_add_player_to_state(typed_player_setup)
			self.state.add_player_ap(index, int(typed_player_setup["ap"]))

			self.state.set_player_team(side, self.state.get_player_team(side))

			var units: Array[BaseUnit] = self.map.model.get_player_units(side)
			for unit: BaseUnit in units:
				unit.team = self.state.get_player_team(side)

			var buildings: Array[BaseBuilding] = self.map.model.get_player_buildings(side)
			for building: BaseBuilding in buildings:
				building.team = self.state.get_player_team(side)

			index += 1
	self.state.register_heroes(self.map.model)


func _add_player_to_state(data: Dictionary[String, Variant]) -> void:
	self.state.add_player(String(data["type"]), String(data["side"]), bool(data["alive"]), data["team"])


func start_music_track() -> void:
	var tracks: int = 6

	if self.map.model.metadata.has("track"):
		self.audio.track(String(self.map.model.metadata["track"]))
	else:
		self.audio.track("soundtrack_" + str((randi() % tracks) + 1))


func check_end_turn() -> void:
	if self.state.has_player_moved:
		self.end_turn()
	else:
		self.show_end_turn_confirm_panel()


func end_turn() -> void:
	if not self.state.is_current_player_ai():
		self.perform_autosave()

	if self.ui.radial.is_visible():
		self.toggle_radial_menu()
	_end_turn()


func _end_turn() -> void:
	self.unselect_tile()
	self.state.switch_to_next_player()
	self.ui.reset_timer()
	self.call_deferred(&"start_turn")


func start_turn() -> void:
	if self.match_setup.turn_limit > 0 and self.state.turn > self.match_setup.turn_limit:
		self.end_game("none")
		return
	self.update_for_current_player()

	await _manage_cinematic_bars()

	if self._should_perform_hq_cam():
		if self._move_camera_to_hq():
			await self.get_tree().create_timer(1).timeout

	self.replenish_unit_actions()
	self.gain_building_ap()
	self.ui.update_resource_value(self.state.get_current_ap())
	self.ui.flash_start_end_card(self.state.get_current_side(), self.state.turn)

	_manage_ai_start()
	_manage_turn_timer()

	self.events.emit_turn_started(self.state.turn, self.state.current_player)


func _manage_cinematic_bars() -> void:
	if self.state.is_current_player_ai():
		if not self.ui.cinematic_bars.is_extended:
			self.ui.show_cinematic_bars()
			await self.get_tree().create_timer(0.25).timeout
	else:
		if self.ui.cinematic_bars.is_extended:
			self.ui.hide_cinematic_bars()


func _manage_ai_start() -> void:
	if self.state.is_current_player_ai():
		self.map.camera.ai_operated = true
		self.map.hide_tile_box()
		self.ai.run()
	else:
		self.map.camera.ai_operated = false
		self.map.show_tile_box()


func _manage_turn_timer() -> void:
	if not self.state.is_current_player_ai() and self.match_setup.time_limit > 0:
		self.ui.start_turn_timer(self.match_setup.time_limit)


func select_tile(tile_position: Vector2i) -> void:
	if self.map.camera.camera_in_transit or self.map.camera.script_operated:
		return

	if self.ui.hover_menu.hover_stack > 0:
		return

	var tile: MapTile = self.map.model.get_tile(tile_position)
	if tile == null:
		return

	var current_player: Dictionary[String, Variant]
	current_player.assign(self.state.get_current_player())
	var open_unit_abilities: bool = false

	if self.active_ability != null:
		if self.ability_markers.marker_exists(tile_position) or self.state.is_current_player_ai():
			set_last_unit_move(null)
			self.execute_active_ability(tile)
		else:
			self.unselect_tile()

	elif tile.is_selectable(String(current_player["side"])):
		if self.selected_tile == tile:
			open_unit_abilities = true
		self.selected_tile = tile
		self.show_contextual_select(open_unit_abilities)

	elif self.selected_tile != null:
		if self.selected_tile.unit.is_present():
			if self.can_move_to_tile(tile):
				set_last_unit_move(null)
				self.move_unit(self.selected_tile, tile)
				self.selected_tile = tile
				self.show_contextual_select()

			elif self.selected_tile.is_neighbour(tile) && tile.can_unit_interact(self.selected_tile.unit.tile) && self.state.can_current_player_afford(1):
				set_last_unit_move(null)
				self.handle_interaction(tile)

			else:
				self.unselect_tile()

		else:
			self.unselect_tile()

	self.hover_tile()

	if self.selected_tile != null and not self.state.is_current_player_ai():
		self.audio.play("map_click")


func unselect_action() -> void:
	if self.active_ability != null:
		self.cancel_ability()
	else:
		self.unselect_tile()


func unselect_tile() -> void:
	self.selected_tile = null
	self.reset_unit_markers()
	self.cancel_ability()
	self.selected_tile_marker.hide()


func refresh_tile_selection() -> void:
	if self.selected_tile != null:
		var selected_position: Vector2i = self.selected_tile.position
		self.unselect_tile()
		self.call_deferred(&"_reselect_tile", selected_position)


func _reselect_tile(tile_position: Vector2i) -> void:
	self.select_tile(tile_position)


func reset_unit_markers() -> void:
	self.movement_markers.reset()
	self.interaction_markers.reset()
	self.path_markers.reset()


func cancel_ability() -> void:
	self.active_ability = null
	self.ability_markers.reset()
	self.refresh_tile_selection()


func load_skirmish_map() -> void:
	self.map.loader.load_map_file(String(self.match_setup.map_name))


func load_campaign_map() -> void:
	self.map.loader.load_campaign_map(String(self.match_setup.campaign_name), self.match_setup.mission_no)
	self.match_setup.campaign_win = true


func update_for_current_player() -> void:
	var current_player: Dictionary[String, Variant]
	current_player.assign(self.state.get_current_player())
	self.map.set_tile_box_side(String(current_player["side"]))


func toggle_radial_menu(context_object: Variant = null) -> void:
	if self.map.camera.script_operated:
		return

	if self.radial_abilities.is_object_without_abilities(self, context_object):
		return

	if not self.ui.is_radial_open():
		self.setup_radial_menu(context_object)
	else:
		self.map.camera.force_stick_reset()
		self.ui.hide_objectives()

	# this might look odd, but is_visible does not change until the next frame after show/hide
	if not self.map.camera.ai_operated:
		if self.ui.radial.is_visible() and not self.state.is_current_player_ai():
			self.map.camera.paused = false
		elif not self.ui.radial.is_visible():
			self.map.camera.paused = true

	if self.ui.radial.is_visible():
		self.ai._ai_paused = false
	elif not self.ui.radial.is_visible():
		self.ai._ai_paused = true

	self.ui.toggle_radial()

	if _can_current_player_perform_actions():
		self.map.tile_box.set_visible(not self.map.tile_box.is_visible())


func setup_radial_menu(context_object: Variant = null) -> void:
	self.ui.radial.clear_fields()
	if context_object == null:
		self.ui.radial.set_field(self.ui.icons.back.instantiate(), "TR_RES_MISS", 0, self, &"_restart_board")
		self.ui.radial.set_field(self.ui.icons.disk.instantiate(), "TR_SAVE_LOAD", 2, self, &"open_saves")
		if self.state.is_current_player_ai():
			self.ui.radial.set_field_disabled(2, "X")
		else:
			self.ui.radial.clear_field_disabled(2)
		self.ui.radial.set_field(self.ui.icons.quit.instantiate(), "TR_MAIN_MENU", 4, self, &"main_menu")
		self.ui.radial.set_field(self.ui.icons.cross.instantiate(), "TR_CLOSE", 6, self, &"toggle_radial_menu")
		self.ui.radial.set_field(self.ui.icons.cog.instantiate(), "TR_SETTINGS", 7, self, &"open_settings")
		self.ui.show_objectives()
	else:
		_setup_radial_menu_with_abilities(context_object)


func _setup_radial_menu_with_abilities(context_object: Variant) -> void:
	self.radial_abilities.fill_radial_with_abilities(self, self.ui.radial, context_object)


func place_selection_marker() -> void:
	self.selected_tile_marker.show()
	var new_position: Vector3 = self.selected_tile_marker.get_position()
	var placement: Vector3 = self.map.map_to_local(self.selected_tile.position)
	placement.y = new_position.y
	self.selected_tile_marker.set_position(placement)


func show_unit_movement_markers() -> void:
	self.movement_markers.show_unit_movement_markers_for_tile(self.selected_tile, self.state.get_current_ap())


func show_unit_interaction_markers() -> void:
	self.interaction_markers.show_interaction_markers_for_tile(self.selected_tile, self.state.get_current_ap())


func show_contextual_select(open_unit_abilities: bool = false) -> void:
	self.place_selection_marker()
	self.movement_markers.reset()
	self.interaction_markers.reset()
	self.path_markers.reset()

	if self.selected_tile.unit.is_present():
		self.show_unit_movement_markers()
		self.show_unit_interaction_markers()
	_show_contextual_select_radial(open_unit_abilities)


func _show_contextual_select_radial(open_unit_abilities: bool) -> void:
	if self.selected_tile.unit.is_present():
		if open_unit_abilities and self.selected_tile.unit.tile.has_active_ability():
			self.toggle_radial_menu(self.selected_tile.unit.tile)
	if self.selected_tile.building.is_present():
		self.toggle_radial_menu(self.selected_tile.building.tile)


func move_unit(source_tile: MapTile, destination_tile: MapTile) -> void:
	var raw_move_cost: Variant = self.movement_markers.get_tile_cost(destination_tile)
	assert(raw_move_cost != null)
	var move_cost: int = int(raw_move_cost)
	if not state.is_current_player_ai():
		set_last_unit_move({
			"source": source_tile,
			"destination": destination_tile,
			"cost": move_cost
		})
	else:
		set_last_unit_move(null)
	destination_tile.unit.set_tile(source_tile.unit.tile)
	source_tile.unit.release()
	self.use_current_player_ap(move_cost)
	destination_tile.unit.tile.use_move(move_cost)

	self.reset_unit_position(source_tile, destination_tile.unit.tile)
	self.update_unit_position(destination_tile)

	self.events.emit_unit_moved(destination_tile.unit.tile, source_tile, destination_tile)


func update_unit_position(tile: MapTile) -> void:
	var path: Array[String] = self.movement_markers.get_path_to_tile(tile)
	var movement_path: Array[String] = self.path_markers.convert_path_to_directions(path)
	var unit: BaseUnit = tile.unit.tile as BaseUnit
	assert(unit != null)

	unit.animate_path(movement_path)


func reset_unit_position(tile: MapTile, unit: BaseUnit) -> void:
	unit.stop_animations()
	var world_position: Vector3 = self.map.map_to_local(tile.position)
	var old_position: Vector3 = unit.get_position()
	world_position.y = old_position.y
	unit.set_position(world_position)


func can_move_to_tile(tile: MapTile) -> bool:
	var move_cost: Variant = self.movement_markers.get_tile_cost(tile)
	if move_cost != null and int(move_cost) > 0 and tile.can_acommodate_unit(self.selected_tile.unit.tile):
		return true
	return false


func should_draw_move_path(tile: MapTile) -> bool:
	if self.selected_tile != null:
		if self.selected_tile.unit.is_present():
			if self.can_move_to_tile(tile):
				return true
	return false


func handle_interaction(tile: MapTile) -> void:
	if self.selected_tile != null:
		if self.selected_tile.unit.is_present():
			if tile.unit.is_present():
				self.battle(self.selected_tile, tile)
				self.use_current_player_ap(1)
				if self.selected_tile != null && self.selected_tile.unit.is_present():
					self.show_contextual_select()
			if tile.building.is_present():
				self.capture(self.selected_tile, tile)
				self.use_current_player_ap(1)
				if self.selected_tile != null && self.selected_tile.unit.is_present():
					self.show_contextual_select()


func battle(attacker_tile: MapTile, defender_tile: MapTile) -> void:
	var attacker: BaseUnit = attacker_tile.unit.tile as BaseUnit
	var defender: BaseUnit = defender_tile.unit.tile as BaseUnit
	assert(attacker != null)
	assert(defender != null)

	attacker.use_move(1)
	attacker.use_attack()

	self.reset_unit_position(attacker_tile, attacker)

	attacker.rotate_unit_to_direction(attacker_tile.get_direction_to_neighbour(defender_tile))

	defender.receive_damage(attacker.get_attack())
	attacker.sfx_effect("attack")
	attacker.sfx_effect("hit")

	if defender.is_alive():
		defender.show_explosion()

		if defender.can_attack(attacker) && defender.has_moves():
			defender.use_all_moves()
			attacker.receive_damage(defender.get_attack())
			await self.get_tree().create_timer(self.RETALIATION_DELAY).timeout
			defender.rotate_unit_to_direction(defender_tile.get_direction_to_neighbour(attacker_tile))

			defender.sfx_effect("attack")
			defender.sfx_effect("hit")

			if attacker.is_alive():
				attacker.show_explosion()
				self.events.emit_unit_attacked(defender, attacker)
			else:
				var attacker_id: int = attacker.get_instance_id()
				var attacker_type: String = attacker.template_name
				var attacker_side: String = attacker.side

				self.unselect_tile()
				self.destroy_unit_on_tile(attacker_tile)
				self.events.emit_unit_destroyed(defender, attacker_id, attacker_type, attacker_side)

		self.events.emit_unit_attacked(attacker, defender)
	else:
		var defender_id: int = defender.get_instance_id()
		var defender_type: String = defender.template_name
		var defender_side: String = defender.side

		self.destroy_unit_on_tile(defender_tile)
		self.events.emit_unit_destroyed(attacker, defender_id, defender_type, defender_side)


func destroy_unit_on_tile(tile: MapTile, skip_explosion: bool = false) -> void:
	var unit: BaseUnit = tile.unit.tile as BaseUnit
	assert(unit != null)

	if unit.unit_class == "hero":
		var hero: HeroUnit = tile.unit.tile as HeroUnit
		assert(hero != null)
		self.state.clear_hero_for_side(unit.side, hero)

	if not skip_explosion:
		self.explode_a_tile(tile, true)
		_generate_collateral_damage(tile)
		if bool(self.settings.get_option("cam_shake")):
			self.map.camera.shake()
	tile.unit.clear()


func _generate_collateral_damage(tile: MapTile) -> Dictionary[String, Variant]:
	return {
		"collateral": self.collateral.generate_collateral(tile),
		"damage": self.collateral.damage_tile(tile)
	}


func explode_a_tile(tile: MapTile, grab_sfx: bool = false) -> void:
	var new_explosion: ExplosionFx = self._spawn_temporary_explosion_instance_on_tile(tile, 0.5)
	new_explosion.explode()
	if grab_sfx:
		new_explosion.grab_sfx_effect(tile.unit.tile)


func smoke_a_tile(tile: MapTile) -> void:
	var new_explosion: ExplosionFx = self._spawn_temporary_explosion_instance_on_tile(tile, 0.5)
	new_explosion.puff_some_smoke()


func bless_a_tile(tile: MapTile) -> void:
	var new_explosion: ExplosionFx = self._spawn_temporary_explosion_instance_on_tile(tile, 1.0)
	new_explosion.rain_bless()


func heal_a_tile(tile: MapTile) -> void:
	var new_explosion: ExplosionFx = self._spawn_temporary_explosion_instance_on_tile(tile, 1.0)
	new_explosion.rain_heal()


func _spawn_temporary_explosion_instance_on_tile(tile: MapTile, free_delay: float = 1.5) -> ExplosionFx:
	var explosion_position: Vector3 = self.map.map_to_local(tile.position)
	var new_explosion: ExplosionFx = self.explosion_template.instantiate() as ExplosionFx
	assert(new_explosion != null)
	self.explosion_anchor.add_child(new_explosion)
	new_explosion.set_position(Vector3(explosion_position.x, 0, explosion_position.z))
	self.destroy_explosion_with_delay(new_explosion, free_delay)

	return new_explosion


func capture(attacker_tile: MapTile, building_tile: MapTile) -> void:
	var attacker: BaseUnit = attacker_tile.unit.tile as BaseUnit
	var building: BaseBuilding = building_tile.building.tile as BaseBuilding
	assert(attacker != null)
	assert(building != null)

	var old_side: String = building.side

	attacker.use_all_moves()
	self.map.builder.set_building_side(building_tile.position, attacker.side, attacker.team)
	self.smoke_a_tile(building_tile)
	building.sfx_effect("capture")

	if building.require_crew and not self.abilities.can_intimidate_crew(attacker):
		await self.get_tree().create_timer(self.RETALIATION_DELAY).timeout
		self.smoke_a_tile(attacker_tile)
		attacker_tile.unit.clear()
		self.unselect_tile()

	self.events.emit_building_captured(building, old_side, attacker.side)


func cheat_capture() -> void:
	if not OS.is_debug_build():
		print("Not a debug build")
		return

	var tile: MapTile = self.map.model.get_tile(self.map.tile_box_position)

	if not tile.building.is_present():
		print("No building found")
		return

	var building: BaseBuilding = tile.building.tile as BaseBuilding
	assert(building != null)
	var old_side: String = building.side

	self.map.builder.set_building_side(tile.position, self.state.get_current_side(), self.state.get_current_team())
	self.smoke_a_tile(tile)
	building.sfx_effect("capture")
	self.events.emit_building_captured(building, old_side, self.state.get_current_side())


func cheat_kill() -> void:
	if not OS.is_debug_build():
		print("Not a debug build")
		return

	var tile: MapTile = self.map.model.get_tile(self.map.tile_box_position)

	if not tile.unit.is_present():
		print("No unit found")
		return

	var unit: BaseUnit = tile.unit.tile as BaseUnit
	assert(unit != null)
	var unit_id: int = unit.get_instance_id()
	var unit_type: String = unit.template_name
	var unit_side: String = unit.side

	self.destroy_unit_on_tile(tile)
	self.events.emit_unit_destroyed(null, unit_id, unit_type, unit_side)


func cheat_level_up() -> void:
	if not OS.is_debug_build():
		print("Not a debug build")
		return

	var tile: MapTile = self.map.model.get_tile(self.map.tile_box_position)

	if not tile.unit.is_present():
		print("No unit found")
		return

	var unit: BaseUnit = tile.unit.tile as BaseUnit
	assert(unit != null)
	unit.level_up()


func activate_production_ability(args: Array) -> void:
	self.toggle_radial_menu()
	var ability: SpawnUnit = args[0] as SpawnUnit
	assert(ability != null)
	_activate_production_ability(ability)


func _activate_production_ability(ability: SpawnUnit) -> void:
	var cost: int = ability.get_cost()
	cost = self.abilities.get_modified_cost(cost, ability.template_name, ability.source)

	if self.state.can_current_player_afford(cost):
		self.active_ability = ability
		if self.selected_tile != null:
			self.ability_markers.show_ability_markers_for_tile(ability, self.selected_tile)


func activate_ability(args: Array) -> void:
	var ability: Ability = args[0] as Ability
	assert(ability != null)
	if self.state.can_current_player_afford(ability.get_cost()) and not ability.is_on_cooldown():
		self.toggle_radial_menu()
		_activate_ability(ability)


func _activate_ability(ability: Ability) -> void:
	self.reset_unit_markers()
	self.active_ability = ability
	if self.selected_tile != null:
		self.ability_markers.show_ability_markers_for_tile(ability, self.selected_tile)
		ability.active_source_tile = self.selected_tile


func execute_active_ability(tile: MapTile) -> void:
	assert(self.active_ability != null)
	self.abilities.execute_ability(self.active_ability, tile)
	self.cancel_ability()


func remove_unit_hightlights() -> void:
	var current_player: Dictionary[String, Variant]
	current_player.assign(self.state.get_current_player())
	var side: String = String(current_player["side"])
	var units: Array[BaseUnit] = self.map.model.get_player_units(side)

	for unit: BaseUnit in units:
		unit.remove_highlight()


func replenish_unit_actions() -> void:
	var current_player: Dictionary[String, Variant]
	current_player.assign(self.state.get_current_player())
	var side: String = String(current_player["side"])
	var units: Array[BaseUnit] = self.map.model.get_player_units(side)

	for unit: BaseUnit in units:
		unit.clear_modifiers()
		self.abilities.apply_passive_modifiers(unit)
		unit.replenish_moves()
		unit.ability_cd_tick_down()
		unit.team = self.state.get_player_team(side)


func gain_building_ap() -> void:
	var ap_sum: int = 0
	var current_player: Dictionary[String, Variant]
	current_player.assign(self.state.get_current_player())
	var side: String = String(current_player["side"])
	var buildings: Array[BaseBuilding] = self.map.model.get_player_buildings(side)

	for building: BaseBuilding in buildings:
		ap_sum += self.abilities.get_modified_ap_gain(building.ap_gain, building)
		if building.ap_gain > 0:
			building.animate_coin()

		building.team = self.state.get_player_team(side)

	self.add_current_player_ap(ap_sum)


func add_current_player_ap(ap_sum: int) -> void:
	self.state.add_current_player_ap(ap_sum)
	self.ui.update_resource_value(self.state.get_current_ap())


func use_current_player_ap(value: int) -> void:
	self.state.use_current_player_ap(value)
	self.ui.update_resource_value(self.state.get_current_ap())
	if self.state.get_current_ap() == 0 and bool(self.settings.get_option("notify_ap_spent")) and not self.state.is_current_player_ai():
		self.ui.ap_depleted.flash()


func update_tile_highlight(tile: MapTile) -> void:
	if not tile.building.is_present() and not tile.unit.is_present():
		self.ui.clear_tile_highlight()
		return

	if not _can_current_player_perform_actions() or self.map.camera.ai_operated:
		return

	var template_name: String
	var new_side: String
	var material_type: String = self.map.templates.MATERIAL_NORMAL
	var building: BaseBuilding = null
	var unit: BaseUnit = null

	if tile.building.is_present():
		building = tile.building.tile as BaseBuilding
		assert(building != null)
		template_name = building.template_name
		new_side = building.side
	if tile.unit.is_present():
		unit = tile.unit.tile as BaseUnit
		assert(unit != null)
		if unit.uses_metallic_material:
			material_type = self.map.templates.MATERIAL_METALLIC
		template_name = unit.template_name
		new_side = unit.side

	var new_tile: MapObject = self.map.templates.get_template(template_name)
	new_tile.set_side_material(self.map.templates.get_side_material(new_side, material_type))

	self.ui.update_tile_highlight(new_tile)

	if building != null:
		var ap_gain: int = building.ap_gain
		ap_gain = self.abilities.get_modified_ap_gain(ap_gain, building)
		self.ui.update_tile_highlight_building_panel(ap_gain)
	if unit != null:
		self.ui.update_tile_highlight_unit_panel(unit, self)


func open_context_panel() -> void:
	var tile: MapTile = self.map.model.get_tile(self.map.tile_box_position)
	self._open_context_panel_for_tile(tile)


func _open_context_panel_for_tile(tile: MapTile) -> void:
	if tile != null:
		if not tile.unit.is_present():
			return

		var template_name: String
		var new_side: String
		var material_type: String = self.map.templates.MATERIAL_NORMAL
		var unit: BaseUnit = tile.unit.tile as BaseUnit
		assert(unit != null)

		if unit.uses_metallic_material:
			material_type = self.map.templates.MATERIAL_METALLIC
		template_name = unit.template_name
		new_side = unit.side

		var tile_preview: MapObject = self.map.templates.get_template(template_name)
		tile_preview.set_side_material(self.map.templates.get_side_material(new_side, material_type))

		self.ui.show_unit_stats(unit, tile_preview, self)
		self.map.camera.paused = true


func _open_context_panel_for_active_tile() -> void:
	if self.selected_tile != null:
		self._open_context_panel_for_tile(self.selected_tile)


func close_context_panel() -> void:
	self.audio.play("menu_back")
	self.ui.hide_unit_stats()
	self.map.camera.paused = false


func show_end_turn_confirm_panel() -> void:
	self.map.camera.paused = true
	self.ui.end_turn_confirm.show_panel()


func close_end_turn_confirm_panel() -> void:
	self.map.camera.paused = false
	self.ui.end_turn_confirm.hide()


func end_game(winner: Variant) -> void:
	self.map.camera.paused = true
	self.ai.abort()
	self.ui.hide_resource()
	self.ui.clear_tile_highlight()
	self.map.tile_box.hide()
	self._signal_winner(winner)
	self.ui.show_summary(String(winner))


func start_ending_turn() -> void:
	var step_delay: float = 0.1
	var step_value: int = 2
	var step_max: int = 30
	self.ending_turn_in_progress = true
	self.ui.show_end_turn()

	self.ending_turn_multiplier = 1
	var ending_multiplier_setting: Variant = self.settings.get_option("end_turn_speed")
	if ending_multiplier_setting == "x2":
		self.ending_turn_multiplier = 2
	if ending_multiplier_setting == "x4":
		self.ending_turn_multiplier = 4

	var index: int = 0

	while index * step_value <= step_max and self.ending_turn_in_progress:
		self.ui.update_end_turn_progress(index * step_value)
		await self.get_tree().create_timer(step_delay).timeout
		index += self.ending_turn_multiplier

	if self.ending_turn_in_progress:
		self.abort_ending_turn()
		self.call_deferred(&"check_end_turn")


func abort_ending_turn() -> void:
	self.ending_turn_in_progress = false
	self.ui.hide_end_turn()


func main_menu() -> void:
	self.ai.abort()
	self.switcher.main_menu()


func destroy_explosion_with_delay(explosion_object: Node, delay: float) -> void:
	await self.get_tree().create_timer(delay).timeout
	explosion_object.queue_free()


func _signal_winner(winning_side: Variant) -> void:
	var side: String = String(winning_side)
	if self.match_setup.campaign_win and self.state.is_player_human(side):
		self.campaign.update_campaign_progress(String(self.match_setup.campaign_name), self.match_setup.mission_no)
		self.match_setup.has_won = true


func shoot_projectile(source_tile: MapTile, destination_tile: MapTile, tween_time: float = 0.5) -> void:
	var new_projectile: ProjectileFx = self._spawn_temporary_projectile_instance_on_tile(source_tile)
	var tile_position: Vector3 = self.map.map_to_local(destination_tile.position)
	new_projectile.shoot_at_position(Vector3(tile_position.x, 0, tile_position.z), tween_time)


func lob_projectile(source_tile: MapTile, destination_tile: MapTile, tween_time: float = 0.5) -> void:
	var new_projectile: ProjectileFx = self._spawn_temporary_projectile_instance_on_tile(source_tile)
	var tile_position: Vector3 = self.map.map_to_local(destination_tile.position)
	new_projectile.lob_at_position(Vector3(tile_position.x, 0, tile_position.z), tween_time)


func _spawn_temporary_projectile_instance_on_tile(tile: MapTile) -> ProjectileFx:
	var tile_position: Vector3 = self.map.map_to_local(tile.position)
	var new_projectile: ProjectileFx = self.projectile_template.instantiate() as ProjectileFx
	assert(new_projectile != null)
	self.explosion_anchor.add_child(new_projectile)
	new_projectile.set_position(Vector3(tile_position.x, 0, tile_position.z))

	return new_projectile


func _move_camera_to_hq() -> bool:
	var hq_position: Variant = self.map.model.get_player_bunker_position(self.state.get_current_side())

	if hq_position != null:
		self.map.move_camera_to_position(hq_position)
		return true

	return false


func _should_perform_hq_cam() -> bool:
	if not self.state.is_current_player_ai() and bool(self.settings.get_option("hq_cam")):
		if self.map.model.metadata.has("skip_initial_hq_cam") and not self.initial_hq_cam_skipped:
			self.initial_hq_cam_skipped = true
			return false
		return true
	return false


func _restart_board() -> void:
	if self.match_setup.restore_save_id != null:
		self.match_setup.restore_save_id = null
		self.match_setup.restore_setup()
	self.match_setup.has_won = false
	self.switcher.board()
	self.audio.play("menu_click")


func open_saves() -> void:
	if self.state.is_current_player_ai():
		return
	self.ui.saves.board = self
	self.ui.hide_radial()
	self.ui.hide_objectives()
	self.ui.show_saves()

	self.ui.saves.bind_cancel(self, &"close_saves")


func close_saves() -> void:
	self.ui.hide_saves()
	self.map.camera.paused = false
	self.ai._ai_paused = false

	if not self.state.is_current_player_ai():
		self.map.tile_box.set_visible(true)


func restore_saved_state() -> void:
	assert(self.match_setup.restore_save_id != null)
	var save_data: Dictionary[String, Variant]
	save_data.assign(self.saves_manager.get_save_data(int(self.match_setup.restore_save_id)))
	_restore_saved_state(save_data)


func _restore_saved_state(save_data: Dictionary[String, Variant]) -> void:
	# restore basic state elements
	self.state.turn = int(save_data["turn"])
	self.state.current_player = int(save_data["active_player"])
	var camera_state: Array
	camera_state.assign(save_data["camera"])
	self.map.camera.restore_from_state(camera_state)
	var objectives_state: Array
	objectives_state.assign(save_data["objectives"])
	self.ui.objectives.restore_from_state(objectives_state)
	if save_data.has("player_moved"):
		self.state.has_player_moved = bool(save_data["player_moved"])
	if save_data.has("turn_limit"):
		self.match_setup.turn_limit = int(save_data["turn_limit"])
	if save_data.has("time_limit"):
		self.match_setup.time_limit = int(save_data["time_limit"])

	# restore tiles state
	self.map.model.wipe_all_units()
	var tiles_data: Dictionary
	tiles_data.assign(save_data["tiles"])
	for tile_key: String in tiles_data.keys():
		var tile_data: Dictionary
		tile_data.assign(tiles_data[tile_key])
		self.map.builder.rebuild_tile(tile_key, tile_data)
	self.map.hide_invisible_tiles()
	self.state.register_heroes(self.map.model)

	# restore triggers
	var triggers: Dictionary[String, Variant]
	triggers.assign(save_data["triggers"])
	self.scripting.restore_from_state(triggers)

	# resume turn after state is loaded
	self.update_for_current_player()

	self.ui.update_resource_value(self.state.get_current_ap())
	self.ui.flash_start_end_card(self.state.get_current_side(), self.state.turn)

	self.map.camera.ai_operated = false
	self.map.show_tile_box()


func perform_autosave() -> void:
	self.ui.saves.board = self
	self.ui.saves.perform_autosave()


func open_settings() -> void:
	self.ui.hide_radial()
	self.ui.hide_objectives()
	self.ui.show_settings()


func close_settings() -> void:
	self.ui.hide_settings()
	self.map.camera.paused = false
	self.ai._ai_paused = false

	if not self.state.is_current_player_ai():
		self.map.tile_box.set_visible(true)


func _timer_end_turn() -> void:
	end_turn()


func set_last_unit_move(move: Variant) -> void:
	last_unit_move.clear()
	if move == null:
		return

	assert(move is Dictionary)
	last_unit_move.assign(move)


func _undo_unit_move() -> void:
	if not last_unit_move.is_empty():
		var source_tile: MapTile = last_unit_move["destination"] as MapTile
		var destination_tile: MapTile = last_unit_move["source"] as MapTile
		assert(source_tile != null)
		assert(destination_tile != null)
		var move_cost: int = int(last_unit_move["cost"])
		destination_tile.unit.set_tile(source_tile.unit.tile)
		source_tile.unit.release()
		self.state.add_current_player_ap(move_cost)
		self.ui.update_resource_value(self.state.get_current_ap())
		destination_tile.unit.tile.restore_move(move_cost)
		self.reset_unit_position(destination_tile, destination_tile.unit.tile)
		self.unselect_tile()
		set_last_unit_move(null)
