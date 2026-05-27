extends BaseStepActionEditor

func fill_step_data(new_step_no: int, new_step_data: Dictionary) -> void:
    super.fill_step_data(new_step_no, new_step_data)
    
    $"slot/slot".set_text("")
    $"text".set_text("")
    $"clear/clear_button/label".set_text("TR_OFF")
    
    if self.step_data.has("details"):
        if self.step_data["details"].has("slot"):
            $"slot/slot".set_text(str(self.step_data["details"]["slot"]))

        if self.step_data["details"].has("clear"):
            if self.step_data["details"]["clear"]:
                $"clear/clear_button/label".set_text("TR_ON")
            else:
                $"clear/clear_button/label".set_text("TR_OFF")

        if self.step_data["details"].has("text"):
            $"text".set_text(self.step_data["details"]["text"])

func build_step_label(requested_step_data: Dictionary) -> String:
    var label: String = requested_step_data["action"]
    if requested_step_data.has("details"):
        if requested_step_data["details"].has("slot"):
            label += " " + str(requested_step_data["details"]["slot"])
    return label

func _compile_step_data() -> Dictionary:
    self.step_data = super._compile_step_data()
    
    var slot: String = $"slot/slot".get_text()
    var text: String = $"text".get_text()
    var clear: bool = false

    if self.step_data["details"].has("clear"):
        clear = self.step_data["details"]["clear"]

    self.step_data["details"] = {
        "clear": clear
    }

    if slot != "":
        self.step_data["details"]["slot"] = slot
    if text != "":
        self.step_data["details"]["text"] = text

    return self.step_data

func _on_clear_button_pressed() -> void:
    self.audio.play("menu_click")
    if not self.step_data["details"].has("clear"):
        self.step_data["details"]["clear"] = false
    self.step_data["details"]["clear"] = not self.step_data["details"]["clear"]
    if self.step_data["details"]["clear"]:
        $"ban/ban_button/label".set_text("TR_ON")
    else:
        $"ban/ban_button/label".set_text("TR_OFF")
    _emit_updated_signal()

func _on_text_area_changed() -> void:
    _emit_updated_signal()
