extends BaseOutcome

var steps: Array[BaseOutcome] = []

func _execute(metadata: Dictionary[String, Variant]) -> void:
    self.board.map.camera.script_operated = true
    for step: BaseOutcome in steps:
        while self.board.ui.is_panel_open():
            await self.board.get_tree().create_timer(0.1).timeout
        step.execute(metadata)

        if step.delay > 0:
            await self.board.get_tree().create_timer(step.delay).timeout

    self.board.map.camera.script_operated = false

func add_step(step: BaseOutcome) -> void:
    self.steps.append(step)
