extends AbstractAction
class_name ReserveApAction

var amount: int = 0

func _init(ap_amount: int) -> void:
    self.amount = ap_amount

func perform(board: Board) -> void:
    board.ai.reserve_ap(self.amount)

func _to_string() -> String:
    return "Reserved AP for next turn: " + str(self.amount)
