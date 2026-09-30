extends BaseOutcome
class_name StoryOutcome

var steps: Array[BaseOutcome] = []

func _execute(metadata: Dictionary[String, Variant]) -> void:
    self.model.queue_story(self, metadata)


func run(metadata: Dictionary[String, Variant]) -> void:
    await self._present_and_wait(LockPresentationEvent.new(
        LockPresentationEvent.Target.STORY, true
    ))
    for step: BaseOutcome in steps:
        step.execute(metadata)
        await self.model.wait_for_command()
        if step.delay > 0:
            await self._present_and_wait(DelayPresentationEvent.new(step.delay))
    await self._present_and_wait(LockPresentationEvent.new(
        LockPresentationEvent.Target.STORY, false
    ))


func _present_and_wait(event: ScriptPresentationEvent) -> void:
    self.model.request_presentation(event)
    await self.model.wait_for_command()

func add_step(step: BaseOutcome) -> void:
    self.steps.append(step)
