extends "res://scenes/ui/menu/base_menu_panel.gd"
class_name MultiplayerPanel

@onready var main_panel: Control = $"widgets/main"
@onready var address_panel: Control = $"widgets/address"
@onready var nickname_input: LineEdit = $"widgets/main/nickname"

@onready var create_button: TextureButton = $"widgets/main/create_button"

@onready var back_button: TextureButton = $"widgets/back_button"
@onready var connect_button: TextureButton = $"widgets/address/connect_button"
@onready var connect_input: LineEdit = $"widgets/address/address"
@onready var connect_port: LineEdit = $"widgets/address/port"
@onready var connect_message: Label = $"widgets/address/message"

@onready var settings: SettingsService = Settings as SettingsService
@onready var multiplayer_srv: MultiplayerService = Multiplayer as MultiplayerService
@onready var autodiscovery: AutodiscoveryService = Autodiscovery as AutodiscoveryService

@onready var server_panels: Array[ServerDiscoveryPanel] = [
    $"widgets/address/server_panel_0" as ServerDiscoveryPanel,
    $"widgets/address/server_panel_1" as ServerDiscoveryPanel,
    $"widgets/address/server_panel_2" as ServerDiscoveryPanel,
    $"widgets/address/server_panel_3" as ServerDiscoveryPanel,
]

var connection_busy: bool = false

func _ready() -> void:
    super._ready()
    self.nickname_input.set_text(str(self.settings.get_option("nickname")))
    self.connect_input.set_text(str(self.settings.get_option("last_used_ip")))
    self.connect_port.set_text(str(self.settings.get_option("last_used_port")))

    self.multiplayer_srv.connection_failed.connect(_on_connection_failed)
    self.multiplayer_srv.connection_success.connect(_on_connection_success)
    self.autodiscovery.scanned_server.connect(_on_server_found)

    for panel: ServerDiscoveryPanel in self.server_panels:
        panel.server_selected.connect(_connect_to_server)

func show_panel() -> void:
    super.show_panel()
    _switch_to_main_panel()

func _on_back_button_pressed() -> void:
    super._on_back_button_pressed()

    if self.connection_busy:
        return

    if self.address_panel.is_visible():
        _switch_to_main_panel()
    else:
        self.main_menu.close_multiplayer()

    self.autodiscovery.abort_lan_scan()

func _switch_to_main_panel() -> void:
    self.address_panel.hide()
    self.main_panel.show()
    await self.get_tree().create_timer(0.1).timeout
    self.create_button.grab_focus()

func _switch_to_connect_panel() -> void:
    self.connect_message.set_text("")
    self.main_panel.hide()
    self.address_panel.show()
    for panel: ServerDiscoveryPanel in self.server_panels:
        panel.hide()
    self.autodiscovery.scan_lan_servers()
    await self.get_tree().create_timer(0.1).timeout
    self.connect_button.grab_focus()

func _on_create_button_pressed() -> void:
    self.audio.play("menu_click")
    self.main_menu.open_multiplayer_picker()


func _on_join_button_pressed() -> void:
    self.audio.play("menu_click")
    _switch_to_connect_panel()


func _on_nickname_focus_exited() -> void:
    self.settings.set_option("nickname", self.nickname_input.get_text())

func _on_address_focus_exited() -> void:
    self.settings.set_option("last_used_ip", self.connect_input.get_text())

func _on_port_focus_exited() -> void:
    self.settings.set_option("last_used_port", self.connect_port.get_text())


func _on_connect_button_pressed() -> void:
    self.audio.play("menu_click")
    _connect_to_server(self.connect_input.get_text(), self.connect_port.get_text().to_int())

func _connect_to_server(address: String, port: int) -> void:
    if self.connection_busy:
        return

    self.connection_busy = true
    self.connect_message.set_text(tr("TR_CONNECTING"))
    var error: Error = self.multiplayer_srv.connect_server(address, port)
    if error:
        self.connection_busy = false
        self.connect_message.set_text(tr("TR_CONNECTION_ERROR"))


func _on_connection_success() -> void:
    self.connection_busy = false
    _switch_to_main_panel()
    self.autodiscovery.abort_lan_scan()
    self.main_menu.open_multiplayer_lobby()

func _on_connection_failed() -> void:
    self.connection_busy = false
    self.connect_message.set_text(tr("TR_CONNECTION_ERROR"))

func _on_server_found() -> void:
    var amount: int = self.server_panels.size()

    if self.autodiscovery.scanned_servers.size() < self.server_panels.size():
        amount = self.autodiscovery.scanned_servers.size()

    for index: int in amount:
        var server_data: Dictionary = self.autodiscovery.scanned_servers[index]
        self.server_panels[index].set_labels(
            str(server_data["server_ip"]) + ":" + str(server_data["port"]) + " - " + str(server_data["map"]),
            str(server_data["players"])
        )
        self.server_panels[index].address = str(server_data["server_ip"])
        self.server_panels[index].port = int(server_data["port"])
        if server_data["joinable"]:
            self.server_panels[index].join_button.show()
        else:
            self.server_panels[index].join_button.hide()
        self.server_panels[index].show()
