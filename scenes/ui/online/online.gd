extends "res://scenes/ui/menu/base_menu_panel.gd"
class_name OnlinePanel

@onready var online: OnlineService = Online as OnlineService
@onready var settings: SettingsService = Settings as SettingsService
@onready var relay: RelayService = Relay as RelayService

@onready var back_button: TextureButton = $"widgets/back_button"

@onready var register_panel: Control = $"widgets/register"
@onready var register_button: TextureButton = $"widgets/register/register_button"
@onready var register_description: Label = $"widgets/register/description"

@onready var online_panel: Control = $"widgets/online"
@onready var maps_panel: Control = $"widgets/online/maps"
@onready var maps_main: Control = $"widgets/online/maps/main"
@onready var upload_button: TextureButton = $"widgets/online/maps/main/upload_button"
@onready var download_button: TextureButton = $"widgets/online/maps/main/download_button"

@onready var maps_upload: Control = $"widgets/online/maps/upload"
@onready var confirm_upload_button: TextureButton = $"widgets/online/maps/upload/confirm_upload_button"
@onready var confirm_upload_button_label: Label = $"widgets/online/maps/upload/confirm_upload_button/label"
@onready var change_button: TextureButton = $"widgets/online/maps/upload/change_button"
@onready var upload_desc: Label = $"widgets/online/maps/upload/description"
@onready var upload_name: Label = $"widgets/online/maps/upload/name"

@onready var maps_download: Control = $"widgets/online/maps/download"
@onready var retry_download_button: TextureButton = $"widgets/online/maps/download/retry_button"
@onready var download_desc: Label = $"widgets/online/maps/download/description"
@onready var download_name: Label = $"widgets/online/maps/download/name"




@onready var online_match_nickname_input: LineEdit = $"widgets/online/maps/main/nickname"
@onready var online_match_create_button: TextureButton = $"widgets/online/maps/main/create_button"
@onready var online_match_join_code_input: LineEdit = $"widgets/online/maps/main/join_code"
@onready var online_match_join_button: TextureButton = $"widgets/online/maps/main/join_button"

@onready var online_match_connecting_panel: Control = $"widgets/online/maps/busy"




var working: bool = false

var selected_upload_map: Variant = null
var selected_download_map: Variant = null

func _ready() -> void:
	super._ready()
	self.upload_name.set_message_translation(false)
	self.upload_name.notification(NOTIFICATION_TRANSLATION_CHANGED)
	self.download_name.set_message_translation(false)
	self.download_name.notification(NOTIFICATION_TRANSLATION_CHANGED)

	self.online_match_nickname_input.set_text(self.settings.get_option("nickname"))
	self.relay.session_success.connect(self._on_session_success)
	self.relay.connection_failed.connect(self._on_connection_failed)

func _on_back_button_pressed() -> void:
	if self.working:
		return
	self.audio.play("menu_back")
	if self.selected_upload_map != null:
		self.selected_upload_map = null
		self._select_panel()
	elif self.selected_download_map != null:
		self.selected_download_map = null
		self._select_panel()
	elif self.online_match_connecting_panel.is_visible():
		self.back_button.show()
		self._select_panel()
	else:
		self.main_menu.close_online()

func _on_register_button_pressed() -> void:
	if self.working:
		return

	self.working = true
	self.audio.play("menu_click")
	self.register_description.set_text(tr("TR_REQUESTING_PLAYER_ID"))
	self.register_button.hide()
	self.back_button.hide()

	var result: String = await self.online.request_player_id()

	self.working = false
	if result == "ok":
		self.register_description.set_text(tr("TR_REQUESTING_PLAYER_SUCCESS"))
		await self.get_tree().create_timer(2).timeout
		self._select_panel()
	else:
		self.back_button.show()
		self.register_button.show()
		self.register_description.set_text(tr("TR_REQUESTING_PLAYER_FAIL"))
		await self.get_tree().create_timer(0.1).timeout
		self.register_button.grab_focus()




func show_panel() -> void:
	super.show_panel()
	self._select_panel()

func _select_panel() -> void:
	self.back_button.show()
	if self.online.is_integrated():
		self._configure_online_panel()
	else:
		self._configure_registration_panel()

func _configure_online_panel() -> void:
	self.online_panel.show()
	self.register_panel.hide()
	self._configure_maps_panel()

func _hide_all_subpanels() -> void:
	self.maps_main.hide()
	self.maps_upload.hide()
	self.maps_download.hide()
	self.online_match_connecting_panel.hide()

func _configure_maps_panel() -> void:
	self._hide_all_subpanels()
	if self.selected_upload_map != null:
		self._configure_maps_upload_confirm_panel()
	elif self.selected_download_map != null:
		self._configure_maps_download_panel()
	else:
		self._configure_maps_upload_panel()


func _configure_maps_upload_panel() -> void:
	self.maps_main.show()
	await self.get_tree().create_timer(0.1).timeout
	self.upload_button.grab_focus()


func _configure_maps_upload_confirm_panel() -> void:
	self.maps_upload.show()
	self.change_button.show()
	self.confirm_upload_button.show()
	self.upload_desc.set_text(tr("TR_SELECTED_MAP"))
	self.upload_name.set_text(self.selected_upload_map)
	self.confirm_upload_button_label.set_text(tr("TR_CONFIRM"))
	await self.get_tree().create_timer(0.1).timeout
	self.confirm_upload_button.grab_focus()


func _configure_maps_download_panel() -> void:
	self.maps_download.show()
	self.download_desc.set_text(tr("TR_DOWNLOADING_MAP"))
	self.download_name.set_text(self.selected_download_map)
	self._on_retry_button_pressed()


func _configure_registration_panel() -> void:
	self.online_panel.hide()
	self.register_panel.show()
	self.register_button.show()
	self.register_description.set_text(tr("TR_NEED_REGISTER"))

	await self.get_tree().create_timer(0.1).timeout
	self.register_button.grab_focus()

func _show_online_connecting_panel() -> void:
	self._hide_all_subpanels()
	self.online_match_connecting_panel.show()
	self.back_button.hide()


func _on_upload_button_pressed() -> void:
	self.audio.play("menu_click")
	self.main_menu.open_upload_picker()


func _on_download_button_pressed() -> void:
	self.audio.play("menu_click")
	self.main_menu.open_download_picker()
	self.back_button.hide()


func _on_confirm_upload_button_pressed() -> void:
	if self.working:
		return

	self.working = true
	self.audio.play("menu_click")
	self.upload_desc.set_text(tr("TR_UPLOADING_WAIT"))
	self.confirm_upload_button.hide()
	self.change_button.hide()
	self.back_button.hide()

	var result: String = await self.online.upload_map(self.selected_upload_map)

	self.working = false
	self.back_button.show()
	if result != "":
		self.upload_desc.set_text(tr("TR_UPLOADING_SUCCESS"))
		self.upload_name.set_text(result)
		await self.get_tree().create_timer(0.1).timeout
		self.back_button.grab_focus()
	else:
		self.change_button.show()
		self.confirm_upload_button.show()
		self.confirm_upload_button_label.set_text(tr("TR_RETRY"))
		self.upload_desc.set_text(tr("TR_UPLOADING_FAIL"))
		await self.get_tree().create_timer(0.1).timeout
		self.confirm_upload_button.grab_focus()


func _on_retry_button_pressed() -> void:
	if self.working:
		return

	self.working = true
	self.audio.play("menu_click")
	self.download_desc.set_text(tr("TR_DOWNLOADING_MAP"))
	self.retry_download_button.hide()
	self.back_button.hide()

	var result: bool = await self.online.download_map(String(self.selected_download_map))

	self.working = false
	self.back_button.show()

	if result:
		self.download_desc.set_text(tr("TR_DOWNLOADING_SUCCESS"))
		await self.get_tree().create_timer(0.1).timeout
		self.back_button.grab_focus()
	else:
		self.retry_download_button.show()
		self.download_desc.set_text(tr("TR_DOWNLOADING_FAIL"))
		await self.get_tree().create_timer(0.1).timeout
		self.retry_download_button.grab_focus()


func _on_nickname_focus_exited() -> void:
	self.settings.set_option("nickname", self.online_match_nickname_input.get_text())


func _on_create_button_pressed() -> void:
	self.audio.play("menu_click")
	self.main_menu.open_online_match_map_picker()


func _on_join_button_pressed() -> void:
	self.audio.play("menu_click")

	if self.online_match_join_code_input.get_text() == "":
		return

	self.working = true
	self._show_online_connecting_panel()
	self.relay.connect_game(self.online_match_join_code_input.get_text())

func init_match(map_name: String) -> void:
	self._show_online_connecting_panel()
	self.working = true
	self.relay.create_game(map_name)

func _on_session_success() -> void:
	self.working = false
	self.main_menu.open_online_lobby()

func _on_connection_failed() -> void:
	self.working = false
	self.back_button.show()
	self._select_panel()
