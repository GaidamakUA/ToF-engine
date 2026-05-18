extends Node2D
class_name SavesPanel

const PAGE_SIZE: int = 10

@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var animations: AnimationPlayer = $"animations"

@onready var save_button: TextureButton = $"widgets/save_button"
@onready var load_button: TextureButton = $"widgets/load_button"
@onready var new_save_button: TextureButton = $"widgets/new_save_button"
@onready var cancel_button: TextureButton = $"widgets/cancel_button"
@onready var next_button: TextureButton = $"widgets/list_next"
@onready var prev_button: TextureButton = $"widgets/list_prev"

@onready var campaign: CampaignService = Campaign as CampaignService
@onready var saves_manager: SavesManagerService = SavesManager as SavesManagerService
@onready var gamepad_adapter: GamepadAdapterService = GamepadAdapter as GamepadAdapterService

@onready var switcher: SceneSwitcherService = SceneSwitcher as SceneSwitcherService
@onready var match_setup: MatchSetupData = MatchSetup as MatchSetupData

@onready var entry_buttons: Array[SaveEntryButton] = [
    $"widgets/save_list/entry0" as SaveEntryButton,
    $"widgets/save_list/entry1" as SaveEntryButton,
    $"widgets/save_list/entry2" as SaveEntryButton,
    $"widgets/save_list/entry3" as SaveEntryButton,
    $"widgets/save_list/entry4" as SaveEntryButton,
    $"widgets/save_list/entry5" as SaveEntryButton,
    $"widgets/save_list/entry6" as SaveEntryButton,
    $"widgets/save_list/entry7" as SaveEntryButton,
    $"widgets/save_list/entry8" as SaveEntryButton,
    $"widgets/save_list/entry9" as SaveEntryButton,
]

var bound_success_object: Object = null
var bound_success_method: StringName = &""
var bound_success_args: Array = []

var bound_cancel_object: Object = null
var bound_cancel_method: StringName = &""
var bound_cancel_args: Array = []

var board: Board

var save_mode: bool = true
var current_page: int = 0
var selected_save_id: Variant = null


func _ready() -> void:
    self.set_process_input(false)
    for button: SaveEntryButton in self.entry_buttons:
        button.bind_method(self, &"entry_button_pressed")

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") or event.is_action_pressed('editor_menu'):
        self.execute_cancel()
    if event.is_action_pressed("ui_page_down"):
        self.switch_to_next_page()
        if self.entry_buttons[0].is_visible():
            self.entry_buttons[0].grab_focus()
    if event.is_action_pressed("ui_page_up"):
        self.switch_to_prev_page()
        if self.entry_buttons[0].is_visible():
            self.entry_buttons[0].grab_focus()

func clear_binds() -> void:
    self.bound_success_object = null
    self.bound_success_method = &""
    self.bound_success_args = []
    self.bound_cancel_object = null
    self.bound_cancel_method = &""
    self.bound_cancel_args = []

func bind_success(success_object: Object, success_method: StringName, success_args: Array = []) -> void:
    self.bound_success_object = success_object
    self.bound_success_method = success_method
    self.bound_success_args = success_args

func bind_cancel(cancel_object: Object, cancel_method: StringName, cancel_args: Array = []) -> void:
    self.bound_cancel_object = cancel_object
    self.bound_cancel_method = cancel_method
    self.bound_cancel_args = cancel_args

func execute_new_save() -> void:
    self.audio.play("menu_click")
    var save_data: Dictionary = self.saves_manager.compile_save_data(self.board)
    self.saves_manager.add_new_save(
        str(save_data["map_name"]),
        str(save_data["map_label"]),
        int(save_data["turn_no"]),
        save_data["save_data"] as Dictionary
    )
    self.current_page = 0
    self.refresh_current_entries_page()

func save_pressed() -> void:
    if self.selected_save_id == null:
        return
    self.audio.play("menu_click")
    self.save_state_to_id(int(self.selected_save_id))
    self.refresh_current_entries_page()

func load_pressed() -> void:
    if self.selected_save_id == null:
        return
    self.audio.play("menu_click")
    self.load_state_from_id(int(self.selected_save_id))

func entry_button_pressed(save_id: int, button: SaveEntryButton) -> void:
    self.audio.play("menu_click")
    self.selected_save_id = save_id

    for entry_button: SaveEntryButton in self.entry_buttons:
        if entry_button != button:
            entry_button.hide_stars()

    self.load_button.show()
    if self.save_mode:
        self.save_button.show()
    await self.get_tree().create_timer(0.1).timeout
    self.load_button.grab_focus()

func execute_cancel() -> void:
    self.audio.play("menu_back")
    if self.bound_cancel_object != null:
        if self.bound_cancel_args.size() > 0:
            self.bound_cancel_object.call_deferred(self.bound_cancel_method, self.bound_cancel_args)
        else:
            self.bound_cancel_object.call_deferred(self.bound_cancel_method)

func execute_success(map_name: String, context: Variant = null) -> void:
    self.audio.play("menu_click")
    if self.bound_success_object != null:
        var args: Array = [] + self.bound_success_args

        args.append(map_name)
        args.append(context)
        self.bound_success_object.call_deferred(self.bound_success_method, args)

func show_saves(set_save_mode: bool) -> void:
    self.animations.play("show")
    self.set_process_input(true)

    self.save_mode = set_save_mode

    self.save_button.hide()
    self.load_button.hide()

    if self.save_mode:
        self.new_save_button.show()
    else:
        self.new_save_button.hide()

    self.refresh_current_entries_page()
    await self.get_tree().create_timer(0.1).timeout
    if self.entry_buttons[0].is_visible():
        self.entry_buttons[0].grab_focus()
    elif self.save_mode:
        self.new_save_button.grab_focus()
    else:
        self.cancel_button.grab_focus()

    self.gamepad_adapter.enable()


func hide_saves() -> void:
    self.animations.play("hide")
    self.set_process_input(false)
    self.gamepad_adapter.disable()

func refresh_current_entries_page() -> void:
    var pages_count: int = self.saves_manager.get_pages_count(self.PAGE_SIZE)

    if self.current_page == 0 || pages_count < 2:
        self.prev_button.hide()
    elif self.current_page > 0:
        self.prev_button.show()


    if self.current_page == pages_count - 1 || pages_count < 2:
        self.next_button.hide()
    elif self.current_page < pages_count - 1:
        self.next_button.show()

    self.selected_save_id = null
    self.save_button.hide()
    self.load_button.hide()
    for entry_button: SaveEntryButton in self.entry_buttons:
        entry_button.hide()
        entry_button.hide_stars()

    var entries_page: Array[Dictionary] = self.saves_manager.get_entries_page(self.current_page, self.PAGE_SIZE)
    var entry: Dictionary

    for index: int in range(entries_page.size()):
        entry = entries_page[index]
        self.entry_buttons[index].fill_data(
            str(entry["label"]),
            int(entry["save_id"]),
            int(entry["turn"]),
            entry["created_at"] as Dictionary
        )
        self.entry_buttons[index].show()

func switch_to_prev_page() -> void:
    self.audio.play("menu_click")
    if self.current_page > 0:
        self.current_page -= 1

    self.refresh_current_entries_page()

    if self.current_page == 0:
        if self.next_button.is_visible():
            self.next_button.grab_focus()


func switch_to_next_page() -> void:
    self.audio.play("menu_click")
    var pages_count: int = self.saves_manager.get_pages_count(self.PAGE_SIZE)

    if self.current_page < pages_count - 1:
        self.current_page += 1

    self.refresh_current_entries_page()

    if self.current_page == pages_count - 1:
        if self.prev_button.is_visible():
            self.prev_button.grab_focus()

func save_state_to_id(save_id: int) -> void:
    var save_data: Dictionary = self.saves_manager.compile_save_data(self.board)

    self.saves_manager.overwrite_save(
        str(save_data["map_name"]),
        str(save_data["map_label"]),
        int(save_data["turn_no"]),
        save_data["save_data"] as Dictionary,
        save_id
    )

func perform_autosave() -> void:
    var save_data: Dictionary = self.saves_manager.compile_save_data(self.board)
    save_data["map_label"] = tr("TR_AUTOSAVE") + " - " + str(save_data["map_label"])

    self.saves_manager.write_autosave(
        str(save_data["map_name"]),
        str(save_data["map_label"]),
        int(save_data["turn_no"]),
        save_data["save_data"] as Dictionary
    )

func load_state_from_id(save_id: int) -> void:
    var save_data: Dictionary = self.saves_manager.get_save_data(save_id)
    self.match_setup.reset()

    self.match_setup.restore_save_id = save_id
    self.match_setup.map_name = save_data["map_name"]
    self.match_setup.campaign_name = save_data["campaign_name"]
    self.match_setup.mission_no = int(save_data["mission_no"])
    var initial_setup: Array[Dictionary]
    initial_setup.assign(save_data["initial_setup"])
    self.match_setup.stored_setup = initial_setup
    var players: Array = save_data["players"] as Array
    for player: Dictionary in players:
        self.match_setup.add_player(
            str(player["side"]),
            int(player["ap"]),
            str(player["type"]),
            bool(player["alive"]),
            player["team"]
        )

    self.gamepad_adapter.disable()
    self.switcher.board()
