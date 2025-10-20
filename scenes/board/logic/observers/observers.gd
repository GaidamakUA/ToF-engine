class_name Observers

func _init(board: Board) -> void:
    self._register_basic_observers(board)

func _register_basic_observers(board: Board) -> void:
    var hero_spawn_observer := HeroSpawnObserver.new(board)
    board.events.register_observer(hero_spawn_observer)
    var experience_observer := ExperienceObserver.new(board)
    board.events.register_observer(experience_observer)
