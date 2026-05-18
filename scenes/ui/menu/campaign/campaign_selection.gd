extends Control
class_name CampaignSelectionPanel

const TILES_PER_PAGE: int = 6

@onready var audio: AudioService = SimpleAudioLibrary as AudioService
@onready var campaign: CampaignService = Campaign as CampaignService

@onready var animations: AnimationPlayer = $"animations"
@onready var prev_button: TextureButton = $"widgets/prev_button"
@onready var next_button: TextureButton = $"widgets/next_button"

@onready var campaign_tiles: Array[CampaignTile] = [
    $"widgets/campaign1" as CampaignTile,
    $"widgets/campaign2" as CampaignTile,
    $"widgets/campaign3" as CampaignTile,
    $"widgets/campaign4" as CampaignTile,
    $"widgets/campaign5" as CampaignTile,
    $"widgets/campaign6" as CampaignTile,
]

var icons: IconsFactory = IconsFactory.new()

var main_menu: MainMenu
var page: int = 0

var last_campaign_tile_clicked: CampaignTile = null

func bind_menu(menu: MainMenu) -> void:
    self.main_menu = menu

    for campaign_tile: CampaignTile in self.campaign_tiles:
        campaign_tile.bind_menu(menu)

func _ready() -> void:
    self.set_process_input(false)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") or event.is_action_pressed('editor_menu'):
        self._on_back_button_pressed()
    if event.is_action_pressed("ui_page_down"):
        self._on_next_button_pressed()
    if event.is_action_pressed("ui_page_up"):
        self._on_prev_button_pressed()

func _on_back_button_pressed() -> void:
    self.audio.play("menu_back")
    self.main_menu.close_campaign_selection()

func _on_prev_button_pressed() -> void:
    if self._is_first_page():
        return

    self.audio.play("menu_click")
    self._switch_to_page(self.page - 1)
    if self._is_first_page():
        self.campaign_tiles[0].focus_tile()

func _on_next_button_pressed() -> void:
    if self._is_last_page():
        return

    self.audio.play("menu_click")
    self._switch_to_page(self.page + 1)
    if self._is_last_page():
        self.campaign_tiles[0].focus_tile()

func show_panel() -> void:
    self.animations.play("show")
    self.set_process_input(true)
    await self.get_tree().create_timer(0.1).timeout
    self.restore_focus()

func hide_panel() -> void:
    self.animations.play("hide")
    self.set_process_input(false)

func show_first_page() -> void:
    self._switch_to_page(0)

func _is_first_page() -> bool:
    return self.page == 0

func _is_last_page() -> bool:
    return self.page == self._get_amount_of_pages() - 1

func _get_amount_of_pages() -> int:
    var campaigns: Array[Dictionary] = self.campaign.get_campaigns()

    var amount: int = campaigns.size()
    var overflow: int = amount % self.TILES_PER_PAGE
    var pages: int = (amount - overflow) / self.TILES_PER_PAGE

    if overflow > 0:
        pages += 1

    return pages

func _switch_to_page(page_no: int) -> void:
    self.page = page_no

    var campaigns: Array[Dictionary] = self.campaign.get_campaigns()

    var index: int = 0
    var campaign_index: int = 0

    while index < self.TILES_PER_PAGE:
        campaign_index = page_no * self.TILES_PER_PAGE + index

        if campaign_index < campaigns.size():
            self._fill_tile(self.campaign_tiles[index], campaigns[campaign_index])
        else:
            self.campaign_tiles[index].hide()
        index += 1
    self._manage_navigation()

func _fill_tile(tile: CampaignTile, manifest: Dictionary) -> void:
    tile.show()

    var icon: Node = self.icons.get_named_icon(str(manifest["icon"]))

    if manifest.has("prerequisite"):
        if not self.campaign.is_campaign_complete(str(manifest["prerequisite"])):
            tile.set_locked(icon)
            return

    tile.set_up(str(manifest["title"]), icon, str(manifest["name"]))
    if self.campaign.is_campaign_complete(str(manifest["name"])):
        tile.set_complete()

func _manage_navigation() -> void:
    if self._is_first_page():
        self.prev_button.hide()
    else:
        self.prev_button.show()

    if self._is_last_page():
        self.next_button.hide()
    else:
        self.next_button.show()

func restore_focus() -> void:
    if self.last_campaign_tile_clicked != null:
        self.last_campaign_tile_clicked.focus_tile()
        self.last_campaign_tile_clicked = null
    else:
        self.campaign_tiles[0].focus_tile()
