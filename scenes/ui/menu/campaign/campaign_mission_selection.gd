extends Control
class_name CampaignMissionSelectionPanel

@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var campaign: CampaignService = Campaign as CampaignService
@onready var match_setup: MatchSetupData = MatchSetup as MatchSetupData

@onready var animations: AnimationPlayer = $"animations"
@onready var back_button: TextureButton = $"widgets/back_button"
@onready var select_button: TextureButton = $"widgets/select_button"
@onready var prev_button: TextureButton = $"widgets/prev_button"
@onready var next_button: TextureButton = $"widgets/next_button"
@onready var medal: Node = $"widgets/medal"

@onready var zoom_in_button: TextureButton = $"widgets/zoom_in_button"
@onready var zoom_out_button: TextureButton = $"widgets/zoom_out_button"

@onready var title: Label = $"widgets/title"
@onready var mission_anchor: Control = $"widgets/map_viewport/missions_anchor"

@onready var base_map: Sprite2D = $"widgets/map_viewport/map"
@onready var override_map: Sprite2D = $"widgets/map_viewport/map_override"

@onready var campaign_viewport: SubViewport = $"widgets/map_viewport"
@onready var campaign_camera: Camera2D = $"widgets/map_viewport/camera"

var main_menu: MainMenu

var manifest: Dictionary = {}

var mission_marker_template: PackedScene = preload("res://scenes/ui/menu/campaign/mission_marker.tscn")
var mission_markers: Array[CampaignMissionMarker] = []
var selected_mission: int = 0

var _maps_cache: Dictionary[String, Texture2D] = {}
var _zoom_level: float = 1.0
var _zoom_limit: float = 1.0
var _zoom_step: float  = 0.1

func bind_menu(menu: MainMenu) -> void:
	self.main_menu = menu

func _ready() -> void:
	self.set_process_input(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed('editor_menu'):
		self._on_back_button_pressed()
	if event.is_action_pressed("ui_page_down"):
		self._on_next_button_pressed(false)
		self.select_button.grab_focus()
	if event.is_action_pressed("ui_page_up"):
		self._on_prev_button_pressed(false)
		self.select_button.grab_focus()

func _on_back_button_pressed() -> void:
	self.audio.play("menu_back")
	self.main_menu.close_campaign_mission_selection()

func _on_prev_button_pressed(do_grab: bool = true) -> void:
	if self._is_first_mission():
		return

	self.audio.play("menu_click")
	self._select_marker(self.selected_mission - 1)
	self._tween_camera_to_marker(self.selected_mission)
	if do_grab and self._is_first_mission():
		self.next_button.grab_focus()

func _on_next_button_pressed(do_grab: bool = true) -> void:
	if self._is_last_mission():
		return

	self.audio.play("menu_click")
	self._select_marker(self.selected_mission + 1)
	self._tween_camera_to_marker(self.selected_mission)
	if do_grab and self._is_last_mission():
		self.prev_button.grab_focus()

func _on_select_button_pressed() -> void:
	self.audio.play("menu_click")
	self.main_menu.open_campaign_mission(str(self.manifest["name"]), self.selected_mission)

func show_panel() -> void:
	self.animations.play("show")
	self.set_process_input(true)
	await self.get_tree().create_timer(0.1).timeout
	self.select_button.grab_focus()

func hide_panel() -> void:
	self.animations.play("hide")
	self.set_process_input(false)

func load_campaign(campaign_name: String) -> void:
	self.clear_markers()
	self.manifest = self.campaign.get_campaign(campaign_name)

	if self.manifest.is_empty():
		self.main_menu.close_campaign_mission_selection()
		return

	self.title.set_text(str(self.manifest["title"]))
	self._add_mission_markers(self.manifest["missions"] as Array)
	self._select_latest_mission()

	if self.campaign.is_campaign_complete(str(self.manifest["name"])):
		if self.match_setup.animate_medal:
			self.match_setup.animate_medal = false
			await self.get_tree().create_timer(0.2).timeout
			self.animations.play("medal")
		else:
			self.medal.show()
	else:
		self.medal.hide()

	if self.manifest.has("map"):
		self._load_map_override(str(self.manifest["map"]))
		self._calculate_zoom_limit()
	else:
		self._show_base_map()
		self._zoom_limit = 1.0
	self._set_zoom(1.0)
	self._manage_zoom_buttons()

func _add_mission_markers(missions: Array) -> void:
	var index: int = 1
	var marker: CampaignMissionMarker
	var campaign_progress: int = self.campaign.get_campaign_progress(str(self.manifest["name"]))

	for mission: Dictionary in missions:
		marker = self._add_mission_marker(index, mission)
		if index <= campaign_progress:
			marker.set_complete()
		if index > campaign_progress + 1:
			marker.hide()
		index += 1

func _add_mission_marker(index: int, mission_details: Dictionary) -> CampaignMissionMarker:
	var mission_marker: CampaignMissionMarker = self.mission_marker_template.instantiate() as CampaignMissionMarker
	self.mission_markers.append(mission_marker)

	mission_marker.set_mission_title(index, str(mission_details["title"]))
	var marker_position: Array = mission_details["marker"] as Array
	mission_marker.set_position(Vector2(marker_position[0], marker_position[1]))
	self.mission_anchor.add_child(mission_marker)

	return mission_marker

func clear_markers() -> void:
	for marker: CampaignMissionMarker in self.mission_markers:
		marker.queue_free()
	self.mission_markers = []
	self.selected_mission = 0

func _select_latest_mission() -> void:
	if self.campaign.is_campaign_complete(str(self.manifest["name"])):
		self._select_marker(0)
		self._snap_camera_to_marker(0)
		return

	var campaign_progress: int = self.campaign.get_campaign_progress(str(self.manifest["name"]))

	if campaign_progress > self.mission_markers.size():
		campaign_progress = self.mission_markers.size() - 1

	self._select_marker(campaign_progress)
	self._snap_camera_to_marker(campaign_progress)


func _select_marker(marker_no: int) -> void:
	if self.selected_mission != marker_no:
		self.mission_markers[self.selected_mission].hide_panel()

	self.selected_mission = marker_no
	self.mission_markers[self.selected_mission].show_panel()
	self.mission_markers[self.selected_mission].move_to_front()
	self._manage_navigation()

func _snap_camera_to_marker(marker_no: int) -> void:
	self.campaign_camera.position.x = self.mission_markers[marker_no].position.x
	self.campaign_camera.position.y = self.mission_markers[marker_no].position.y

func _tween_camera_to_marker(marker_no: int) -> void:
	var tween: Tween = self.create_tween()
	tween.tween_property(self.campaign_camera, "position", self.mission_markers[marker_no].position, 0.5)

func _manage_navigation() -> void:
	if self._is_first_mission():
		self.prev_button.hide()
	else:
		self.prev_button.show()

	if self._is_last_mission():
		self.next_button.hide()
	else:
		self.next_button.show()

func _is_first_mission() -> bool:
	return self.selected_mission == 0

func _is_last_mission() -> bool:
	var campaign_progress: int = self.campaign.get_campaign_progress(str(self.manifest["name"]))
	return self.selected_mission == campaign_progress or self.selected_mission == self.mission_markers.size() - 1

func _show_base_map() -> void:
	self.base_map.show()
	self.override_map.hide()
	self.campaign_camera.limit_right = self.campaign_viewport.size.x
	self.campaign_camera.limit_bottom = self.campaign_viewport.size.y

func _load_map_override(filename: String) -> void:
	if not self._maps_cache.has(filename):
		if filename.begins_with("res://"):
			self._maps_cache[filename] = load(filename) as Texture2D
		else:
			var image: Image = Image.load_from_file(filename)
			self._maps_cache[filename] = ImageTexture.create_from_image(image)
	self.override_map.texture = self._maps_cache[filename]
	self.campaign_camera.limit_right = self._maps_cache[filename].get_width()
	self.campaign_camera.limit_bottom = self._maps_cache[filename].get_height()


	self.base_map.hide()
	self.override_map.show()

func _calculate_zoom_limit() -> void:
	self._zoom_limit = 1.0

	var fraction_x: float = float(self.campaign_viewport.size.x) / float(self.override_map.texture.get_width())
	var fraction_y: float = float(self.campaign_viewport.size.y) / float(self.override_map.texture.get_height())
	var fraction: float = max(fraction_x, fraction_y)

	while fraction < self._zoom_limit - self._zoom_step:
		self._zoom_limit -= self._zoom_step

func _set_zoom(amount: float) -> void:
	amount = clamp(amount, self._zoom_limit, 1.0)
	self._zoom_level = amount
	self.campaign_camera.zoom.x = amount
	self.campaign_camera.zoom.y = amount

func _manage_zoom_buttons() -> void:
	if self._zoom_level <= self._zoom_limit:
		self.zoom_out_button.hide()
	else:
		self.zoom_out_button.show()

	if self._zoom_level >= 1.0:
		self.zoom_in_button.hide()
	else:
		self.zoom_in_button.show()

func _on_zoom_in_button_pressed() -> void:
	if self._zoom_level >= 1.0:
		return

	self.audio.play("menu_click")
	self._set_zoom(self._zoom_level + self._zoom_step)
	self._manage_zoom_buttons()
	if self._zoom_level >= 1.0:
		self.zoom_out_button.grab_focus()


func _on_zoom_out_button_pressed() -> void:
	if self._zoom_level <= self._zoom_limit:
		return

	self.audio.play("menu_click")
	self._set_zoom(self._zoom_level - self._zoom_step)
	self._manage_zoom_buttons()
	if self._zoom_level <= self._zoom_limit:
		self.zoom_in_button.grab_focus()
