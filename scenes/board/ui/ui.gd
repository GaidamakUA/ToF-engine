extends Control
class_name Ui

@onready var settings: SettingsService = Settings as SettingsService
@onready var gamepad_adapter: GamepadAdapterService = GamepadAdapter as GamepadAdapterService

# Panels
@onready var radial: Radial = $"radial/radial"
@onready var resource: Element3DView = $"resources/coin_view"
@onready var resource_label: Label = $"resources/coin_view/label"
@onready var summary: SummaryView = $"summary/summary_view"
@onready var end_turn: EndTurnView = $"end_turn/end_turn"
@onready var end_turn_confirm: EndTurnConfirmPanel = $"end_turn_confirm/end_turn_confirm"
@onready var start_turn: StartTurnView = $"start_turn/start_turn"
@onready var story_dialog: StoryDialogPanel = $"story_dialog/story_dialog"
@onready var cinematic_bars: CinematicBars = $"cinematic_bars/cinematic_bars"
@onready var unit_stats: UnitStatsPanel = $"unit_stats/unit_stats"
@onready var objectives: ObjectivesUi = $"objectives/objectives"
@onready var ap_depleted: ApDepletedView = $"ap_depleted/ap_depleted"
@onready var saves: SavesPanel = $"saves/saves"
@onready var settings_panel: MainMenuSettingsPanel = $"settings/settings"
@onready var controls: Control = $"controls/game"
@onready var turn_timer: TurnTimeView = $"TurnTime"

# Tile highlight
@onready var tile_highlight: TileView = $"tile_highlight/tile_view"
@onready var tile_highlight_level1: Node2D = $"tile_highlight/level1"
@onready var tile_highlight_level2: Node2D = $"tile_highlight/level2"
@onready var tile_highlight_level3: Node2D = $"tile_highlight/level3"
@onready var tile_highlight_unit_panel_hp: Label = $"tile_highlight/tile_view/hp"

# Tile highlight abilities
@onready var ab1: Node2D = $"tile_highlight/abilities/ab1"
@onready var ab1_anchor: Node2D = $"tile_highlight/abilities/ab1/anchor"
@onready var ab1_name: Label = $"tile_highlight/abilities/ab1/label"
@onready var ab1_disabled: Sprite2D = $"tile_highlight/abilities/ab1/disabled"
@onready var ab1_cd: Label = $"tile_highlight/abilities/ab1/disabled/cd"
@onready var ab2: Node2D = $"tile_highlight/abilities/ab2"
@onready var ab2_anchor: Node2D = $"tile_highlight/abilities/ab2/anchor"
@onready var ab2_name: Label = $"tile_highlight/abilities/ab2/label"
@onready var ab2_disabled: Sprite2D = $"tile_highlight/abilities/ab2/disabled"
@onready var ab2_cd: Label = $"tile_highlight/abilities/ab2/disabled/cd"
@onready var ab3: Node2D = $"tile_highlight/abilities/ab3"
@onready var ab3_anchor: Node2D = $"tile_highlight/abilities/ab3/anchor"
@onready var ab3_name: Label = $"tile_highlight/abilities/ab3/label"
@onready var ab3_disabled: Sprite2D = $"tile_highlight/abilities/ab3/disabled"
@onready var ab3_cd: Label = $"tile_highlight/abilities/ab3/disabled/cd"
var ability_icons: Array[Node] = [null, null, null]

# Edge pan
@onready var edge_pan_left: Control = $"edge_pan/left"
@onready var edge_pan_right: Control = $"edge_pan/right"
@onready var edge_pan_top: Control = $"edge_pan/top"
@onready var edge_pan_bottom: Control = $"edge_pan/bottom"

@onready var hover_menu: HoverMenu = $"buttons/hover_menu"


var icons: IconsFactory = IconsFactory.new()

func _ready() -> void:
    self.show_controls()
    self.settings.changed.connect(self._on_settings_changed)
    self.turn_timer.turn_timeout.connect(self.turn_timer.hide)

func is_popup_open() -> bool:
    if self.summary.is_visible():
        return true

    if self.story_dialog.is_visible():
        return true

    if self.end_turn_confirm.is_visible():
        return true

    if self.unit_stats.is_visible():
        return true

    if self.saves.is_visible():
        return true

    if self.settings_panel.is_visible():
        return true

    return false

func is_panel_open() -> bool:
    if self.is_radial_open():
        return true
    if self.is_popup_open():
        return true

    return false

func is_radial_open() -> bool:
    return self.radial.is_visible()

func show_radial() -> void:
    self.radial.show_menu()

func hide_radial() -> void:
    self.radial.hide_menu()

func toggle_radial() -> void:
    if self.radial.is_visible():
        self.hide_radial()
    else:
        self.show_radial()

func update_resource_value(value: int) -> void:
    self.resource_label.set_text(str(value))
    if value == 0:
        self.resource.flash()
    else:
        self.resource.stop_flash()

func update_tile_highlight(tile_preview: MapObject) -> void:
    self.clear_tile_highlight()
    if self.cinematic_bars.is_extended:
        return

    self.tile_highlight.show()
    self.tile_highlight.set_tile(tile_preview, 0)

func update_tile_highlight_unit_panel(unit: BaseUnit, board: Board) -> void:
    if self.cinematic_bars.is_extended:
        return
    self.tile_highlight_unit_panel_hp.set_text(str(unit.hp) + "/" + str(unit.max_hp))

    match unit.level:
        1:
            self.tile_highlight_level1.show()
        2:
            self.tile_highlight_level2.show()
        3:
            self.tile_highlight_level3.show()
    self._show_active_abilities(unit, board)

func _show_active_abilities(unit: BaseUnit, board: Board) -> void:
    if not unit.has_active_ability():
        return

    var index: int = 0

    for ability: Ability in unit.active_abilities:
        if ability.is_visible(board):
            if index > 2:
                return
            self._bind_ability(index, ability)
            index += 1

func _bind_ability(index: int, ability: Ability) -> void:
    var boxes: Array[Node2D] = [
        self.ab1,
        self.ab2,
        self.ab3
    ]
    var anchors: Array[Node2D] = [
        self.ab1_anchor,
        self.ab2_anchor,
        self.ab3_anchor,
    ]
    var labels: Array[Label] = [
        self.ab1_name,
        self.ab2_name,
        self.ab3_name,
    ]
    var disabled: Array[Sprite2D] = [
        self.ab1_disabled,
        self.ab2_disabled,
        self.ab3_disabled,
    ]
    var cooldowns: Array[Label] = [
        self.ab1_cd,
        self.ab2_cd,
        self.ab3_cd,
    ]

    boxes[index].show()
    var icon: Node = self.icons.get_named_icon(ability.named_icon)
    if icon != null:
        anchors[index].add_child(icon)
    self.ability_icons[index] = icon
    labels[index].set_text(ability.label)

    if ability.cd_turns_left > 0:
        disabled[index].show()
        cooldowns[index].set_text(str(ability.cd_turns_left))
    else:
        disabled[index].hide()

func update_tile_highlight_building_panel(ap_gain: int) -> void:
    self.tile_highlight_unit_panel_hp.set_text("+" + str(ap_gain))

func hide_resource() -> void:
    self.resource.hide()

func clear_tile_highlight() -> void:
    self.tile_highlight.clear()
    self.tile_highlight.hide()
    self.tile_highlight_level1.hide()
    self.tile_highlight_level2.hide()
    self.tile_highlight_level3.hide()
    self.tile_highlight_unit_panel_hp.set_text("")
    self.ab1.hide()
    self.ab2.hide()
    self.ab3.hide()

    if self.ability_icons[0] != null:
        self.ability_icons[0].queue_free()
    if self.ability_icons[1] != null:
        self.ability_icons[1].queue_free()
    if self.ability_icons[2] != null:
        self.ability_icons[2].queue_free()
    self.ability_icons = [null, null, null]

func show_summary(winner: String) -> void:
    self.summary.configure_winner(winner)
    self.summary.show()

func show_end_turn() -> void:
    self.ap_depleted.hide()
    self.end_turn.show()

func hide_end_turn() -> void:
    self.end_turn.hide()
    self.end_turn.reset()

func update_end_turn_progress(value: float) -> void:
    self.end_turn.set_progress(value)

func flash_start_end_card(player: String, turn: int) -> void:
    self.start_turn.flash(player, turn)

func show_story_dialog(text: String, actor: Dictionary[String, Variant], font_size: int = 16) -> void:
    self.story_dialog.set_text(text)
    self.story_dialog.set_actor(actor)
    self.story_dialog.set_font_size(font_size)
    self.story_dialog.show_panel()

func hide_story_dialog() -> void:
    self.story_dialog.hide()

func show_cinematic_bars() -> void:
    self.clear_tile_highlight()
    self.cinematic_bars.show_bars()
    self.hide_controls()

func hide_cinematic_bars() -> void:
    self.cinematic_bars.hide_bars()
    self.show_controls()

func are_cinematic_bars_visible() -> bool:
    return self.cinematic_bars.is_extended

func show_unit_stats(unit: BaseUnit, tile_preview: MapObject, board: Board) -> void:
    self.unit_stats.bind_unit(unit, tile_preview, board)
    self.unit_stats.show_panel()
    self.hide_controls()

func hide_unit_stats() -> void:
    self.unit_stats.hide()
    self.show_controls()

func show_objectives() -> void:
    self.objectives.fade_in()

func hide_objectives() -> void:
    self.objectives.fade_out()

func show_saves() -> void:
    self.saves.show_saves(true)

func hide_saves() -> void:
    self.saves.hide_saves()

func show_controls() -> void:
    if self.settings.get_option("show_controls"):
        self.controls.show()

func hide_controls() -> void:
    self.controls.hide()

func show_settings() -> void:
    self.settings_panel.show_panel()
    self.settings_panel.hide_controls_button()
    self.gamepad_adapter.enable()

func hide_settings() -> void:
    self.settings_panel.hide_panel()
    self.gamepad_adapter.disable()

func _on_settings_changed(key: String, new_value: Variant) -> void:
    if key == "show_controls":
        if new_value:
            self.show_controls()
        else:
            self.hide_controls()


func start_turn_timer(seconds: int) -> void:
    turn_timer.start_timer(seconds)
    turn_timer.show()


func reset_timer() -> void:
    turn_timer.reset()
    turn_timer.hide()
