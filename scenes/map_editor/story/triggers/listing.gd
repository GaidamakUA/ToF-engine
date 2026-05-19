extends Control
class_name MapStoryTriggersListing

const PAGE_SIZE = 10

signal trigger_created(new_trigger_name: String)
signal page_load_requested(page_no: int)
signal edit_requested(trigger_name: String)
signal trigger_data_updated(trigger_name: String, trigger_data: Dictionary)
signal trigger_removal_requested(trigger_name: String)
signal picker_requested(context: Dictionary)

@onready var prev_button: TextureButton = $"list_prev"
@onready var next_button: TextureButton = $"list_next"
@onready var add_button: TextureButton = $"new_trigger/add_button"
@onready var audio: AudioService = SimpleAudioLibrary as AudioService

var list_elements: Array[TriggerListElement] = []
var current_page: int = 0

var edit_panels: Dictionary[String, Variant] = {}

func _ready() -> void:
	for element: TriggerListElement in $"elements".get_children():
		self.list_elements.append(element)
		element.edit_requested.connect(self._on_edit_requested)
	for edit_panel: Variant in $"edit_panels".get_children():
		self.edit_panels[str(edit_panel.name)] = edit_panel
		edit_panel.hide()
		edit_panel.trigger_data_updated.connect(self._on_trigger_data_updated)
		edit_panel.trigger_removal_requested.connect(self._on_trigger_removal_requested)
		edit_panel.picker_requested.connect(self._on_picker_requested)

func _hide_edit_panels() -> void:
	for edit_panel: Variant in self.edit_panels.values():
		edit_panel.hide()

func _switch_to_edit_panel(panel_name: String, trigger_name: String, trigger_data: Dictionary) -> void:
	_hide_edit_panels()
	if self.edit_panels.has(panel_name):
		self.edit_panels[panel_name].show_panel()
		self.edit_panels[panel_name].fill_trigger_data(trigger_name, trigger_data)

func show_panel() -> void:
	self.show()

func _clear_page() -> void:
	for element: TriggerListElement in self.list_elements:
		element.hide()

func _slice_page(names_list: Array, page_no: int) -> Array:
	var paging: Array[Variant] = _normalize_page_no(names_list.size(), page_no)
	page_no = int(paging[0])
	
	return names_list.slice(page_no * self.PAGE_SIZE, (page_no + 1) * self.PAGE_SIZE)

func _fill_page(list_slice: Array) -> void:
	var range_size: int = min(self.PAGE_SIZE, list_slice.size())
	for index: int in range(range_size):
		self.list_elements[index].set_trigger_name(String(list_slice[index]))
		self.list_elements[index].show()

func _manage_buttons(list_size: int, page_no: int) -> void:
	var paging: Array[Variant] = _normalize_page_no(list_size, page_no)
	self.current_page = int(paging[0])
	if paging[0] == 0:
		self.prev_button.hide()
	else:
		self.prev_button.show()
	if paging[1]:
		self.next_button.hide()
	else:
		self.next_button.show()


func _normalize_page_no(list_size: int, page_no: int, index_search: int = -1) -> Array[Variant]:
	if list_size == 0:
		return [0, true]
	@warning_ignore("integer_division")
	var full_pages: int = list_size / self.PAGE_SIZE
	var page_overflow: int = list_size % self.PAGE_SIZE
	var all_pages: int = full_pages
	if (page_overflow > 0):
		all_pages += 1

	if index_search >= 0:
		@warning_ignore("integer_division")
		page_no = index_search / self.PAGE_SIZE

	page_no = max(page_no, 0)
	page_no = min(page_no, all_pages - 1)
	
	return [page_no, page_no == all_pages - 1]

func _find_trigger_page(names_list: Array, trigger_name: String) -> int:
	var index: int = names_list.find(trigger_name)
	var paging: Array[Variant] = _normalize_page_no(names_list.size(), 0, index)
	return int(paging[0])

func show_page(names_list: Array, page_no: int) -> void:
	_clear_page()
	_fill_page(_slice_page(names_list, page_no))
	_manage_buttons(names_list.size(), page_no)

func refresh_page(names_list: Array) -> void:
	self.show_page(names_list, self.current_page)
	_switch_to_edit_panel("none", "", {})

func show_trigger_page(names_list: Array, trigger_name: String) -> void:
	self.show_page(names_list, _find_trigger_page(names_list, trigger_name))

func edit_trigger(trigger_name: String, trigger_data: Dictionary) -> void:
	var edit_panel: String = "type_selector"
	if trigger_data["type"] != null:
		edit_panel = trigger_data["type"]
	_switch_to_edit_panel(edit_panel, trigger_name, trigger_data)

func _on_edit_requested(trigger_name: String) -> void:
	self.audio.play("menu_click")
	self.edit_requested.emit(trigger_name)


func _on_list_prev_pressed() -> void:
	self.audio.play("menu_click")
	self.page_load_requested.emit(self.current_page - 1)


func _on_list_next_pressed() -> void:
	self.audio.play("menu_click")
	self.page_load_requested.emit(self.current_page + 1)


func _on_add_button_pressed() -> void:
	self.audio.play("menu_click")
	self.trigger_created.emit($"new_trigger/name".get_text())

func _on_trigger_data_updated(trigger_name: String, trigger_data: Dictionary) -> void:
	self.trigger_data_updated.emit(trigger_name, trigger_data)

	if self.edit_panels["type_selector"].is_visible() or trigger_data["type"] == null:
		self.edit_trigger(trigger_name, trigger_data)
		self.add_button.grab_focus()

func _on_trigger_removal_requested(trigger_name: String) -> void:
	self.trigger_removal_requested.emit(trigger_name)
	self.add_button.grab_focus()

func _on_picker_requested(context: Dictionary) -> void:
	self.picker_requested.emit(context)

func _handle_picker_response(response: Variant, context: Dictionary) -> void:
	if context.has("trigger_type"):
		self.edit_panels[context["trigger_type"]]._handle_picker_response(response, context)
