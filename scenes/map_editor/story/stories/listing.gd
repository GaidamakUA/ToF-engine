extends Control
class_name StoryListingPanel

var _page_size: int

signal story_created(new_story_name: String)
signal page_load_requested(page_no: int)
signal edit_requested(story_name: String)
signal story_removal_requested(story_name: String)

@onready var prev_button: TextureButton = $"list_prev"
@onready var next_button: TextureButton = $"list_next"
@onready var add_button: TextureButton = $"new_story/add_button"
@onready var audio: AudioService = SimpleAudioLibrary as AudioService

var list_elements: Array[StoryListElement] = []
var current_page: int = 0


func _ready() -> void:
	for element: StoryListElement in $"elements".get_children():
		self.list_elements.append(element)
		element.edit_requested.connect(self._on_edit_requested)
		element.story_removal_requested.connect(self._on_story_removal_requested)
	self._page_size = self.list_elements.size()


func show_panel() -> void:
	self.show()

func _clear_page() -> void:
	for element: StoryListElement in self.list_elements:
		element.hide()

func _slice_page(names_list: Array, page_no: int) -> Array:
	var paging: Array[Variant] = _normalize_page_no(names_list.size(), page_no)
	page_no = int(paging[0])
	
	return names_list.slice(page_no * self._page_size, (page_no + 1) * self._page_size)

func _fill_page(list_slice: Array) -> void:
	var range_size: int = min(self._page_size, list_slice.size())
	for index: int in range(range_size):
		self.list_elements[index].set_story_name(String(list_slice[index]))
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

func show_page(names_list: Array, page_no: int) -> void:
	_clear_page()
	_fill_page(_slice_page(names_list, page_no))
	_manage_buttons(names_list.size(), page_no)

func refresh_page(names_list: Array) -> void:
	self.show_page(names_list, self.current_page)

func _on_edit_requested(story_name: String) -> void:
	self.audio.play("menu_click")
	self.edit_requested.emit(story_name)


func _on_list_prev_pressed() -> void:
	self.audio.play("menu_click")
	self.page_load_requested.emit(self.current_page - 1)


func _on_list_next_pressed() -> void:
	self.audio.play("menu_click")
	self.page_load_requested.emit(self.current_page + 1)


func _on_add_button_pressed() -> void:
	self.audio.play("menu_click")
	self.story_created.emit($"new_story/name".get_text())

func _on_story_removal_requested(story_name: String) -> void:
	self.audio.play("menu_click")
	self.story_removal_requested.emit(story_name)
	self.add_button.grab_focus()
