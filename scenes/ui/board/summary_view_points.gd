class_name SidePointsSummary
extends Control


var _icons_factory: IconsFactory = IconsFactory.new()
var _current_icon: Node = null

var _building_points: int = 0
var _unit_points: int = 0
var _ap_points: int = 0

@onready var _icon_anchor: Control = $"background/icon_anchor/icon_anchor"
@onready var _building_points_label: Label = $"background/building_points"
@onready var _unit_points_label: Label = $"background/unit_points"
@onready var _ap_points_label: Label = $"background/ap_points"
@onready var _total_points_label: Label = $"background/total_points"


func show_player_points(player_data: Dictionary[String, Variant], board: Board) -> void:
    var side: String = str(player_data["side"])
    _set_icon(side)
    _calculate_building_points(side, board)
    _calculate_unit_points(side, board)
    _calculate_ap_points(player_data)
    _calculate_total_points()


func _set_icon(side: String) -> void:
    if _current_icon:
        _current_icon.queue_free()
    _current_icon = _icons_factory.get_named_icon(side + "_gem")
    _icon_anchor.add_child(_current_icon)


func _calculate_building_points(side: String, board: Board) -> void:
    _building_points = 0
    for tile: MapTile in board.map.model.tiles.values():
        if tile.building.is_present():
            var building: BaseBuilding = tile.building.get_map_object() as BaseBuilding
            assert(building != null)
            if building.side == side:
                _building_points += building.capture_value
    _building_points_label.set_text(str(_building_points))


func _calculate_unit_points(side: String, board: Board) -> void:
    _unit_points = 0
    for tile: MapTile in board.map.model.tiles.values():
        if tile.unit.is_present():
            var unit: BaseUnit = tile.unit.get_map_object() as BaseUnit
            assert(unit != null)
            if unit.side == side:
                _unit_points += unit.get_value()
    _unit_points_label.set_text(str(_unit_points))


func _calculate_ap_points(player_data: Dictionary[String, Variant]) -> void:
    _ap_points = int(player_data["ap"])
    _ap_points_label.set_text(str(_ap_points))


func _calculate_total_points() -> void:
    _total_points_label.set_text(str(_building_points + _unit_points + _ap_points))
