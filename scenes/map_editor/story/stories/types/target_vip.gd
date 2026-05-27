extends BaseStepActionEditor

func fill_step_data(new_step_no: int, new_step_data: Dictionary) -> void:
    super.fill_step_data(new_step_no, new_step_data)
    
    $"vip/x".set_text("")
    $"vip/y".set_text("")
    $"trigger/trigger".set_text("")
    
    if self.step_data.has("details"):
        if self.step_data["details"].has("vip"):
            $"vip/x".set_text(str(self.step_data["details"]["vip"][0]))
            $"vip/y".set_text(str(self.step_data["details"]["vip"][1]))
        if self.step_data["details"].has("trigger_id"):
            $"trigger/trigger".set_text(self.step_data["details"]["trigger_id"])

func _compile_step_data() -> Dictionary:
    self.step_data = super._compile_step_data()
    
    var x: String = $"vip/x".get_text()
    var y: String = $"vip/y".get_text()
    var trigger: String = $"trigger/trigger".get_text()

    self.step_data["details"] = {}

    if x != "" and y != "":
        self.step_data["details"]["vip"] = [int(x), int(y)]
    if trigger != "":
        self.step_data["details"]["trigger_id"] = trigger

    return self.step_data


func _on_picker_button_pressed() -> void:
    self.audio.play("menu_click")

    var vip_position: Variant = null
    if self.step_data["details"].has("vip"):
        vip_position = self.step_data["details"]["vip"]

    self.picker_requested.emit({
        "type": "position",
        "position": vip_position,
        "step_no": self.step_no
    })

func _handle_picker_response(response: Variant, context: Dictionary) -> void:
    super._handle_picker_response(response, context)
    if context["type"] == "position":
        $"vip/x".set_text(str(response.x))
        $"vip/y".set_text(str(response.y))
    if context["type"] == "trigger":
        $"trigger/trigger".set_text(response)
    _emit_updated_signal()


func _on_trigger_picker_button_pressed() -> void:
    self.audio.play("menu_click")

    self.picker_requested.emit({
        "type": "trigger",
        "step_no": self.step_no
    })
