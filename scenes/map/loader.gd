class_name MapLoader

const EDITOR_VERSION: int = 2

var importer: MapImporter = MapImporter.new()
var map_list_service: MapManagerService = MapManager as MapManagerService

var map: Map

func _init(map_scene: Map) -> void:
    self.map = map_scene

func save_map_file(filename: String) -> void:
    if self.map.model.metadata.has("iteration"):
        self.map.model.metadata["iteration"] += 1
    if not self.map.model.metadata.has("name") or self.map.model.metadata["name"] != filename:
        self.map.model.metadata["name"] = filename
        self.map.model.metadata["iteration"] = 0
        self.map.model.metadata["base_code"] = null
    self.map.model.metadata["editor_version"] = self.EDITOR_VERSION
    var map_data: Dictionary[String, Variant] = self.map.model.get_dict()
    self.map_list_service.save_map_to_file(filename, map_data)

func load_map_file(filename: String) -> void:
    var content: Dictionary[String, Variant]
    content.assign(self.map_list_service.get_map_data(filename))
    if content.is_empty():
        return

    content["metadata"] = self._fill_missing_metadata(content)
    self.map.builder.wipe_map()
    self.map.builder.fill_map_from_data(content)
    self._initialize_camera_position()

func load_campaign_map(campaign_name: String, mission_no: int) -> void:
    var content: Dictionary[String, Variant]
    content.assign(self.map.campaign.get_campaign_mission_map(campaign_name, mission_no))
    content["metadata"] = self._fill_missing_metadata(content)
    self.map.builder.wipe_map()
    self.map.builder.fill_map_from_data(content)
    self._initialize_camera_position()

func _initialize_camera_position() -> void:
    if self.map.model.metadata.has("initial_cam_pos"):
        var position: Vector2i = Vector2i(self.map.model.metadata["initial_cam_pos"][0], self.map.model.metadata["initial_cam_pos"][1])
        self.map.snap_camera_to_position(position)

func load_from_v1_data(data: Dictionary) -> void:
    self.map.builder.wipe_map()
    self.importer.build_from_v1_data(self.map, data)

func _fill_missing_metadata(data: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
    var metadata: Dictionary[String, Variant] = {}
    if data.has("metadata"):
        metadata.assign(data["metadata"])

    if not metadata.has("iteration"):
        metadata["iteration"] = 0
    if not metadata.has("name"):
        metadata["name"] = ""
        metadata["base_code"] = null
    if metadata.has("editor_version"):
        if metadata["editor_version"] is String:
            metadata["editor_version"] = 1
    else:
        metadata["editor_version"] = self.EDITOR_VERSION

    return metadata
