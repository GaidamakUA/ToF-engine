class_name Scripting
var board: Board
var scripts: Variant = null

var triggers: Dictionary[String, BaseTrigger] = {}
var trigger_groups: Dictionary[String, Dictionary] = {}

var trigger_factory: TriggerFactory = TriggerFactory.new()
var outcome_factory: OutcomeFactory = OutcomeFactory.new()

func ingest_scripts(board_object: Board, incoming_scripts: Variant) -> void:
    self.board = board_object
    self.scripts = incoming_scripts

    if self.scripts == null or self.scripts.is_empty() or self.scripts['triggers'].is_empty():
        self._setup_basic_win_condition()
    else:
        for trigger_name: String in self.scripts['triggers']:
            var trigger_definition: Dictionary[String, Variant] = {}
            trigger_definition.assign(self.scripts['triggers'][trigger_name])

            if _is_trigger_valid(trigger_definition):
                self.triggers[trigger_name] = self._setup_trigger(trigger_definition)
            else:
                print("Invalid trigger: ", trigger_name)

func _setup_basic_win_condition() -> void:
    self._build_hq_lost_event(self.board.map.templates.MODERN_HQ)
    self._build_hq_lost_event(self.board.map.templates.STEAMPUNK_HQ)
    self._build_hq_lost_event(self.board.map.templates.FUTURISTIC_HQ)
    self._build_hq_lost_event(self.board.map.templates.FEUDAL_HQ)
    self.board.ui.objectives.set_objective_slot(0, "Capture enemy HQ")

func _build_hq_lost_event(hq_type: String) -> void:
    var trigger: BuildingLostTrigger = BuildingLostTrigger.new()
    var outcome: EliminatePlayerOutcome = EliminatePlayerOutcome.new()

    trigger.outcome = outcome
    trigger.building_type = hq_type

    outcome.board = self.board

    self.board.events.register_observer(trigger)

func _is_trigger_valid(trigger_definition: Dictionary[String, Variant]) -> bool:
    if trigger_definition['type'] == null or trigger_definition['story'] == null:
        return false
    return true

func _setup_trigger(trigger_definition: Dictionary[String, Variant]) -> BaseTrigger:
    var new_trigger: BaseTrigger = self.trigger_factory.get_trigger(String(trigger_definition['type']))
    new_trigger.outcome = self._build_outcome_story(String(trigger_definition['story']))

    new_trigger.board = self.board
    var details: Dictionary[String, Variant] = {}
    details.assign(trigger_definition['details'])
    new_trigger.ingest_details(details)

    if trigger_definition.has('one_off'):
        new_trigger.one_off = bool(trigger_definition['one_off'])

    self.board.events.register_observer(new_trigger)

    return new_trigger

func _build_outcome_story(story_name: String) -> StoryOutcome:
    var story_definition: Array = []
    story_definition.assign(self.scripts['stories'][story_name])
    var new_story: StoryOutcome = StoryOutcome.new()
    new_story.board = self.board

    for step_data: Dictionary in story_definition:
        var step: Dictionary[String, Variant] = {}
        step.assign(step_data)
        new_story.add_step(self._build_outcome_story_step(step))

    return new_story

func _build_outcome_story_step(step_definition: Dictionary[String, Variant]) -> BaseOutcome:
    var new_step: BaseOutcome = self.outcome_factory.get_outcome(String(step_definition['action']))
    new_step.board = self.board
    if step_definition.has('details'):
        var details: Dictionary[String, Variant] = {}
        details.assign(step_definition['details'])
        new_step.ingest_details(details)
    if step_definition.has('delay'):
        new_step.delay = float(step_definition['delay'])

    return new_step

func suspend_trigger(name: String, state: bool) -> void:
    if self.triggers.has(name):
        self.triggers[name].suspended = state

func add_to_group(group_name: String, trigger_name: String) -> void:
    if not self.trigger_groups.has("group_name"):
        self.trigger_groups[group_name] = {}

    self.trigger_groups[group_name][trigger_name] = true

func remove_from_group(group_name: String, trigger_name: String) -> void:
    if not self.trigger_groups.has("group_name"):
        self.trigger_groups[group_name] = {}

    self.trigger_groups[group_name][trigger_name] = false

func suspend_group(group_name: String, state: bool) -> void:
    if not self.trigger_groups.has("group_name"):
        return

    for trigger_name: String in self.trigger_groups[group_name].keys():
        if self.trigger_groups[group_name][trigger_name]:
            self.suspend_trigger(trigger_name, state)

func get_save_data() -> Dictionary[String, Variant]:
    var trigger_data: Dictionary[String, Variant] = {}

    for trigger_name: String in self.triggers.keys():
        trigger_data[trigger_name] = self.triggers[trigger_name].get_save_data()

    return {
        "triggers": trigger_data,
        "groups": self.trigger_groups
    }

func restore_from_state(state: Dictionary[String, Variant]) -> void:
    self.trigger_groups.clear()
    self.trigger_groups.assign(state["groups"])

    var trigger_states: Dictionary[String, Variant] = {}
    trigger_states.assign(state["triggers"])

    for trigger_name: String in trigger_states.keys():
        var trigger_state: Dictionary[String, Variant] = {}
        trigger_state.assign(trigger_states[trigger_name])
        self.triggers[trigger_name].restore_from_state(trigger_state)
