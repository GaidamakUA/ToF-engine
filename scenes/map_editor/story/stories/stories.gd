extends Control
class_name MapStoryStoriesPanel

@onready var listing_panel: StoryListingPanel = $Listing
@onready var story_panel: MapStoryStepsPanel = $Story

signal picker_requested(context: Dictionary)
@warning_ignore("unused_signal")
signal edit_requested(story_name: String)

var stories_data: Dictionary = {}

func _ready() -> void:
    self.listing_panel.story_created.connect(self._on_new_story_created)
    self.listing_panel.page_load_requested.connect(self._on_stories_page_load_request)
    self.listing_panel.edit_requested.connect(self._on_story_edit_requested)
    self.listing_panel.story_removal_requested.connect(self._on_story_removal_requested)

    self.story_panel.step_created.connect(self._on_new_story_step_created)
    self.story_panel.page_load_requested.connect(self._on_step_page_load_requested)
    self.story_panel.edit_requested.connect(self._on_step_edit_requested)
    self.story_panel.step_data_updated.connect(self._on_step_data_updated)
    self.story_panel.step_move_requested.connect(self._on_step_move_requested)
    self.story_panel.step_removal_requested.connect(self._on_story_step_removal_requested)
    self.story_panel.picker_requested.connect(self._on_picker_requested)


func _switch_to_panel(panel: Variant) -> void:
    self.listing_panel.hide()
    self.story_panel.hide()
    panel.show_panel()

func show_panel() -> void:
    self.show()


func ingest_stories_data(data: Dictionary) -> void:
    self.stories_data = data
    _on_stories_page_load_request(0)
    _switch_to_panel(self.listing_panel)
    

func compile_stories_data() -> Dictionary:
    return self.stories_data


func _on_back_button_pressed() -> bool:
    if self.story_panel.is_visible():
        _switch_to_panel(self.listing_panel)
        return true
    return false

func _get_sorted_stories_names() -> Array:
    var stories_names: Array = self.stories_data.keys()
    stories_names.sort()
    return stories_names

func _on_new_story_created(new_story_name: String) -> void:
    if new_story_name == "":
        return
    if not self.stories_data.has(new_story_name):
        self.stories_data[new_story_name] = []
    self.listing_panel.refresh_page(_get_sorted_stories_names())

func _on_stories_page_load_request(page_no: int) -> void:
    _switch_to_panel(self.listing_panel)
    self.listing_panel.show_page(_get_sorted_stories_names(), page_no)


func _on_story_edit_requested(story_name: String) -> void:
    _switch_to_panel(self.story_panel)
    _on_step_page_load_requested(story_name, 0)
    self.story_panel.clear_editor()

func _on_story_removal_requested(story_name: String) -> void:
    self.stories_data.erase(story_name)
    _switch_to_panel(self.listing_panel)
    self.listing_panel.refresh_page(_get_sorted_stories_names())


func _on_new_story_step_created(story_name: String) -> void:
    if not self.stories_data.has(story_name):
        return
    var new_step_no: int = self.stories_data[story_name].size()
    self.stories_data[story_name].append({
        "action": null,
        "delay": 0
    })
    self.story_panel.show_step_page(story_name, self.stories_data[story_name], new_step_no)
    self.story_panel.edit_step(new_step_no, self.stories_data[story_name][new_step_no])

func _on_step_page_load_requested(story_name: String, page_no: int) -> void:
    if self.stories_data.has(story_name):
        self.story_panel.show_page(story_name, self.stories_data[story_name], page_no)

func _on_step_edit_requested(story_name: String, step_no: int) -> void:
    if self.stories_data.has(story_name):
        self.story_panel.edit_step(step_no, self.stories_data[story_name][step_no])

func _on_step_data_updated(story_name: String, step_no: int, step_data: Dictionary) -> void:
    if self.stories_data.has(story_name):
        self.stories_data[story_name][step_no] = step_data
        self.story_panel.refresh_page(story_name, self.stories_data[story_name], false)

func _on_step_move_requested(story_name: String, step_no: int, new_step_no: int) -> void:
    if self.stories_data.has(story_name):
        var step_data: Dictionary = self.stories_data[story_name].pop_at(step_no)
        new_step_no = clamp(new_step_no, 0, self.stories_data[story_name].size())
        self.stories_data[story_name].insert(new_step_no, step_data)
        self.story_panel.show_step_page(story_name, self.stories_data[story_name], new_step_no)
        self.story_panel.edit_step(new_step_no, self.stories_data[story_name][new_step_no])

func _on_story_step_removal_requested(story_name: String, step_no: int) -> void:
    if self.stories_data.has(story_name):
        self.stories_data[story_name].remove_at(step_no)
        self.story_panel.refresh_page(story_name, self.stories_data[story_name])

func _on_picker_requested(context: Dictionary) -> void:
    context["tab"] = "stories"
    if context.has("story_name"):
        if self.stories_data.has(context["story_name"]):
            context["step_action"] = self.stories_data[context["story_name"]][context["step_no"]]["action"]
    self.picker_requested.emit(context)

func _handle_picker_response(response: Variant, context: Dictionary) -> void:
    self.story_panel._handle_picker_response(response, context)
