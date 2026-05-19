extends Control
class_name StoryElementPicker

var _page_size: int

signal value_selected(element_value: String, context: Dictionary)

@onready var prev_button: TextureButton = $"prev"
@onready var next_button: TextureButton = $"next"
@onready var audio: AudioService = SimpleAudioLibrary as AudioService

var list_elements: Array[StoryElementPickerListElement] = []
var current_page: int = 0
var current_data: Array = []
var picker_context: Dictionary = {}

func _ready() -> void:
	for element: StoryElementPickerListElement in $"elements".get_children():
		self.list_elements.append(element)
		element.value_selected.connect(self._on_value_selected)
	self._page_size = self.list_elements.size()

func show_panel() -> void:
	self.show()

func _clear_page() -> void:
	for element: StoryElementPickerListElement in self.list_elements:
		element.hide()

func _slice_page(names_list: Array, page_no: int) -> Array:
	var paging: Array[Variant] = _normalize_page_no(names_list.size(), page_no)
	page_no = int(paging[0])
	
	return names_list.slice(page_no * self._page_size, (page_no + 1) * self._page_size)

func _fill_page(list_slice: Array) -> void:
	var range_size: int = min(self._page_size, list_slice.size())
	for index: int in range(range_size):
		self.list_elements[index].set_element_value(String(list_slice[index]))
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
	var full_pages: int = list_size / self._page_size
	var page_overflow: int = list_size % self._page_size
	var all_pages: int = full_pages
	if (page_overflow > 0):
		all_pages += 1

	if index_search >= 0:
		@warning_ignore("integer_division")
		page_no = index_search / self._page_size

	page_no = max(page_no, 0)
	page_no = min(page_no, all_pages - 1)
	
	return [page_no, page_no == all_pages - 1]

func load_list(names_list: Array, context: Dictionary) -> void:
	self.current_data = names_list
	self.current_page = 0
	self.picker_context = context
	_load_page(0)

func _load_page(page_no: int) -> void:
	_clear_page()
	_fill_page(_slice_page(self.current_data, page_no))
	_manage_buttons(self.current_data.size(), page_no)


func _on_prev_pressed() -> void:
	self.audio.play("menu_click")
	_load_page(self.current_page - 1)


func _on_next_pressed() -> void:
	self.audio.play("menu_click")
	_load_page(self.current_page + 1)

func _on_value_selected(selected_value: String) -> void:
	self.audio.play("menu_click")
	self.value_selected.emit(selected_value, self.picker_context)
