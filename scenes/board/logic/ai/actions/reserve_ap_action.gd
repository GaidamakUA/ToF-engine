extends AbstractAction
class_name ReserveApAction

var amount: int = 0

func _init(ap_amount: int) -> void:
    self.amount = ap_amount

func perform(model: BoardModel, wait_for_presentation: Callable = Callable()) -> void:
    model.reserve_ap(self.amount)
    if wait_for_presentation.is_valid():
        await wait_for_presentation.call()

func _to_string() -> String:
    return "Reserved AP for next turn: " + str(self.amount)
