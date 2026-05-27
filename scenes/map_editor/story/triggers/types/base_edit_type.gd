extends Control
class_name BaseTriggerTypeEditor

var trigger_name: String = ""
var trigger_data: Dictionary = {}

@onready var audio: AudioService = SimpleAudioLibrary as AudioService

signal trigger_data_updated(trigger_name: String, trigger_data: Dictionary)
signal trigger_removal_requested(trigger_name: String)
signal picker_requested(context: Dictionary)

func show_panel() -> void:
    self.show()

func fill_trigger_data(new_trigger_name: String, new_trigger_data: Dictionary) -> void:
    self.trigger_name = new_trigger_name
    self.trigger_data = new_trigger_data
    
    if not self.trigger_data.has("one_off"):
        self.trigger_data["one_off"] = false
    
    $"name".set_text(self.trigger_name)
    $"type".set_text(self.trigger_data["type"])
    
    if self.trigger_data["story"] != null:
        $"story".set_text(self.trigger_data["story"])
    else:
        $"story".set_text("")
    
    if self.trigger_data["one_off"]:
        $"oneoff_button/label".set_text("TR_ON")
    else:
        $"oneoff_button/label".set_text("TR_OFF")

func _emit_updated_signal() -> void:
    self.trigger_data_updated.emit(self.trigger_name, _compile_trigger_data())

func _compile_trigger_data() -> Dictionary:
    return self.trigger_data


func _on_delete_button_pressed() -> void:
    self.audio.play("menu_click")
    self.trigger_removal_requested.emit(self.trigger_name)


func _on_change_button_pressed() -> void:
    self.audio.play("menu_click")
    self.trigger_data["type"] = null
    _emit_updated_signal()


func _on_story_button_pressed() -> void:
    self.audio.play("menu_click")
    self.picker_requested.emit({
        "type": "story",
        "trigger_name": self.trigger_name
    })


func _on_oneoff_button_pressed() -> void:
    self.audio.play("menu_click")
    self.trigger_data["one_off"] = not self.trigger_data["one_off"]
    if self.trigger_data["one_off"]:
        $"oneoff_button/label".set_text("TR_ON")
    else:
        $"oneoff_button/label".set_text("TR_OFF")
    _emit_updated_signal()

func _handle_picker_response(response: Variant, context: Dictionary) -> void:
    if context["type"] == "story":
        self.trigger_data["story"] = response
        $"story".set_text(response)
        _emit_updated_signal()
