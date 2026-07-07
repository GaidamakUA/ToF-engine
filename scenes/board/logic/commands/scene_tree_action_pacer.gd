class_name SceneTreeActionPacer
extends ActionPacer


var board_host: Node = null
var scene_tree: SceneTree = null


func _init(host: Variant = null) -> void:
	if host is SceneTree:
		self.scene_tree = host
	elif host is Node:
		self.board_host = host


func wait_after(result: CommandResult) -> void:
	if result == null or result.delay <= 0.0:
		return
	var active_tree := _get_scene_tree()
	if active_tree == null:
		return
	await active_tree.create_timer(result.delay).timeout


func _get_scene_tree() -> SceneTree:
	if self.scene_tree != null:
		return self.scene_tree
	if self.board_host != null:
		return self.board_host.get_tree()
	return null
