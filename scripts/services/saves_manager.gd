extends Node
class_name SavesManagerService

const AUTOSAVE_ID: int = 0
const LIST_FILE_PATH: String = "user://saves.json"
const SAVE_PATH: String = "user://save"
const SAVE_EXTENSION: String = ".tofsave.json"

var filesystem: FileSystem = FileSystem.new()

var autosave: Array = [null, null, null]
var saves: Array[Dictionary] = []


func _ready() -> void:
    self.load_saves_from_file()


func add_new_save(map_name: String, map_label: String, turn_no: int, save_data: Dictionary) -> void:
    var new_save_id: int = self.saves.size() + 3
    self.saves.append({
        "map": map_name,
        "label": map_label,
        "turn": turn_no,
        "save_id": new_save_id,
        "created_at": Time.get_datetime_dict_from_system()
    })

    self.save_list_to_file()
    self.store_save_data(new_save_id, save_data)


func overwrite_save(map_name: String, map_label: String, turn_no: int, save_data: Dictionary, save_id: int) -> void:
    self.saves[save_id - 3] = {
        "map": map_name,
        "label": map_label,
        "turn": turn_no,
        "save_id": save_id,
        "created_at": Time.get_datetime_dict_from_system()
    }

    self.save_list_to_file()
    self.store_save_data(save_id, save_data)


func write_autosave(map_name: String, map_label: String, turn_no: int, save_data: Dictionary) -> void:
    self.autosave[2] = self.autosave[1]
    if self.autosave[2] != null:
        self.autosave[2]["save_id"] = 2
        self._move_save_file(1, 2)
    self.autosave[1] = self.autosave[0]
    if self.autosave[1] != null:
        self.autosave[1]["save_id"] = 1
        self._move_save_file(0, 1)
    self.autosave[0] = {
        "map": map_name,
        "label": map_label,
        "turn": turn_no,
        "save_id": 0,
        "created_at": Time.get_datetime_dict_from_system()
    }

    self.save_list_to_file()
    self.store_save_data(0, save_data)


func save_list_to_file() -> void:
    var save_data: Dictionary = {
        "autosave": self.autosave,
        "saves": self.saves
    }
    self.filesystem.write_data_as_json_to_file(self.LIST_FILE_PATH, save_data)


func load_saves_from_file() -> void:
    var save_data: Dictionary = self.filesystem.read_json_from_file(self.LIST_FILE_PATH)
    if save_data.has("saves"):
        self.saves.assign(save_data["saves"])
    if save_data.has("autosave"):
        if save_data["autosave"] is Dictionary:
            save_data["autosave"] = [save_data["autosave"], null, null]
            self.autosave = save_data["autosave"]
            self._migrate_saves()
            self.save_list_to_file()
        self.autosave = save_data["autosave"]


func get_entries_page(page_number: int, page_size: int) -> Array[Dictionary]:
    var entries_list: Array[Dictionary] = []

    for autosave_entry: Variant in self.autosave:
        if autosave_entry != null:
            entries_list.append(autosave_entry as Dictionary)

    if self.saves.size() > 0:
        var saves_copy: Array[Dictionary] = self.saves.duplicate()
        saves_copy.reverse()
        entries_list += saves_copy
    return entries_list.slice(page_number * page_size, (page_number + 1) * page_size)


func get_pages_count(page_size: int) -> int:
    var total_saves_count: int = self.saves.size()
    for autosave_entry: Variant in self.autosave:
        if autosave_entry != null:
            total_saves_count += 1

    return ceili(total_saves_count / float(page_size))


func get_save_data(save_id: int) -> Dictionary:
    var filepath: String = self.get_save_path(save_id)
    return self.filesystem.read_json_from_file(filepath)


func store_save_data(save_id: int, save_data: Dictionary) -> void:
    self.filesystem.write_data_as_json_to_file(self.get_save_path(save_id), save_data)


func get_save_path(save_id: int) -> String:
    return self.SAVE_PATH + str(save_id) + self.SAVE_EXTENSION


func compile_save_data(board: BoardView) -> Dictionary:
    var map_name: String = ""
    var map_label: String = ""

    if board.match_setup.map_name != null:
        map_name = str(board.match_setup.map_name)
        map_label = str(board.match_setup.map_name)

    if board.match_setup.campaign_name != null:
        var manifest: Dictionary = board.campaign.get_campaign(str(board.match_setup.campaign_name))
        var missions: Array = manifest["missions"] as Array
        var mission_details: Dictionary = missions[board.match_setup.mission_no] as Dictionary
        map_label = tr(str(manifest["title"])) + " - " + tr(str(mission_details["title"]))

    var snapshot: BoardStateSnapshot = board.board_model.get_snapshot()
    var save_data: Dictionary = BoardStateSerializer.to_save_data(snapshot)
    save_data.merge({
        "map_name": board.match_setup.map_name,
        "campaign_name": board.match_setup.campaign_name,
        "mission_no": board.match_setup.mission_no,
        "initial_setup": board.match_setup.stored_setup,
        "camera": board.map.camera.get_position_state(),
    }, true)

    return {
        "map_name": map_name,
        "map_label": map_label,
        "turn_no": snapshot.match.turn,
        "save_data": save_data
    }


func _move_save_file(source_id: int, destination_id: int) -> void:
    self.store_save_data(destination_id, self.get_save_data(source_id))


func _migrate_saves() -> void:
    var saves_copy: Array[Dictionary] = self.saves.duplicate()
    saves_copy.reverse()
    for save: Dictionary in saves_copy:
        var save_id: int = int(save["save_id"])
        self._move_save_file(save_id, save_id + 2)
        save["save_id"] = save_id + 2
    saves_copy.reverse()
    self.saves = saves_copy
