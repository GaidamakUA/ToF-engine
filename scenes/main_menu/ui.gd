extends Control
class_name MainMenuUi

@onready var menu: MainMenuOptionsPanel = $"options/menu"
@onready var logo: Node2D = $"logo/logo_view"
@onready var picker: MapPickerPanel = $"map_picker/picker"
@onready var saves: SavesPanel = $"saves/saves"
@onready var skirmish: SkirmishPanel = $"skirmish/skirmish"
@onready var settings: MainMenuSettingsPanel = $"settings/settings"
@onready var controls: ControlsPanel = $"controls/controls"
@onready var campaign_selection: CampaignSelectionPanel = $"campaign_selection/campaign_selection"
@onready var campaign_mission_selection: CampaignMissionSelectionPanel = $"campaign_mission_selection/campaign_mission_selection"
@onready var campaign_mission: CampaignMissionPanel = $"campaign_mission/campaign_mission"
@onready var online: OnlinePanel = $"online/online"
@onready var online_lobby: OnlineLobbyPanel = $"online_lobby/lobby"
@onready var multiplayer_panel: MultiplayerPanel = $"multiplayer/multiplayer"
@onready var multiplayer_lobby_panel: MultiplayerLobbyPanel = $"multiplayer_lobby/lobby"
@onready var extra_buttons: VBoxContainer = $"extra_buttons"
@onready var credits_panel: CreditsPanel = $"credits/credits"
@onready var credits_button: TextureButton = $"extra_buttons/credits_button"
@onready var changelog_panel: ChangelogPanel = $"changelog/changelog"
@onready var changelog_button: TextureButton = $"extra_buttons/changelog_button"


func bind_menu(main_menu: MainMenu) -> void:
	self.menu.bind_menu(main_menu)
	self.skirmish.bind_menu(main_menu)
	self.settings.bind_menu(main_menu)
	self.controls.bind_menu(main_menu)
	self.campaign_selection.bind_menu(main_menu)
	self.campaign_mission_selection.bind_menu(main_menu)
	self.campaign_mission.bind_menu(main_menu)
	self.online.bind_menu(main_menu)
	self.online_lobby.bind_menu(main_menu)
	self.multiplayer_panel.bind_menu(main_menu)
	self.multiplayer_lobby_panel.bind_menu(main_menu)
	self.credits_panel.bind_menu(main_menu)
	self.changelog_panel.bind_menu(main_menu)

	var version_string: String = tr("TR_VERSION") + " v" + ProjectSettings.get_setting("application/config/version")
	if main_menu.settings._is_steam_deck():
		version_string += " SteamOS"
	else:
		version_string += " " + OS.get_name()
	if OS.has_feature("demo"):
		version_string += " Demo"
	self.set_version(version_string)

func hide_menu() -> void:
	self.menu.hide_panel()
	#self.logo.hide()
	self.extra_buttons.hide()

func show_menu() -> void:
	self.menu.show_panel()
	#self.logo.show()
	self.extra_buttons.show()

func show_picker() -> void:
	self.picker.show_picker()

func hide_picker() -> void:
	self.picker.hide_picker()

func show_skirmish(map_name: String) -> void:
	self.skirmish.show_panel(map_name)

func hide_skirmish() -> void:
	self.skirmish.hide_panel()

func show_settings() -> void:
	self.settings.show_panel()

func hide_settings() -> void:
	self.settings.hide_panel()

func show_controls() -> void:
	self.controls.show_panel()

func hide_controls() -> void:
	self.controls.hide_panel()

func show_campaign_selection(reset_page: bool = false) -> void:
	self.campaign_selection.show_panel()
	if reset_page:
		self.campaign_selection.show_first_page()

func hide_campaign_selection() -> void:
	self.campaign_selection.hide_panel()

func show_campaign_mission_selection(campaign_name: String = "") -> void:
	self.campaign_mission_selection.show_panel()
	if campaign_name != "":
		self.campaign_mission_selection.load_campaign(campaign_name)

func hide_campaign_mission_selection() -> void:
	self.campaign_mission_selection.hide_panel()

func show_campaign_mission(campaign_name: String, mission_no: int) -> void:
	self.campaign_mission.show_panel()
	self.campaign_mission.load_mission(campaign_name, mission_no)

func hide_campaign_mission() -> void:
	self.campaign_mission.hide_panel()

func set_version(value: String) -> void:
	$"version/version".set_text(value)

func show_saves() -> void:
	self.saves.show_saves(false)

func hide_saves() -> void:
	self.saves.hide_saves()

func show_online() -> void:
	self.online.show_panel()

func hide_online() -> void:
	self.online.hide_panel()

func show_online_lobby() -> void:
	self.online_lobby.show_panel()

func hide_online_lobby() -> void:
	self.online_lobby.hide_panel()

func show_multiplayer() -> void:
	self.multiplayer_panel.show_panel()

func hide_multiplayer() -> void:
	self.multiplayer_panel.hide_panel()

func show_multiplayer_lobby() -> void:
	self.multiplayer_lobby_panel.show_panel()

func hide_multiplayer_lobby() -> void:
	self.multiplayer_lobby_panel.hide_panel()

func show_credits() -> void:
	self.credits_panel.show_panel()

func hide_credits() -> void:
	self.credits_panel.hide_panel()

func show_changelog() -> void:
	self.changelog_panel.show_panel()

func hide_changelog() -> void:
	self.changelog_panel.hide_panel()


func _on_button_pressed() -> void:
	self.credits_panel.audio.play("menu_back")
	self.credits_panel.main_menu.open_credits()


func _on_changelog_button_pressed() -> void:
	self.credits_panel.audio.play("menu_back")
	self.credits_panel.main_menu.open_changelog()
