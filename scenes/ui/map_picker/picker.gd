extends Node2D
class_name MapPickerPanel

const MODE_NAME: String = "name"
const MODE_SELECT: String = "select"
const MODE_BROWSE: String = "browse"

const LIST_LATEST: String = "latest"
const LIST_DOWNLOADED: String = "downloaded"

const PAGE_SIZE: int = 10

@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var animations: AnimationPlayer = $"animations"

@onready var tabs_bar: Control = $"widgets/tabs"
@onready var name_group: Control = $"widgets/name"
@onready var map_name_field: LineEdit = $"widgets/name/map_name"
@onready var save_button: BaseButton = $"widgets/name/save_button"
@onready var load_button: BaseButton = $"widgets/name/load_button"
@onready var cancel_button: BaseButton = $"widgets/cancel_button"
@onready var next_button: BaseButton = $"widgets/list_next"
@onready var prev_button: BaseButton = $"widgets/list_prev"

@onready var online_bar: Control = $"widgets/online"
@onready var code_group: Control = $"widgets/code"
@onready var code_field: LineEdit = $"widgets/code/code"
@onready var download_button: BaseButton = $"widgets/code/download_button"

@onready var custom_maps_button: BaseButton = $"widgets/tabs/custom_button"

@onready var map_list_service: MapManagerService = MapManager as MapManagerService
@onready var gamepad_adapter: GamepadAdapterService = GamepadAdapter as GamepadAdapterService
@onready var online_service: OnlineService = Online as OnlineService

@onready var map_selection_buttons: Array[MapPickerButton] = [
	$"widgets/map_list/map0",
	$"widgets/map_list/map1",
	$"widgets/map_list/map2",
	$"widgets/map_list/map3",
	$"widgets/map_list/map4",
	$"widgets/map_list/map5",
	$"widgets/map_list/map6",
	$"widgets/map_list/map7",
	$"widgets/map_list/map8",
	$"widgets/map_list/map9",
]
@onready var minimap: MinimapView = $"widgets/minimap"
@onready var thumb: TextureRect = $"widgets/minimap/thumb"
@onready var thumb_label: Label = $"widgets/minimap/thumb/label"



var bound_success_object: Object = null
var bound_success_method: StringName = &""
var bound_success_args: Array[Variant] = []

var bound_cancel_object: Object = null
var bound_cancel_method: StringName = &""
var bound_cancel_args: Array[Variant] = []

var operation_mode: String = "name"
var list_mode: String = ""
var current_page: int = 0

var last_online_id: int = -1
var last_focused_code: Variant = null
var fetching_chunk: bool = false

func _ready() -> void:
	self.connect_buttons()
	self.set_process_input(false)
	self.list_mode = self.map_list_service.LIST_STOCK

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed('editor_menu'):
		self.execute_cancel()
	if event.is_action_pressed("ui_page_down"):
		self.switch_to_next_page()
		if self.map_selection_buttons[0].is_visible():
			self.map_selection_buttons[0].grab_focus()
	if event.is_action_pressed("ui_page_up"):
		self.switch_to_prev_page()
		if self.map_selection_buttons[0].is_visible():
			self.map_selection_buttons[0].grab_focus()

func set_name_mode() -> void:
	self.operation_mode = self.MODE_NAME
	self.name_group.show()
	self.code_group.hide()
	self.online_bar.hide()

func set_select_mode() -> void:
	self.operation_mode = self.MODE_SELECT
	self.name_group.hide()
	self.code_group.hide()
	self.online_bar.hide()

func set_browse_mode() -> void:
	self.operation_mode = self.MODE_BROWSE
	self.list_mode = self.LIST_LATEST
	self.current_page = 0
	self.manage_pagination_buttons(0)
	self.name_group.hide()
	self.code_group.show()
	self.online_bar.show()
	self.tabs_bar.hide()
	self.minimap.wipe()
	self.online_service.set_api_version(2)

func set_browse_v1_mode() -> void:
	self.set_browse_mode()
	self.online_service.set_api_version(1)

func lock_tab_bar(select_mode: Variant = null) -> void:
	if select_mode != null:
		self.list_mode = String(select_mode)
	else:
		self.list_mode = self.map_list_service.LIST_CUSTOM
	self.tabs_bar.hide()

func lock_custom_maps() -> void:
	self.list_mode = self.map_list_service.LIST_STOCK
	self.custom_maps_button.hide()

func lock_tab_bar_downloaded() -> void:
	self.lock_tab_bar(self.map_list_service.LIST_DOWNLOADED)

func unlock_tab_bar() -> void:
	self.custom_maps_button.show()
	self.tabs_bar.show()


func clear_binds() -> void:
	self.bound_success_object = null
	self.bound_success_method = &""
	self.bound_success_args = []
	self.bound_cancel_object = null
	self.bound_cancel_method = &""
	self.bound_cancel_args = []

func bind_success(success_object: Object, success_method: StringName, success_args: Array[Variant] = []) -> void:
	self.bound_success_object = success_object
	self.bound_success_method = success_method
	self.bound_success_args = success_args

func bind_cancel(cancel_object: Object, cancel_method: StringName, cancel_args: Array[Variant] = []) -> void:
	self.bound_cancel_object = cancel_object
	self.bound_cancel_method = cancel_method
	self.bound_cancel_args = cancel_args


func execute_success(map_name: String, context: Variant = null) -> void:
	self.audio.play("menu_click")
	if self.bound_success_object != null:
		var args: Array[Variant] = []
		args.assign(self.bound_success_args)

		args.append(map_name)
		args.append(context)
		self.bound_success_object.call_deferred(self.bound_success_method, args)

func execute_load() -> void:
	self.audio.play("menu_click")
	var map_name: String = self.map_name_field.get_text()

	if map_name == "":
		return

	if not self.map_list_service.map_exists(map_name):
		return

	self.execute_success(map_name, "load")


func execute_save() -> void:
	self.audio.play("menu_click")
	var map_name: String = self.map_name_field.get_text()

	if map_name == "":
		return

	self.execute_success(map_name, "save")

func execute_cancel() -> void:
	self.audio.play("menu_back")
	if self.bound_cancel_object != null:
		if self.bound_cancel_args.size() > 0:
			self.bound_cancel_object.call_deferred(self.bound_cancel_method, self.bound_cancel_args)
		else:
			self.bound_cancel_object.call_deferred(self.bound_cancel_method)

func show_picker() -> void:
	self.animations.play("show")
	self.set_process_input(true)

	self.last_online_id = -1
	self.online_service.clear_cache()
	self.thumb.hide()
	self.minimap.wipe()

	if self.operation_mode == self.MODE_BROWSE:
		self.refresh_online_maps_page()
	else:
		self.refresh_current_maps_page()
	await self.get_tree().create_timer(0.1).timeout
	if self.map_selection_buttons[0].is_visible():
		self.map_selection_buttons[0].grab_focus()
	elif self.name_group.is_visible():
		self.save_button.grab_focus()
	elif self.operation_mode == self.MODE_BROWSE:
		self.code_field.grab_focus()
	else:
		self.cancel_button.grab_focus()

	self.gamepad_adapter.enable()


func hide_picker() -> void:
	self.animations.play("hide")
	self.set_process_input(false)
	self.gamepad_adapter.disable()

func set_map_name(map_name: String) -> void:
	self.map_name_field.set_text(map_name)
	self._on_map_name_text_changed(map_name)

func set_code(code: String) -> void:
	self.code_field.set_text(code)

func refresh_online_maps_page() -> void:
	for map_button: MapPickerButton in self.map_selection_buttons:
		map_button.hide()
	self.thumb.hide()

	if self.list_mode == self.LIST_DOWNLOADED and not  self.online_service.maps.listing_end:
		await self.online_service.fetch_top_downloads()

	if self.last_online_id == -1:
		await self._fetch_next_online_page()

	var pages_count: int = self.online_service.get_pages_count(self.PAGE_SIZE)
	if self.current_page >= pages_count - 2:
		await self._fetch_next_online_page()

	self.manage_pagination_buttons(pages_count)
	var maps_page: Array[Dictionary] = self.online_service.get_maps_page(self.current_page, self.PAGE_SIZE)
	for index: int in range(maps_page.size()):
		var map_details: Dictionary[String, Variant]
		map_details.assign(maps_page[index])
		self.map_selection_buttons[index].fill_data(String(map_details["name"]), String(map_details["code"]), map_details["downloads"])
		self.map_selection_buttons[index].show()
		self.online_service.fetch_thumbnail(String(map_details["code"]))


func refresh_current_maps_page() -> void:
	var pages_count: int = self.map_list_service.get_pages_count(self.list_mode, self.PAGE_SIZE)

	self.manage_pagination_buttons(pages_count)
	for map_button: MapPickerButton in self.map_selection_buttons:
		map_button.hide()

	var maps_page: Array[String] = self.map_list_service.get_maps_page(self.list_mode, self.current_page, self.PAGE_SIZE)
	for index: int in range(maps_page.size()):
		var map_details: Dictionary[String, Variant]
		map_details.assign(self.map_list_service.get_map_details(maps_page[index]))
		self.map_selection_buttons[index].fill_data(String(map_details["name"]), map_details["online_id"])
		self.map_selection_buttons[index].show()

func manage_pagination_buttons(pages_count: int) -> void:
	if self.current_page == 0 || pages_count < 2:
		self.prev_button.hide()
	elif self.current_page > 0:
		self.prev_button.show()

	if self.current_page == pages_count - 1 || pages_count < 2:
		self.next_button.hide()
	elif self.current_page < pages_count - 1:
		self.next_button.show()

func switch_to_prev_page() -> void:
	self.audio.play("menu_click")
	if self.current_page > 0:
		self.current_page -= 1

	if self.operation_mode == self.MODE_BROWSE:
		self.refresh_online_maps_page()
	else:
		self.refresh_current_maps_page()

	if self.current_page == 0:
		if self.next_button.is_visible():
			self.next_button.grab_focus()


func switch_to_next_page() -> void:
	self.audio.play("menu_click")
	var pages_count: int
	if self.operation_mode == self.MODE_BROWSE:
		pages_count = self.online_service.get_pages_count(self.PAGE_SIZE)
	else:
		pages_count = self.map_list_service.get_pages_count(self.list_mode, self.PAGE_SIZE)

	if self.current_page < pages_count - 1:
		self.current_page += 1

	if self.operation_mode == self.MODE_BROWSE:
		self.refresh_online_maps_page()
	else:
		self.refresh_current_maps_page()

	if self.current_page == pages_count - 1:
		if self.prev_button.is_visible():
			self.prev_button.grab_focus()


func map_button_pressed(map_name: String) -> void:
	self.audio.play("menu_click")
	if self.operation_mode == self.MODE_NAME:
		self.set_map_name(map_name)
		self.load_button.grab_focus()
	elif self.operation_mode == self.MODE_SELECT:
		self.execute_success(map_name, "select")
	elif self.operation_mode == self.MODE_BROWSE:
		self.set_code(map_name)
		self.download_button.grab_focus()

func map_button_focused(map_name: String) -> void:
	if self.operation_mode == self.MODE_BROWSE:
		self.last_focused_code = map_name
		self.thumb.show()
		self.thumb_label.show()
		var image: Dictionary[String, Variant] = await self.online_service.fetch_thumbnail(map_name)
		if self.last_focused_code == image["code"] and image["image"] != null:
			self.thumb_label.hide()
			self.thumb.texture = image["image"] as Texture2D
	else:
		self.thumb.hide()
		self.minimap.fill_minimap(map_name)

func connect_buttons() -> void:
	self.cancel_button.connect("pressed", Callable(self, "execute_cancel"))

	self.save_button.connect("pressed", Callable(self, "execute_save"))
	self.load_button.connect("pressed", Callable(self, "execute_load"))

	self.next_button.connect("pressed", Callable(self, "switch_to_next_page"))
	self.prev_button.connect("pressed", Callable(self, "switch_to_prev_page"))

	for button: MapPickerButton in self.map_selection_buttons:
		button.bind_method(self, &"map_button_pressed")
		button.bind_focus(self, &"map_button_focused")


func _on_map_name_text_changed(new_text: String) -> void:
	self.save_button.set_disabled(self.map_list_service.is_reserved_name(new_text))


func _fetch_next_online_page() -> void:
	if self.online_service.maps.listing_end:
		return
	if self.fetching_chunk:
		return
	self.fetching_chunk = true

	var result: int = await self.online_service.fetch_listing_chunk(self.last_online_id)

	self.fetching_chunk = false
	self.last_online_id = result
	var pages_count: int = self.online_service.get_pages_count(self.PAGE_SIZE)
	self.manage_pagination_buttons(pages_count)

func _on_stock_button_pressed() -> void:
	self.audio.play("menu_click")
	self.list_mode = self.map_list_service.LIST_STOCK
	self.current_page = 0
	self.refresh_current_maps_page()


func _on_custom_button_pressed() -> void:
	self.audio.play("menu_click")
	self.list_mode = self.map_list_service.LIST_CUSTOM
	self.current_page = 0
	self.refresh_current_maps_page()


func _on_downloaded_button_pressed() -> void:
	self.audio.play("menu_click")
	self.list_mode = self.map_list_service.LIST_DOWNLOADED
	self.current_page = 0
	self.refresh_current_maps_page()


func _on_latest_button_pressed() -> void:
	self.audio.play("menu_click")
	if self.list_mode == self.LIST_LATEST:
		return
	self.list_mode = self.LIST_LATEST
	self.current_page = 0
	self.manage_pagination_buttons(0)
	self.last_online_id = -1
	self.online_service.clear_cache()
	self.refresh_online_maps_page()


func _on_top_button_pressed() -> void:
	if self.list_mode == self.LIST_DOWNLOADED:
		return
	self.list_mode = self.LIST_DOWNLOADED
	self.current_page = 0
	self.manage_pagination_buttons(0)
	self.last_online_id = -1
	self.online_service.clear_cache()
	self.refresh_online_maps_page()


func _on_download_button_pressed() -> void:
	self.audio.play("menu_click")
	var code: String = self.code_field.get_text()

	if code == "":
		return

	self.execute_success(code, "download")
