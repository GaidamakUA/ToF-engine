extends Node3D
class_name BoardView

signal presentation_finished
signal command_impact

@onready var map: Map = $"map"
@onready var ui: Ui = $"ui"

@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var switcher: SceneSwitcherService = SceneSwitcher as SceneSwitcherService
@onready var match_setup: MatchSetupData = MatchSetup as MatchSetupData
@onready var settings: SettingsService = Settings as SettingsService
@onready var campaign: CampaignService = Campaign as CampaignService
@onready var saves_manager: SavesManagerService = SavesManager as SavesManagerService

var board_model: BoardModel
var presenter: BoardPresenter
var state: State
var radial_abilities: RadialAbilities
var abilities: Abilities
var events: Events
var scripting: Scripting
var ai: Ai
var board_animation_player: BoardAnimationPlayer


var selected_tile: MapTile:
    get:
        if self.presenter.selected_position == null:
            return null
        return self.map.model.get_tile(self.presenter.selected_position)
    set(value):
        if value == null:
            self.presenter.clear_selection()
        else:
            self.presenter.select_position(value.position)
var active_ability: Ability:
    get:
        return self.presenter.active_ability
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

func _init() -> void:
    self.board_model = BoardModel.new()
    self.presenter = BoardPresenter.new(self.board_model, self)
    self.state = self.board_model._state
    self.radial_abilities = RadialAbilities.new()
    self.events = self.board_model.events
    self.scripting = self.board_model.scripting
    self.abilities = self.board_model.abilities
    self.ai = Ai.new(self)


func _ready() -> void:
    self.board_animation_player = BoardAnimationPlayer.new(self)
    self.add_child(self.board_animation_player)
    self.set_up_ui()
    self.set_up_map()
    self.board_model.set_map_model(self.map.model)
    self.set_up_board()
    _ready_start()


func _ready_start() -> void:
    if self.match_setup.restore_save_id == null:
        self.match_setup.store_setup()
        self.board_model.start_match()
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
    return not self.state.is_current_player_ai() and not self.presenter.is_presenting()


func _physics_process(_delta: float) -> void:
    self.hover_tile()


func hover_tile() -> void:
    if not _can_current_player_perform_actions():
        return

    if not self.ui.is_panel_open():
        var tile: MapTile = self.map.model.get_tile(self.map.tile_box_position)

        if tile != self.last_hover_tile or true:
            self.last_hover_tile = tile
            if tile == null:
                self.presenter.set_hover(null)
            else:
                self.presenter.set_hover(tile.position)

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
    self.board_model.load_scripts(self.map.model.scripts)
    self.start_music_track()

    for player_setup: Dictionary in self.match_setup.setup:
        var typed_player_setup: Dictionary[String, Variant]
        typed_player_setup.assign(player_setup)
        var side: String = String(typed_player_setup["side"])
        if side != self.map.templates.PLAYER_NEUTRAL:
            _add_player_to_state(typed_player_setup)

            var units: Array[BaseUnit] = self.map.model.get_player_units(side)
            for unit: BaseUnit in units:
                unit.team = self.state.get_player_team(side)

            var buildings: Array[BaseBuilding] = self.map.model.get_player_buildings(side)
            for building: BaseBuilding in buildings:
                building.team = self.state.get_player_team(side)
    self.state.register_heroes(self.map.model)
    self.board_model.turn_limit = self.match_setup.turn_limit
    self.board_model.time_limit = self.match_setup.time_limit
    self.board_model.publish_state()


func render_interaction(interaction: BoardPresenter) -> void:
    self.reset_unit_markers()
    if interaction.selected_position == null:
        self.selected_tile_marker.hide()
        return
    var tile: MapTile = self.map.model.get_tile(interaction.selected_position)
    if tile == null:
        return
    self.selected_tile_marker.show()
    var marker_position: Vector3 = self.map.map_to_local(tile.position)
    marker_position.y = self.selected_tile_marker.position.y
    self.selected_tile_marker.position = marker_position
    self.movement_markers.show_legal_moves_for_tile(tile, interaction.legal_moves)
    self.interaction_markers.show_legal_interactions(interaction.legal_interactions)
    if interaction.active_ability != null:
        var marker_colour: String = "green"
        if self.active_ability is ActiveUnitAbility:
            marker_colour = (self.active_ability as ActiveUnitAbility).marker_colour
        elif self.active_ability is ActiveHeroAbility:
            marker_colour = (self.active_ability as ActiveHeroAbility).marker_colour
        self.ability_markers.show_legal_targets(interaction.legal_ability_targets, marker_colour)


func present_command_lead_in(command: BoardCommand) -> void:
    await self.board_animation_player.play_lead_in(command)
    self.command_impact.emit()


func present_model_update(
    snapshot: BoardStateSnapshot,
    domain_events: Array[BoardDomainEvent],
    command: BoardCommand = null
) -> void:
    self.ui.update_resource_value(snapshot.match.players[snapshot.match.current_player].ap)
    var animation_events: Array[BoardDomainEvent] = []
    for event: BoardDomainEvent in domain_events:
        if event is ScriptPresentationEvent:
            if not animation_events.is_empty():
                await self.board_animation_player.play(animation_events, command)
                animation_events.clear()
            await self._present_script_request(event as ScriptPresentationEvent, snapshot)
        else:
            animation_events.append(event)
    await self.board_animation_player.play(animation_events, command)
    self.presentation_finished.emit()


func _present_script_request(event: ScriptPresentationEvent, snapshot: BoardStateSnapshot) -> void:
    if event is FocusPresentationEvent:
        var focus := event as FocusPresentationEvent
        var camera_zoom: Variant = null
        if focus.zoom >= 0:
            camera_zoom = focus.zoom
        self.map.move_camera_to_position_if_far_away(focus.position, 0, camera_zoom)
    elif event is LockPresentationEvent:
        var lock := event as LockPresentationEvent
        if lock.target == LockPresentationEvent.Target.STORY:
            self.map.camera.script_operated = lock.locked
        elif lock.locked:
            self.ui.show_cinematic_bars()
            self.map.camera.ai_operated = true
            self.map.hide_tile_box()
            self.presenter.clear_selection()
        else:
            self.ui.hide_cinematic_bars()
            self.map.camera.ai_operated = false
            self.map.show_tile_box()
    elif event is ObjectivesPresentationEvent:
        self.ui.objectives.clear()
        for index: int in range(snapshot.scenario.objectives.size()):
            if not snapshot.scenario.objectives[index].is_empty():
                self.ui.objectives.set_objective_slot(index, snapshot.scenario.objectives[index])
        self.ui.objectives.flash()
    elif event is MessagePresentationEvent:
        self._present_script_message(event as MessagePresentationEvent)
        await self.ui.story_dialog.dismissed
    elif event is DelayPresentationEvent:
        await self.get_tree().create_timer((event as DelayPresentationEvent).duration).timeout
    elif event is EndGamePresentationEvent:
        self.end_game((event as EndGamePresentationEvent).winning_side)
    elif event is TileEffectPresentationEvent:
        var effect := event as TileEffectPresentationEvent
        var tile: MapTile = self.map.model.get_tile(effect.position)
        if effect.kind == TileEffectPresentationEvent.Kind.SMOKE:
            self.smoke_a_tile(tile)
        else:
            self.bless_a_tile(tile)


func _present_script_message(event: MessagePresentationEvent) -> void:
    var portrait_source: MapObjectResource = null
    if not event.portrait_key.is_empty():
        portrait_source = self.map.templates.get_template_source(event.portrait_key)
    var actor: Dictionary[String, Variant] = {
        "portrait": event.portrait_key,
        "portrait_source": portrait_source,
        "portrait_material": null,
        "name": event.actor_name,
        "side": event.side,
    }
    var portrait_unit := portrait_source as UnitResource
    var portrait_colour: String = event.colour
    if portrait_colour.is_empty() and portrait_unit != null:
        portrait_colour = portrait_unit.side
    if not portrait_colour.is_empty():
        actor["portrait_material"] = self.map.templates.get_side_material(portrait_colour)
    self.ui.show_story_dialog(event.text, actor, event.font_size)
    if not event.sound_key.is_empty():
        self.audio.play(event.sound_key)


func _add_player_to_state(data: Dictionary[String, Variant]) -> void:
    self.board_model.add_player(
        String(data["type"]), String(data["side"]), bool(data["alive"]),
        data["team"], int(data.get("ap", 0)), data.get("peer_id")
    )


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
    self.presenter.end_turn()
    self.ui.reset_timer()
    self.call_deferred(&"start_turn")


func start_turn() -> void:
    await self.presenter.wait_until_idle()
    self.update_for_current_player()

    await _manage_cinematic_bars()

    if self._should_perform_hq_cam():
        if self._move_camera_to_hq():
            await self.get_tree().create_timer(1).timeout

    self.ui.update_resource_value(self.state.get_current_ap())
    self.ui.flash_start_end_card(self.state.get_current_side(), self.state.turn)

    _manage_ai_start()
    _manage_turn_timer()



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

    self.presenter.press_tile(tile_position)


func get_tile_at(tile_position: Vector2i) -> MapTile:
    return self.map.model.get_tile(tile_position)


func is_current_player_ai() -> bool:
    return self.state.is_current_player_ai()


func play_tile_selected_feedback() -> void:
    if self.selected_tile != null and not self.state.is_current_player_ai():
        self.audio.play("map_click")


func unselect_action() -> void:
    self.presenter.cancel_interaction()


func unselect_tile() -> void:
    self.presenter.clear_selection()


func clear_selection_view() -> void:
    self.reset_unit_markers()
    self.ability_markers.reset()
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
    self.presenter.cancel_targeting()


func clear_ability_view() -> void:
    self.ability_markers.reset()
    self.refresh_tile_selection()


func load_skirmish_map() -> void:
    self.map.loader.load_map_file(String(self.match_setup.map_name))


func load_campaign_map() -> void:
    self.map.loader.load_campaign_map(String(self.match_setup.campaign_name), self.match_setup.mission_no)
    self.match_setup.campaign_win = true


func update_for_current_player() -> void:
    self.map.set_tile_box_side(self.state.get_current_side())


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


func show_contextual_select(open_unit_abilities: bool = false) -> void:
    if self.selected_tile == null:
        return
    self._show_contextual_select_radial(open_unit_abilities)


func _show_contextual_select_radial(open_unit_abilities: bool) -> void:
    if self.selected_tile.unit.is_present():
        if open_unit_abilities and self.selected_tile.unit.tile.has_active_ability():
            self.toggle_radial_menu(self.selected_tile.unit.tile)
    if self.selected_tile.building.is_present():
        self.toggle_radial_menu(self.selected_tile.building.tile)


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


func explode_a_tile(tile: MapTile) -> void:
    var new_explosion: ExplosionFx = self._spawn_temporary_explosion_instance_on_tile(tile, 0.5)
    new_explosion.explode()


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


func cheat_capture() -> void:
    if not OS.is_debug_build():
        print("Not a debug build")
        return

    var tile: MapTile = self.map.model.get_tile(self.map.tile_box_position)

    if not tile.building.is_present():
        print("No building found")
        return

    self.board_model.set_building_side(tile.position, self.state.get_current_side())


func cheat_kill() -> void:
    if not OS.is_debug_build():
        print("Not a debug build")
        return

    var tile: MapTile = self.map.model.get_tile(self.map.tile_box_position)

    if not tile.unit.is_present():
        print("No unit found")
        return

    self.board_model.destroy_unit(tile.position)


func cheat_level_up() -> void:
    if not OS.is_debug_build():
        print("Not a debug build")
        return

    var tile: MapTile = self.map.model.get_tile(self.map.tile_box_position)

    if not tile.unit.is_present():
        print("No unit found")
        return

    self.board_model.level_up_unit(tile.position)


func activate_production_ability(args: Array) -> void:
    self.toggle_radial_menu()
    var ability: SpawnUnit = args[0] as SpawnUnit
    assert(ability != null)
    _activate_production_ability(ability)


func _activate_production_ability(ability: SpawnUnit) -> void:
    var building: BaseBuilding = self.selected_tile.building.tile
    var cost: int = ability.get_cost(building)
    cost = self.abilities.get_modified_cost(cost, ability.template_name, building)

    if self.state.can_current_player_afford(cost):
        self.presenter.start_targeting(self.selected_tile.position, ability)


func activate_ability(args: Array) -> void:
    var ability: Ability = args[0] as Ability
    var unit: BaseUnit = self.selected_tile.unit.tile
    assert(ability != null)
    if self.state.can_current_player_afford(ability.get_cost(unit)) and not unit.is_ability_on_cooldown(ability):
        self.toggle_radial_menu()
        _activate_ability(ability)


func _activate_ability(ability: Ability) -> void:
    self.reset_unit_markers()
    self.presenter.start_targeting(self.selected_tile.position, ability)


func remove_unit_hightlights() -> void:
    var side: String = self.state.get_current_side()
    var units: Array[BaseUnit] = self.map.model.get_player_units(side)

    for unit: BaseUnit in units:
        unit.remove_highlight()


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
        building = tile.building.tile
        assert(building != null)
        template_name = building.template_name
        new_side = building.side
    if tile.unit.is_present():
        unit = tile.unit.tile
        assert(unit != null)
        if unit.uses_metallic_material:
            material_type = self.map.templates.MATERIAL_METALLIC
        template_name = unit.template_name
        new_side = unit.side

    var tile_source: MapObjectResource = self.map.templates.get_template_source(template_name)
    var material: Material = self.map.templates.get_side_material(new_side, material_type) as Material
    self.ui.update_tile_highlight(tile_source, material)

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
        var unit: BaseUnit = tile.unit.tile
        assert(unit != null)

        if unit.uses_metallic_material:
            material_type = self.map.templates.MATERIAL_METALLIC
        template_name = unit.template_name
        new_side = unit.side

        var tile_source: MapObjectResource = self.map.templates.get_template_source(template_name)
        var material: Material = self.map.templates.get_side_material(new_side, material_type) as Material
        self.ui.show_unit_stats(unit, tile_source, material, self)
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
    self.board_model.restore_match(BoardStateSerializer.match_from_save_data(save_data))
    var camera_state: Array
    camera_state.assign(save_data["camera"])
    self.map.camera.restore_from_state(camera_state)
    var objectives_state: Array
    objectives_state.assign(save_data["objectives"])
    self.ui.objectives.restore_from_state(objectives_state)
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
    self.board_model.objectives.assign(objectives_state)
    self.board_model.set_map_model(self.map.model)
    self.board_model.publish_state()

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


func _undo_unit_move() -> void:
    self.presenter.undo_last_move()
