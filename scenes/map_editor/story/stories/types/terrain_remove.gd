extends BaseStepActionEditor

func fill_step_data(new_step_no: int, new_step_data: Dictionary) -> void:
    super.fill_step_data(new_step_no, new_step_data)
    
    $"where/x".set_text("")
    $"where/y".set_text("")
    $"tile_type/tile_type".set_text("")
    $"explosion/explosion_button/label".set_text("TR_OFF")
    
    if self.step_data.has("details"):
        if self.step_data["details"].has("where"):
            $"where/x".set_text(str(self.step_data["details"]["where"][0]))
            $"where/y".set_text(str(self.step_data["details"]["where"][1]))

        if self.step_data["details"].has("type"):
            $"tile_type/tile_type".set_text(self.step_data["details"]["type"])

        if self.step_data["details"].has("explosion"):
            if self.step_data["details"]["explosion"]:
                $"explosion/explosion_button/label".set_text("TR_ON")
            else:
                $"explosion/explosion_button/label".set_text("TR_OFF")

func build_step_label(requested_step_data: Dictionary) -> String:
    var label: String = requested_step_data["action"]
    if requested_step_data.has("details"):
        if requested_step_data["details"].has("type"):
            label += " " + requested_step_data["details"]["type"]
    return label

func _compile_step_data() -> Dictionary:
    self.step_data = super._compile_step_data()
    
    var x: String = $"where/x".get_text()
    var y: String = $"where/y".get_text()
    var tile_type: String = $"tile_type/tile_type".get_text()
    var explosion: bool = false

    if self.step_data["details"].has("explosion"):
        explosion = self.step_data["details"]["explosion"]

    self.step_data["details"] = {
        "explosion": explosion
    }

    if x != "" and y != "":
        self.step_data["details"]["where"] = [int(x), int(y)]
    if tile_type != "":
        self.step_data["details"]["type"] = tile_type

    return self.step_data


func _on_picker_button_pressed() -> void:
    self.audio.play("menu_click")

    var vip_position: Variant = null
    if self.step_data["details"].has("where"):
        vip_position = self.step_data["details"]["where"]

    self.picker_requested.emit({
        "type": "position",
        "position": vip_position,
        "step_no": self.step_no
    })

func _handle_picker_response(response: Variant, context: Dictionary) -> void:
    super._handle_picker_response(response, context)
    if context["type"] == "position":
        $"where/x".set_text(str(response.x))
        $"where/y".set_text(str(response.y))
    if context["type"] == "tile_type":
        $"tile_type/tile_type".set_text(response)
    _emit_updated_signal()


func _on_type_picker_button_pressed() -> void:
    self.audio.play("menu_click")

    self.picker_requested.emit({
        "type": "tile_type",
        "step_no": self.step_no
    })


func _on_explosion_button_pressed() -> void:
    self.audio.play("menu_click")
    if not self.step_data["details"].has("explosion"):
        self.step_data["details"]["explosion"] = false
    self.step_data["details"]["explosion"] = not self.step_data["details"]["explosion"]
    if self.step_data["details"]["explosion"]:
        $"explosion/explosion_button/label".set_text("TR_ON")
    else:
        $"explosion/explosion_button/label".set_text("TR_OFF")
    _emit_updated_signal()
