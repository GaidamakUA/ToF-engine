extends Node
class_name CampaignService

const PROGRESS_FILE_PATH: String = "user://campaigns.json"
const CORE_CAMPAIGNS_BASE_PATH: String = "res://assets/campaigns/"
const CUSTOM_CAMPAIGNS_BASE_PATH: String = "campaign"
const CAMPAIGN_MANIFEST: String = "/campaign.json"

var filesystem: FileSystem = FileSystem.new()

var campaign_progress: Dictionary[String, Dictionary] = {}

var registered_core_campaign_names: Array[String] = [
    "tutorial",
    "core_prologue",
    "core_ruby_dusk",
    "core_sapphire_dawn",
    "core_jade_twilight",
    "core_amber_noon",
    "core_epilogue"
]

var core_campaigns: Array[Dictionary] = []
var core_campaigns_by_name: Dictionary[String, Dictionary] = {}
var custom_campaigns: Array[Dictionary] = []
var custom_campaigns_by_name: Dictionary[String, Dictionary] = {}

func _ready() -> void:
    self._load_campaign_progress()
    self._load_core_campaigns()
    self._load_custom_campaigns()

func get_campaigns() -> Array[Dictionary]:
    var campaigns: Array[Dictionary] = []
    campaigns.append_array(self.core_campaigns)
    campaigns.append_array(self.custom_campaigns)
    return campaigns

func get_campaign(campaign_name: String) -> Dictionary:
    if self.core_campaigns_by_name.has(campaign_name):
        return self.core_campaigns_by_name[campaign_name]
    elif self.custom_campaigns_by_name.has(campaign_name):
        return self.custom_campaigns_by_name[campaign_name]
    return {}

func get_campaign_progress(campaign_name: String) -> int:
    if self.campaign_progress.has(campaign_name):
        return self.campaign_progress[campaign_name]["progress"]
    return 0

func update_campaign_progress(campaign_name: String, mission_no: int) -> void:
    if not self.campaign_progress.has(campaign_name):
        self.campaign_progress[campaign_name] = {
            "progress" : 0,
            "complete" : false,
        }

    if mission_no + 1 > self.campaign_progress[campaign_name]["progress"]:
        self.campaign_progress[campaign_name]["progress"] = mission_no + 1
        self.campaign_progress[campaign_name]["complete"] = self._is_last_scenario(campaign_name, mission_no)

    self._save_campaign_progress()

func is_campaign_complete(campaign_name: String) -> bool:
    if self.campaign_progress.has(campaign_name):
        return self.campaign_progress[campaign_name]["complete"]
    return false

func _load_campaign_progress() -> void:
    var loaded_progress: Dictionary = self.filesystem.read_json_from_file(self.PROGRESS_FILE_PATH) as Dictionary

    for campaign_name: String in loaded_progress:
        self.campaign_progress[campaign_name] = loaded_progress[campaign_name] as Dictionary

func _save_campaign_progress() -> void:
    self.filesystem.write_data_as_json_to_file(self.PROGRESS_FILE_PATH, self.campaign_progress)

func _load_core_campaigns() -> void:
    var campaign_details: Dictionary

    for registered_campaign: String in self.registered_core_campaign_names:
        campaign_details = self._load_campaign_details(self.CORE_CAMPAIGNS_BASE_PATH + registered_campaign)
        if not campaign_details.is_empty():
            if campaign_details.has("map"):
                campaign_details["map"] = self.CORE_CAMPAIGNS_BASE_PATH + "/" + registered_campaign + "/" + campaign_details["map"]
            self.core_campaigns.append(campaign_details)
            self.core_campaigns_by_name[registered_campaign] = campaign_details


func _load_custom_campaigns() -> void:
    if self.filesystem.dir_exists(self.CUSTOM_CAMPAIGNS_BASE_PATH):
        var dirs_found: Array[String] = self.filesystem.dir_list(self.CUSTOM_CAMPAIGNS_BASE_PATH)
        var campaign_details: Dictionary

        for dir_name: String in dirs_found:
            campaign_details = self._load_campaign_details(self.CUSTOM_CAMPAIGNS_BASE_PATH + "/" + dir_name)
            if not campaign_details.is_empty():
                if campaign_details.has("map"):
                    campaign_details["map"] = self.CUSTOM_CAMPAIGNS_BASE_PATH + "/" + dir_name + "/" + campaign_details["map"]
                self.custom_campaigns.append(campaign_details)
                self.custom_campaigns_by_name[dir_name] = campaign_details
    else:
        print("Custom dir not found " + self.CUSTOM_CAMPAIGNS_BASE_PATH)

func _load_campaign_details(directory_path: String) -> Dictionary:
    var manifest_path: String = directory_path + self.CAMPAIGN_MANIFEST
    var details: Dictionary = {}

    if self.filesystem.file_exists(manifest_path):
        details = self.filesystem.read_json_from_file(manifest_path) as Dictionary
        if self._validate_manifest(details, directory_path):
            self._load_translations(directory_path)
            return details

    return {}

func _validate_manifest(manifest: Dictionary, directory_path: String) -> bool:
    if not manifest.has("missions"):
        return false

    for mission: Dictionary in manifest["missions"]:
        if not self.filesystem.file_exists(directory_path + "/maps/" + mission["map"]):
            return false

    return true

func _load_translations(directory_path: String) -> void:
    if self.filesystem.file_exists(directory_path + "/translations.json"):
        var translations: Dictionary = self.filesystem.read_json_from_file(directory_path + "/translations.json") as Dictionary

        for locale: String in translations:
            var position: Translation = Translation.new()
            position.locale = locale

            for key: String in translations[locale]:
                position.add_message(key, translations[locale][key])
            TranslationServer.add_translation(position)

func _get_scenario_index(campaign_name: String, scenario_name: String) -> int:
    var manifest: Dictionary = self.get_campaign(campaign_name)
    if manifest.is_empty():
        return 0

    return self._search_manifest_for_scenario_index(manifest, scenario_name)

func _search_manifest_for_scenario_index(manifest: Dictionary, scenario_name: String) -> int:
    var index: int = 0

    for mission_details: Dictionary in manifest["missions"]:
        index += 1
        if mission_details["name"] == scenario_name:
            return index

    return 0

func _is_last_scenario(campaign_name: String, mission_no: int) -> bool:
    var manifest: Dictionary = self.get_campaign(campaign_name)
    if manifest.is_empty():
        return false

    return mission_no + 1 == manifest["missions"].size()

func _get_campaign_path(campaign_name: String) -> String:
    if self.core_campaigns_by_name.has(campaign_name):
        return self.CORE_CAMPAIGNS_BASE_PATH + campaign_name
    elif self.custom_campaigns_by_name.has(campaign_name):
        return self.CUSTOM_CAMPAIGNS_BASE_PATH + "/" + campaign_name
    return ""

func get_campaign_mission_map(campaign_name: String, mission_no: int) -> Dictionary:
    var manifest: Dictionary = self.get_campaign(campaign_name)
    var campaign_path: String = self._get_campaign_path(campaign_name)
    if manifest.is_empty() or campaign_path == "":
        return {}

    var map_path: String = campaign_path + "/maps/" + manifest["missions"][mission_no]["map"]
    if self.filesystem.file_exists(map_path):
        return self.filesystem.read_json_from_file(map_path) as Dictionary
    return {}
