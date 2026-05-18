extends Node
class_name OnlineService

var THUMBNAIL_LOCATION: String = "api.tof.p1x.in"
const THUMBNAIL_URL: String = "/browser/public/thumbs/v2/"
const THUMBNAIL_V1_URL: String = "/browser/public/thumbs/"

@onready var connector: OnlineConnector = OnlineConnector.new(self)
@onready var player: OnlinePlayer = OnlinePlayer.new(self)
@onready var maps: OnlineMaps = OnlineMaps.new(self)

@onready var map_manager_service: MapManagerService = MapManager as MapManagerService
@onready var settings: SettingsService = Settings as SettingsService

var thumb_cache: Dictionary[String, ImageTexture] = {}
var api_version: int = 2


func _ready() -> void:
	self.player.load_data_from_file()
	self._read_settings()
	self.settings.changed.connect(self._on_settings_changed)


func _on_settings_changed(key: String, _value) -> void:
	if key == "online_domain" or key == "online_port":
		self._read_settings()
		self.connector._read_settings()


func _read_settings() -> void:
	var new_value: Variant = self.settings.get_option("online_domain")
	if new_value is String:
		self.THUMBNAIL_LOCATION = new_value


func is_integrated() -> bool:
	return self.player.is_registered()


func request_player_id() -> String:
	return await self.player.request_player_id()


func clear_cache() -> void:
	self.maps.clear_cache()


func fetch_listing_chunk(last_id: int) -> int:
	return await self.maps.fetch_listing_chunk(last_id)


func fetch_top_downloads() -> int:
	return await self.maps.fetch_top_downloads()


func get_maps_page(page_number: int, page_size: int) -> Array[Dictionary]:
	var pages_count: int = self.get_pages_count(page_size)
	if page_number >= pages_count:
		return []

	var index_start: int = page_number * page_size
	var index_end: int = index_start + page_size

	var maps_count: int = self.maps.listing_cache.size()
	if index_end > maps_count:
		index_end = maps_count

	var index: int = index_start
	var output: Array[Dictionary] = []

	while index < index_end:
		output.append(self.maps.listing_cache[index])
		index += 1

	return output

func get_pages_count(page_size: int) -> int:
	var total_map_count: int = self.maps.listing_cache.size()
	var last_page_overflow: int = total_map_count % page_size
	@warning_ignore("integer_division")
	var pages_count: int = (total_map_count - last_page_overflow) / page_size

	if last_page_overflow > 0:
		pages_count += 1

	return pages_count


func fetch_thumbnail(map_code: String) -> Dictionary[String, Variant]:
	if self.thumb_cache.has(map_code):
		return {
			'code' : map_code,
			'image' : self.thumb_cache[map_code]
		}

	var url: String = ""
	if self.api_version == 1:
		url = self.THUMBNAIL_V1_URL + map_code + ".png"
	elif self.api_version == 2:
		url = self.THUMBNAIL_URL + map_code + ".png"
	var result: Dictionary[String, Variant] = await self.connector._request_any(self.THUMBNAIL_LOCATION, url, HTTPClient.METHOD_GET, "", false, false)

	if result['status'] != 'ok':
		return {
			'code' : map_code,
			'image' : null
		}

	var image: Image = Image.new()
	var error: Error = image.load_png_from_buffer(result['data'])

	if error != OK:
		return {
			'code' : map_code,
			'image' : null
		}

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	self.thumb_cache[map_code] = texture

	return {
		'code' : map_code,
		'image' : self.thumb_cache[map_code]
	}


func upload_map(map_name: String) -> String:
	var content: Dictionary[String, Variant]
	content.assign(self.map_manager_service.get_map_data(map_name))

	var response: Dictionary[String, Variant] = await self.maps.upload_map(content)

	if response['status'] == 'ok':
		var metadata: Dictionary = content["metadata"]
		var response_data: Dictionary = response["data"]
		metadata["name"] = map_name
		metadata["base_code"] = response_data["base_code"]
		metadata["iteration"] = response_data["iteration"]
		var code: String = str(response_data["code"])
		self.map_manager_service.add_online_map_to_list(map_name, code)
		self.map_manager_service.save_online_to_file(code, content)
		self.map_manager_service.save_map_to_file(map_name, content)
		return code

	return ""

func download_map(map_code: String) -> bool:
	if self.map_manager_service._is_online(map_code):
		return true

	var response: Dictionary[String, Variant] = await self.maps.download_map(map_code)

	if response['status'] == 'ok':
		var response_data: Dictionary = response["data"]
		var map_data: Dictionary = response_data["data"]
		var metadata: Dictionary = map_data["metadata"]
		self.map_manager_service.add_online_map_to_list(str(metadata["name"]), map_code)
		self.map_manager_service.save_online_to_file(map_code, map_data)
		return true

	return false


func set_api_version(version: int) -> void:
	self.api_version = version
