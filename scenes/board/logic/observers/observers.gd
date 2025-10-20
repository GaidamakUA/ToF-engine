class_name Observers

var board: Board
var basic_observers: Array[Resource] = [
    preload("res://scenes/board/logic/observers/experience.gd"),
    preload("res://scenes/board/logic/observers/hero_spawn.gd"),
]

func _init(_board: Board) -> void:
    self.board = _board
    self._register_basic_observers()

func _register_basic_observers() -> void:
    for template: Resource in self.basic_observers:
        var observer: Observer = template.new(self.board)
        self.board.events.register_observer(observer.observed_event_type, observer, 'observe')
