extends BaseStepActionEditor

func fill_step_data(new_step_no: int, new_step_data: Dictionary) -> void:
	super.fill_step_data(new_step_no, new_step_data)
	
	$"vip/x".set_text("")
	$"vip/y".set_text("")
	$"pause/pause_button/label".set_text("TR_OFF")
	
	if self.step_data.has("details"):
		if self.step_data["details"].has("who"):
			$"vip/x".set_text(str(self.step_data["details"]["who"][0]))
			$"vip/y".set_text(str(self.step_data["details"]["who"][1]))

		if self.step_data["details"].has("pause"):
			if self.step_data["details"]["pause"]:
				$"pause/pause_button/label".set_text("TR_ON")
			else:
				$"pause/pause_button/label".set_text("TR_OFF")

func _compile_step_data() -> Dictionary:
	self.step_data = super._compile_step_data()
	
	var x: String = $"vip/x".get_text()
	var y: String = $"vip/y".get_text()
	var pause: bool = false

	if self.step_data["details"].has("pause"):
		pause = self.step_data["details"]["pause"]

	self.step_data["details"] = {
		"pause": pause
	}

	if x != "" and y != "":
		self.step_data["details"]["who"] = [int(x), int(y)]

	return self.step_data


func _on_picker_button_pressed() -> void:
	self.audio.play("menu_click")

	var vip_position: Variant = null
	if self.step_data["details"].has("who"):
		vip_position = self.step_data["details"]["who"]

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
	_emit_updated_signal()

func _on_pause_button_pressed() -> void:
	self.audio.play("menu_click")
	if not self.step_data["details"].has("pause"):
		self.step_data["details"]["pause"] = false
	self.step_data["details"]["pause"] = not self.step_data["details"]["pause"]
	if self.step_data["details"]["pause"]:
		$"pause/pause_button/label".set_text("TR_ON")
	else:
		$"pause/pause_button/label".set_text("TR_OFF")
	_emit_updated_signal()
