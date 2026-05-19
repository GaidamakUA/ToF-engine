extends BaseStepActionEditor

func fill_step_data(new_step_no: int, new_step_data: Dictionary) -> void:
	super.fill_step_data(new_step_no, new_step_data)
	
	$"where/x".set_text("")
	$"where/y".set_text("")
	$"zoom/zoom".set_text("")
	
	if self.step_data.has("details"):
		if self.step_data["details"].has("where"):
			$"where/x".set_text(str(self.step_data["details"]["where"][0]))
			$"where/y".set_text(str(self.step_data["details"]["where"][1]))

		if self.step_data["details"].has("zoom"):
			$"zoom/zoom".set_text(str(self.step_data["details"]["zoom"]))

func _compile_step_data() -> Dictionary:
	self.step_data = super._compile_step_data()
	
	var x: String = $"where/x".get_text()
	var y: String = $"where/y".get_text()
	var zoom: String = $"zoom/zoom".get_text()

	self.step_data["details"] = {}

	if x != "" and y != "":
		self.step_data["details"]["where"] = [int(x), int(y)]
	if zoom != "":
		self.step_data["details"]["zoom"] = float(zoom)

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
	_emit_updated_signal()
