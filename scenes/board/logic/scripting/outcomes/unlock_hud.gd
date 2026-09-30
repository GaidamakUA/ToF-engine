extends BaseOutcome
class_name UnlockHudOutcome


func _init() -> void:
    self.delay = 0.3

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    self.model.request_presentation(LockPresentationEvent.new(
        LockPresentationEvent.Target.HUD, false
    ))
