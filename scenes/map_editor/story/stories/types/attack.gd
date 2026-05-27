extends BaseStepActionEditor

func fill_step_data(new_step_no: int, new_step_data: Dictionary) -> void:
    super.fill_step_data(new_step_no, new_step_data)
    
    $"who/x".set_text("")
    $"who/y".set_text("")
    $"whom/x".set_text("")
    $"whom/y".set_text("")
    $"damage/damage".set_text("")
    
    if self.step_data.has("details"):
        if self.step_data["details"].has("who"):
            $"who/x".set_text(str(self.step_data["details"]["who"][0]))
            $"who/y".set_text(str(self.step_data["details"]["who"][1]))
        if self.step_data["details"].has("whom"):
            $"whom/x".set_text(str(self.step_data["details"]["whom"][0]))
            $"whom/y".set_text(str(self.step_data["details"]["whom"][1]))

        if self.step_data["details"].has("damage"):
            $"damage/damage".set_text(str(self.step_data["details"]["damage"]))

func _compile_step_data() -> Dictionary:
    self.step_data = super._compile_step_data()
    
    var x1: String = $"who/x".get_text()
    var y1: String = $"who/y".get_text()
    var x2: String = $"whom/x".get_text()
    var y2: String = $"whom/y".get_text()
    var damage: String = $"damage/damage".get_text()

    self.step_data["details"] = {}

    if x1 != "" and y1 != "":
        self.step_data["details"]["who"] = [int(x1), int(y1)]
    if x2 != "" and y2 != "":
        self.step_data["details"]["whom"] = [int(x2), int(y2)]

    if damage != "":
        self.step_data["details"]["damage"] = int(damage)

    return self.step_data

func _handle_picker_response(response: Variant, context: Dictionary) -> void:
    super._handle_picker_response(response, context)
    if context["type"] == "position":
        if context.has("field_id"):
            if context["field_id"] == "who":
                _handle_picker_response_for_fields($"who/x", $"who/y", response)
            if context["field_id"] == "whom":
                _handle_picker_response_for_fields($"whom/x", $"whom/y", response)


func _handle_picker_response_for_fields(input_x: LineEdit, input_y: LineEdit, response: Variant) -> void:
    input_x.set_text(str(response.x))
    input_y.set_text(str(response.y))
    _emit_updated_signal()


func _on_who_picker_button_pressed() -> void:
    _request_picker_for_fields("who", $"who/x", $"who/y")


func _on_whom_picker_button_pressed() -> void:
    _request_picker_for_fields("whom", $"whom/x", $"whom/y")

func _request_picker_for_fields(identifier: String, input_x: LineEdit, input_y: LineEdit) -> void:
    var x: String = input_x.get_text()
    var y: String = input_y.get_text()

    var current_position: Variant = null
    if x != "" and y != "":
        current_position = [int(x), int(y)]

    self.picker_requested.emit({
        "type": "position",
        "position": current_position,
        "step_no": self.step_no,
        "field_id": identifier
    })
