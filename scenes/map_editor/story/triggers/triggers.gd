extends Control
class_name MapStoryTriggersPanel

@onready var listing_panel: MapStoryTriggersListing = $Listing

signal picker_requested(context: Dictionary)

var triggers_data: Dictionary = {}

func _ready() -> void:
	self.listing_panel.trigger_created.connect(self._on_new_trigger_created)
	self.listing_panel.page_load_requested.connect(self._on_triggers_page_load_request)
	self.listing_panel.edit_requested.connect(self._on_trigger_edit_requested)
	self.listing_panel.trigger_data_updated.connect(self._on_trigger_data_updated)
	self.listing_panel.trigger_removal_requested.connect(self._on_trigger_removal_requested)
	self.listing_panel.picker_requested.connect(self._on_picker_requested)


func _switch_to_panel(panel: Variant) -> void:
	self.listing_panel.hide()
	panel.show_panel()

func show_panel() -> void:
	self.show()


func ingest_triggers_data(data: Dictionary) -> void:
	self.triggers_data = data
	_on_triggers_page_load_request(0)
	_switch_to_panel(self.listing_panel)
	self.listing_panel._hide_edit_panels()
	

func compile_triggers_data() -> Dictionary:
	return self.triggers_data

func _get_sorted_trigger_names() -> Array:
	var trigger_names: Array = self.triggers_data.keys()
	trigger_names.sort()
	return trigger_names

func _on_new_trigger_created(new_trigger_name: String) -> void:
	if new_trigger_name == "":
		return
	if not self.triggers_data.has(new_trigger_name):
		self.triggers_data[new_trigger_name] = {
			"details": {},
			"one_off": true,
			"story": null,
			"type": null
		}
	self.listing_panel.show_trigger_page(_get_sorted_trigger_names(), new_trigger_name)
	self.listing_panel.edit_trigger(new_trigger_name, self.triggers_data[new_trigger_name])
	
func _on_triggers_page_load_request(page_no: int) -> void:
	self.listing_panel.show_page(_get_sorted_trigger_names(), page_no)

func _on_trigger_edit_requested(trigger_name: String) -> void:
	self.listing_panel.edit_trigger(trigger_name, self.triggers_data[trigger_name])

func _on_trigger_data_updated(trigger_name: String, trigger_data: Dictionary) -> void:
	self.triggers_data[trigger_name] = trigger_data


func _on_trigger_removal_requested(trigger_name: String) -> void:
	self.triggers_data.erase(trigger_name)
	self.listing_panel.refresh_page(_get_sorted_trigger_names())

func _on_picker_requested(context: Dictionary) -> void:
	context["tab"] = "triggers"
	if context.has("trigger_name"):
		if self.triggers_data.has(context["trigger_name"]):
			context["trigger_type"] = self.triggers_data[context["trigger_name"]]["type"]
	self.picker_requested.emit(context)

func _handle_picker_response(response: Variant, context: Dictionary) -> void:
	self.listing_panel._handle_picker_response(response, context)
