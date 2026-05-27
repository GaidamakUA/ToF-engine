class_name SettingsCategoryPanel
extends Control


signal help_requested(tip: String)
signal clear_help_requested()


func _ready() -> void:
    for option_node: Node in $VBoxContainer.get_children():
        var option: SettingsItem = option_node as SettingsItem
        option.help_requested.connect(_on_help_requested)
        option.clear_help_requested.connect(_on_clear_help_requested)


func _on_help_requested(tip: String) -> void:
    help_requested.emit(tip)


func _on_clear_help_requested() -> void:
    clear_help_requested.emit()
