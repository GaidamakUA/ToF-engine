extends Node2D
class_name SummaryView

var board: Board

@onready var menu_button: TextureButton = $"menu_button"
@onready var restart_button: TextureButton = $"restart_button"
@onready var next_mission_button: TextureButton = $"next_mission_button"
@onready var next_mission_button_label: Label = $"next_mission_button/label"

@onready var mission_complete: Label = $"background/mission_complete"
@onready var mission_failed: Label = $"background/mission_failed"

@onready var blue_wins: Label = $"background/blue_wins"
@onready var red_wins: Label = $"background/red_wins"
@onready var green_wins: Label = $"background/green_wins"
@onready var yellow_wins: Label = $"background/yellow_wins"
@onready var black_wins: Label = $"background/black_wins"
@onready var game_draw: Label = $"background/game_draw"

@onready var switcher: SceneSwitcherService = SceneSwitcher as SceneSwitcherService
@onready var gamepad_adapter: GamepadAdapterService = GamepadAdapter as GamepadAdapterService
@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var match_setup: MatchSetupData = MatchSetup as MatchSetupData
@onready var campaign: CampaignService = Campaign as CampaignService
@onready var multiplayer_srv: MultiplayerService = Multiplayer as MultiplayerService

@onready var points_panels: Dictionary[String, SidePointsSummary] = {
    "blue": $"points/HBoxContainer/SummaryViewPoints0",
    "red": $"points/HBoxContainer/SummaryViewPoints1",
    "yellow": $"points/HBoxContainer/SummaryViewPoints2",
    "green": $"points/HBoxContainer/SummaryViewPoints3",
    "black": $"points/HBoxContainer/SummaryViewPoints4",
}

func configure_winner(winner: String) -> void:
    self.gamepad_adapter.enable()
    self.restart_button.show()
    _clear_points()

    if self.match_setup.campaign_win:
        if self.match_setup.has_won:
            self.mission_complete.show()
            self._setup_next_mission()
            self.next_mission_button.grab_focus()
            self.audio.play("fanfare")
        else:
            self.mission_failed.show()
            self.restart_button.grab_focus()
            self.audio.play("failfare")
    else:
        match winner:
            "blue":
                self.blue_wins.show()
            "red":
                self.red_wins.show()
            "yellow":
                self.yellow_wins.show()
            "green":
                self.green_wins.show()
            "black":
                self.black_wins.show()
            "none":
                self.game_draw.show()
                self._show_points()

        self.menu_button.grab_focus()
        self.audio.play("fanfare")

func disable_restart() -> void:
    self.restart_button.hide()
    self.menu_button.grab_focus()

func _setup_next_mission() -> void:
    self.next_mission_button.show()
    if self.campaign.is_campaign_complete(self.match_setup.campaign_name):
        self.next_mission_button_label.set_text("TR_FINISH")

func _on_menu_button_pressed() -> void:
    self.gamepad_adapter.disable()
    self.match_setup.reset()
    self.multiplayer_srv.close_game()
    self.switcher.main_menu()
    self.audio.play("menu_click")


func _on_restart_button_pressed() -> void:
    self.gamepad_adapter.disable()
    if self.match_setup.restore_save_id != null:
        self.match_setup.restore_save_id = null
        self.match_setup.restore_setup()
    self.match_setup.has_won = false
    self.switcher.board()
    self.audio.play("menu_click")

func _on_next_mission_button_pressed() -> void:
    if self.campaign.is_campaign_complete(self.match_setup.campaign_name):
        self.match_setup.animate_medal = true
    self.gamepad_adapter.disable()
    self.switcher.main_menu()
    self.audio.play("menu_click")


func _clear_points() -> void:
    for panel: SidePointsSummary in points_panels.values():
        panel.hide()


func _show_points() -> void:
    for player_data: Dictionary in board.state.players:
        _show_points_for_player(player_data)


func _show_points_for_player(player_data: Dictionary) -> void:
    if points_panels.has(player_data["side"]):
        points_panels[player_data["side"]].show()
        points_panels[player_data["side"]].show_player_points(player_data, board)
