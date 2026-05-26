extends Control
class_name SkirmishPanel

@onready var map_list_service: MapManagerService = MapManager as MapManagerService
@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var switcher: SceneSwitcherService = SceneSwitcher as SceneSwitcherService
@onready var match_setup: MatchSetupData = MatchSetup as MatchSetupData
@onready var start_button: TextureButton = $"widgets/start_button"
@onready var player_panels: Array[SkirmishPlayerPanel] = [
	$"widgets/skirmish_player_0" as SkirmishPlayerPanel,
	$"widgets/skirmish_player_1" as SkirmishPlayerPanel,
	$"widgets/skirmish_player_2" as SkirmishPlayerPanel,
	$"widgets/skirmish_player_3" as SkirmishPlayerPanel,
]

@onready var minimap: MinimapView = $"widgets/minimap"
@onready var animations: AnimationPlayer = $"animations"
@onready var turn_config: TurnConfigView = $"widgets/TurnConfig"

var hq_templates: Array[String] = [
	"modern_hq",
	"steampunk_hq",
	"futuristic_hq",
	"feudal_hq",
]

var main_menu: MainMenu
var map_name: String = ""
var cache: Dictionary[String, Dictionary] = {}

func bind_menu(menu: MainMenu) -> void:
	self.main_menu = menu

func _ready() -> void:
	self.set_process_input(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed('editor_menu'):
		self._on_back_button_pressed()

func show_panel(selected_map_name: String) -> void:
	self.animations.play("show")
	self.set_process_input(true)
	self.fill_map_data(selected_map_name)
	self.map_name = selected_map_name
	self.turn_config.reset()
	await self.get_tree().create_timer(0.1).timeout
	self.start_button.grab_focus()


func hide_panel() -> void:
	self.animations.play("hide")
	self.set_process_input(false)

func fill_map_data(fill_name: String) -> void:
	self.minimap.fill_minimap(fill_name)
	$"widgets/minimap/map_name/label".set_text(fill_name)
	self._fill_player_panels(fill_name)

func _hide_player_panels() -> void:
	for panel: SkirmishPlayerPanel in self.player_panels:
		panel.hide()
		panel._reset_labels()

func _fill_player_panels(fill_name: String) -> void:
	self._hide_player_panels()

	var sides: Dictionary = self._gather_player_sides(self._get_map_data(fill_name))

	var index: int = 0

	for side: Variant in sides:
		if index >= self.player_panels.size():
			continue
		self.player_panels[index].fill_panel(side)
		self.player_panels[index].show()
		index += 1

func _gather_player_sides(map_data: Dictionary) -> Dictionary:
	var sides: Dictionary = {}
	var side: Variant
	var key: String
	var tiles: Dictionary = map_data["tiles"]

	for y: int in range(self.map_list_service.MAX_MAP_SIZE):
		for x: int in range(self.map_list_service.MAX_MAP_SIZE):
			key = str(x) + "_" + str(y)
			if tiles.has(key):
				side = self._lookup_side(tiles[key])

				if side != null:
					sides[side] = side

	return sides

func _lookup_side(data: Dictionary) -> Variant:
	if data["building"]["tile"] != null:
		if data["building"]["tile"] in self.hq_templates:
			return data["building"]["side"]

	return null


func _on_start_button_pressed() -> void:
	self.audio.play("menu_click")

	self.match_setup.reset()
	self.match_setup.map_name = self.map_name
	self.match_setup.turn_limit = self.turn_config.turn_limit
	self.match_setup.time_limit = self.turn_config.time_limit

	for player: SkirmishPlayerPanel in self.player_panels:
		if player.side != null:
			self.match_setup.add_player(str(player.side), player.ap, player.type, true, player.team)

	self.switcher.board()


func _on_back_button_pressed() -> void:
	self.audio.play("menu_back")
	self.main_menu.close_skirmish()

func _get_map_data(fill_name: String) -> Dictionary:
	if self.cache.has(fill_name):
		return self.cache[fill_name]

	var map_data: Dictionary = self.map_list_service.get_map_data(fill_name)

	self.cache[fill_name] = map_data

	return map_data
