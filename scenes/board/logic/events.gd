class_name Events

var observers: Array[Observer] = []

func register_observer(observer_object: Observer) -> void:
    self.observers.append(observer_object)

func emit_event(event_object: BoardDomainEvent) -> void:
    for observer: Observer in self.observers:
        if observer.suspended:
            continue
        if not is_instance_of(event_object, observer.observed_event_type):
            continue
        observer.observe(event_object)
