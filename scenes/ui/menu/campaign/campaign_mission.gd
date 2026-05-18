extends "res://scenes/ui/menu/base_menu_panel.gd"
class_name CampaignMissionPanel

@onready var campaign: CampaignService = Campaign as CampaignService
@onready var switcher: SceneSwitcherService = SceneSwitcher as SceneSwitcherService
@onready var match_setup: MatchSetupData = MatchSetup as MatchSetupData

@onready var back_button: TextureButton = $"widgets/back_button"
@onready var start_button: TextureButton = $"widgets/start_button"
@onready var title: Label = $"widgets/title"
@onready var description: Label = $"widgets/description"

var manifest: Dictionary = {}
var mission_no: int = 0

func _on_back_button_pressed() -> void:
    super._on_back_button_pressed()
    self.main_menu.close_campaign_mission()

func _on_start_button_pressed() -> void:
    self.audio.play("menu_click")

    var missions: Array = self.manifest["missions"] as Array
    var mission_details: Dictionary = missions[self.mission_no] as Dictionary
    var players: Array = mission_details["players"] as Array

    self.match_setup.reset()
    self.match_setup.campaign_name = str(self.manifest["name"])
    self.match_setup.mission_no = self.mission_no

    for player: Dictionary in players:
        if not player.has("alive"):
            player["alive"] = true
        if not player.has("team"):
            player["team"] = null
        self.match_setup.add_player(
            str(player["side"]),
            int(player["ap"]),
            str(player["type"]),
            bool(player["alive"]),
            player["team"]
        )

    self.switcher.board()

func show_panel() -> void:
    super.show_panel()
    await self.get_tree().create_timer(0.1).timeout
    self.start_button.grab_focus()

func load_mission(campaign_name: String, _mission_no: int) -> void:
    self.manifest = self.campaign.get_campaign(campaign_name)
    self.mission_no = _mission_no

    if self.manifest.is_empty():
        self.main_menu.close_campaign_mission()
        return

    var missions: Array = self.manifest["missions"] as Array
    var mission_details: Dictionary = missions[self.mission_no] as Dictionary

    self.title.set_text(str(mission_details["title"]))
    self.description.set_text(str(mission_details["description"]))
