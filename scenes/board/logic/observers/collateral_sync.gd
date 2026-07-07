extends Observer
class_name CollateralSyncObserver


func _init(_board: Board) -> void:
	super(_board)
	self.observed_event_type = CollateralDamageAppliedEvent


func _observe(event: BaseEvent) -> void:
	if not event is CollateralDamageAppliedEvent:
		return
	self.board._sync_collateral_damage(event as CollateralDamageAppliedEvent)
