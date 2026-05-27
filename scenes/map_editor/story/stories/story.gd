extends Control
class_name MapStoryStepsPanel

var _page_size: int

signal step_created(story_name: String)
signal page_load_requested(story_name: String, page_no: int)
signal edit_requested(story_name: String, step_no: int)
signal step_data_updated(story_name: String, step_no: int, step_data: Dictionary)
signal step_move_requested(story_name: String, step_no: int, new_step_no: int)
signal step_removal_requested(story_name: String, step_no: int)
signal picker_requested(context: Dictionary)

@onready var prev_button: TextureButton = $"list_prev"
@onready var next_button: TextureButton = $"list_next"
@onready var add_button: TextureButton = $"new_step/add_button"
@onready var audio: AudioService = SimpleAudioLibrary as AudioService

var _story_name: String = ""
var list_elements: Array[StoryStepElement] = []
var current_page: int = 0

var edit_panels: Dictionary[String, Variant] = {}

func _ready() -> void:
    for element: StoryStepElement in $"elements".get_children():
        self.list_elements.append(element)
        element.edit_requested.connect(self._on_edit_requested)
    self._page_size = self.list_elements.size()

    for edit_panel: Variant in $"edit_panels".get_children():
        self.edit_panels[str(edit_panel.name)] = edit_panel
        edit_panel.hide()
        edit_panel.step_data_updated.connect(self._on_step_data_updated)
        edit_panel.step_move_requested.connect(self._on_step_move_requested)
        edit_panel.step_removal_requested.connect(self._on_step_removal_requested)
        edit_panel.picker_requested.connect(self._on_picker_requested)

func _hide_edit_panels() -> void:
    for edit_panel: Variant in self.edit_panels.values():
        edit_panel.hide()

func _switch_to_edit_panel(panel_name: String, step_no: int, step_data: Dictionary) -> void:
    _hide_edit_panels()
    if self.edit_panels.has(panel_name):
        self.edit_panels[panel_name].show_panel()
        self.edit_panels[panel_name].fill_step_data(step_no, step_data)

func show_panel() -> void:
    self.show()

func _clear_page() -> void:
    for element: StoryStepElement in self.list_elements:
        element.hide()

func _slice_page(steps_list: Array, page_no: int) -> Array:
    var paging: Array[Variant] = _normalize_page_no(steps_list.size(), page_no)
    page_no = int(paging[0])

    return steps_list.slice(page_no * self._page_size, (page_no + 1) * self._page_size)

func _fill_page(list_slice: Array, steps_list: Array, page_no: int) -> void:
    var paging: Array[Variant] = _normalize_page_no(steps_list.size(), page_no)
    page_no = int(paging[0])

    var range_size: int = min(self._page_size, list_slice.size())
    var step_label: Variant

    for index: int in range(range_size):
        step_label = list_slice[index]["action"]

        if self.edit_panels.has(list_slice[index]["action"]):
            step_label = self.edit_panels[list_slice[index]["action"]].build_step_label(list_slice[index])

        self.list_elements[index].set_step_name(page_no * self._page_size + index, str(step_label))
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

func _find_step_page(steps_list: Array, step_no: int) -> int:
    var paging: Array[Variant] = _normalize_page_no(steps_list.size(), 0, step_no)
    return int(paging[0])

func show_page(story_name: String, steps_list: Array, page_no: int) -> void:
    self._story_name = story_name
    _clear_page()
    _fill_page(_slice_page(steps_list, page_no), steps_list, page_no)
    _manage_buttons(steps_list.size(), page_no)

func refresh_page(story_name: String, steps_list: Array, clear_edit_panel: bool = true) -> void:
    self.show_page(story_name, steps_list, self.current_page)
    if clear_edit_panel:
        self.clear_editor()

func clear_editor() -> void:
    _switch_to_edit_panel("none", 0, {})

func show_step_page(story_name: String, steps_list: Array, step_no: int) -> void:
    self.show_page(story_name, steps_list, _find_step_page(steps_list, step_no))

func edit_step(step_no: int, step_data: Dictionary) -> void:
    var edit_panel: String = "type_selector"
    if step_data["action"] != null:
        edit_panel = step_data["action"]
    _switch_to_edit_panel(edit_panel, step_no, step_data)

func _on_edit_requested(step_no: int) -> void:
    self.audio.play("menu_click")
    self.edit_requested.emit(self._story_name, step_no)


func _on_list_prev_pressed() -> void:
    self.audio.play("menu_click")
    self.page_load_requested.emit(self._story_name, self.current_page - 1)


func _on_list_next_pressed() -> void:
    self.audio.play("menu_click")
    self.page_load_requested.emit(self._story_name, self.current_page + 1)


func _on_add_button_pressed() -> void:
    self.audio.play("menu_click")
    self.step_created.emit(self._story_name)

func _on_step_data_updated(step_no: int, step_data: Dictionary) -> void:
    self.step_data_updated.emit(self._story_name, step_no, step_data)

    if self.edit_panels["type_selector"].is_visible() or step_data["action"] == null:
        self.edit_step(step_no, step_data)
        self.add_button.grab_focus()

func _on_step_removal_requested(step_no: int) -> void:
    self.step_removal_requested.emit(self._story_name, step_no)
    self.add_button.grab_focus()

func _on_step_move_requested(step_no: int, new_step_no: int) -> void:
    self.step_move_requested.emit(self._story_name, step_no, new_step_no)

func _on_picker_requested(context: Dictionary) -> void:
    context["story_name"] = self._story_name
    self.picker_requested.emit(context)

func _handle_picker_response(response: Variant, context: Dictionary) -> void:
    if context.has("step_action"):
        self.edit_panels[context["step_action"]]._handle_picker_response(response, context)
