extends BaseStepActionEditor

func fill_step_data(new_step_no: int, new_step_data: Dictionary) -> void:
    super.fill_step_data(new_step_no, new_step_data)

    $"where/x".set_text("")
    $"where/y".set_text("")
    $"unit_type/unit_type_input".set_text("")
    $"player_side/side".set_text("")
    $"rotation/rotation".set_text("")
    $"hp/hp".set_text("")
    $"sound/sound_button/label".set_text("TR_ON")
    $"promote/promote_button/label".set_text("TR_OFF")

    if self.step_data.has("details"):
        if self.step_data["details"].has("where"):
            $"where/x".set_text(str(self.step_data["details"]["where"][0]))
            $"where/y".set_text(str(self.step_data["details"]["where"][1]))

        if self.step_data["details"].has("template"):
            $"unit_type/unit_type_input".set_text(self.step_data["details"]["template"])

        if self.step_data["details"].has("side"):
            $"player_side/side".set_text(self.step_data["details"]["side"])

        if self.step_data["details"].has("rotation"):
            $"rotation/rotation".set_text(str(self.step_data["details"]["rotation"]))

        if self.step_data["details"].has("hp"):
            $"hp/hp".set_text(str(self.step_data["details"]["hp"]))

        if self.step_data["details"].has("sound"):
            if self.step_data["details"]["sound"]:
                $"sound/sound_button/label".set_text("TR_ON")
            else:
                $"sound/sound_button/label".set_text("TR_OFF")

        if self.step_data["details"].has("promote"):
            if self.step_data["details"]["promote"]:
                $"promote/promote_button/label".set_text("TR_ON")
            else:
                $"promote/promote_button/label".set_text("TR_OFF")

func build_step_label(requested_step_data: Dictionary) -> String:
    var label: String = requested_step_data["action"]
    if requested_step_data.has("details"):
        if requested_step_data["details"].has("template"):
            label += " " + requested_step_data["details"]["template"]
    return label

func _compile_step_data() -> Dictionary:
    self.step_data = super._compile_step_data()

    var x: String = $"where/x".get_text()
    var y: String = $"where/y".get_text()
    var unit_type: String = $"unit_type/unit_type_input".get_text()
    var player_side: String = $"player_side/side".get_text()
    var unit_rotation: String = $"rotation/rotation".get_text()
    var hp: String = $"hp/hp".get_text()
    var sound: bool = true
    var promote: bool = false

    if self.step_data["details"].has("sound"):
        sound = self.step_data["details"]["sound"]
    if self.step_data["details"].has("promote"):
        promote = self.step_data["details"]["promote"]

    self.step_data["details"] = {
        "sound": sound,
        "promote": promote
    }

    if x != "" and y != "":
        self.step_data["details"]["where"] = [int(x), int(y)]
    if unit_type != "":
        self.step_data["details"]["template"] = unit_type
    if player_side != "":
        self.step_data["details"]["side"] = player_side
    if unit_rotation != "":
        self.step_data["details"]["rotation"] = int(unit_rotation)
    if hp != "":
        self.step_data["details"]["hp"] = int(hp)

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

func _on_unit_picker_button_pressed() -> void:
    self.audio.play("menu_click")

    self.picker_requested.emit({
        "type": "unit_type",
        "step_no": self.step_no
    })

func _on_side_picker_button_pressed() -> void:
    self.audio.play("menu_click")

    self.picker_requested.emit({
        "type": "side",
        "step_no": self.step_no
    })

func _handle_picker_response(response: Variant, context: Dictionary) -> void:
    super._handle_picker_response(response, context)
    if context["type"] == "position":
        $"where/x".set_text(str(response.x))
        $"where/y".set_text(str(response.y))
    if context["type"] == "unit_type":
        $"unit_type/unit_type_input".set_text(response)
    if context["type"] == "side":
        $"player_side/side".set_text(response)
    _emit_updated_signal()


func _on_sound_button_pressed() -> void:
    self.audio.play("menu_click")
    if not self.step_data["details"].has("sound"):
        self.step_data["details"]["sound"] = true
    self.step_data["details"]["sound"] = not self.step_data["details"]["sound"]
    if self.step_data["details"]["sound"]:
        $"sound/sound_button/label".set_text("TR_ON")
    else:
        $"sound/sound_button/label".set_text("TR_OFF")
    _emit_updated_signal()


func _on_promote_button_pressed() -> void:
    self.audio.play("menu_click")
    if not self.step_data["details"].has("promote"):
        self.step_data["details"]["promote"] = false
    self.step_data["details"]["promote"] = not self.step_data["details"]["promote"]
    if self.step_data["details"]["promote"]:
        $"promote/promote_button/label".set_text("TR_ON")
    else:
        $"promote/promote_button/label".set_text("TR_OFF")
    _emit_updated_signal()
