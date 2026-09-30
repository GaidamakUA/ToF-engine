class_name BoardPresenter
extends RefCounted


signal became_idle


var model: BoardModel
var view: Object
var active_ability: Ability
var selected_position: Variant = null
var hovered_position: Variant = null
var ability_origin: Variant = null
var legal_moves: Dictionary[Vector2i, Array] = {}
var legal_interactions: Array[Vector2i] = []
var legal_ability_targets: Array[Vector2i] = []
var _queued_updates: Array[Array] = []
var _presenting: bool = false
var _active_command: BoardCommand
var _active_update: Array = []
var _refresh_after_command: Callable


func _init(board_model: BoardModel, board_view: Object) -> void:
	self.model = board_model
	self.view = board_view
	self.model.updated.connect(self._on_model_updated)
	self.model.command_requested.connect(self._on_command_requested)
	self.view.connect(&"presentation_finished", self._on_presentation_finished)
	self.view.connect(&"command_impact", self._on_command_impact)


func set_hover(position: Variant) -> void:
	if self._presenting:
		return
	if self.hovered_position != position:
		self.hovered_position = position
		self._render_interaction()


func select_position(position: Vector2i) -> void:
	if self._presenting:
		return
	self._select(position)


func press_tile(position: Vector2i) -> void:
	if self._presenting:
		return
	if self.active_ability != null:
		if self.legal_ability_targets.has(position):
			var origin: Vector2i = self.ability_origin
			self._refresh_after_command = self._refresh_or_clear.bind(origin, position)
			if self.model.use_ability(origin, self.active_ability.get_key(), position):
				self.cancel_targeting()
			else:
				self._refresh_after_command = Callable()
		return

	if self.model.is_tile_selectable_for_current_player(position):
		var open_abilities: bool = self.selected_position == position
		self._select(position)
		self._call_view(&"show_contextual_select", [open_abilities])
		self._finish_control()
		return

	if self.selected_position != null:
		var source: Vector2i = self.selected_position
		if self.legal_moves.has(position):
			self._refresh_after_command = self._refresh_or_clear.bind(position)
			if self.model.move_unit(source, position):
				self._call_view(&"show_contextual_select", [false])
			else:
				self._refresh_after_command = Callable()
				self.clear_selection()
		elif self.legal_interactions.has(position):
			var target: TileStateSnapshot = self.model.get_snapshot().map.get_tile(position)
			var accepted: bool = false
			self._refresh_after_command = self._refresh_or_clear.bind(source)
			if target != null and target.unit != null:
				accepted = self.model.attack_unit(source, position)
			elif target != null and target.building != null:
				accepted = self.model.capture_building(source, position)
			if not accepted:
				self._refresh_after_command = Callable()
		else:
			self.clear_selection()
	self._finish_control()


func clear_selection() -> void:
	self._clear_selection_state()
	self._call_view(&"clear_selection_view")


func cancel_interaction() -> void:
	if self.active_ability != null:
		self.cancel_targeting()
	else:
		self.clear_selection()


func start_targeting(origin: Vector2i, ability: Ability) -> void:
	if self._presenting:
		return
	self.active_ability = ability
	self.ability_origin = origin
	self.legal_ability_targets = self.model.get_legal_ability_targets(origin, ability.get_key())
	self._render_interaction()


func cancel_targeting() -> void:
	self.active_ability = null
	self.ability_origin = null
	self.legal_ability_targets.clear()
	self._render_interaction()
	self._call_view(&"clear_ability_view")


func end_turn() -> bool:
	if self._presenting:
		return false
	self.hovered_position = null
	self._clear_selection_state()
	return self.model.end_turn()


func undo_last_move() -> bool:
	if self._presenting:
		return false
	var undone: bool = self.model.undo_last_move()
	if undone:
		self._clear_selection_state()
	return undone


func _select(position: Vector2i) -> void:
	self.selected_position = position
	self.legal_moves = self.model.get_legal_moves(position)
	self.legal_interactions = self.model.get_legal_interactions(position)
	self._render_interaction()


func _clear_selection_state() -> void:
	self.active_ability = null
	self.selected_position = null
	self.ability_origin = null
	self.legal_moves.clear()
	self.legal_interactions.clear()
	self.legal_ability_targets.clear()
	self._render_interaction()


func is_presenting() -> bool:
	return self._presenting


func wait_until_idle() -> void:
	while self._presenting or not self._queued_updates.is_empty():
		await self.became_idle


func _refresh_or_clear(position: Vector2i, fallback: Variant = null) -> void:
	if self.model.is_tile_selectable_for_current_player(position):
		self._select(position)
	elif fallback != null and self.model.is_tile_selectable_for_current_player(fallback):
		self._select(fallback)
	else:
		self.clear_selection()


func _finish_control() -> void:
	self._call_view(&"hover_tile")
	self._call_view(&"play_tile_selected_feedback")


func _on_model_updated(snapshot: BoardStateSnapshot, domain_events: Array[BoardDomainEvent]) -> void:
	if self._active_command != null:
		self._active_update = [snapshot, domain_events]
		return
	self._queued_updates.append([snapshot, domain_events])
	self._present_next_update()


func _on_command_requested(command: BoardCommand) -> void:
	assert(self._active_command == null)
	self._active_command = command
	self._active_update.clear()
	self._presenting = true
	self._call_view(&"present_command_lead_in", [command])


func _on_command_impact() -> void:
	if self._active_command == null:
		return
	if not self.model.commit_pending_command():
		self._finish_active_command()
		return
	if self._active_update.is_empty():
		self._finish_active_command()
		return
	self._call_view(
		&"present_model_update",
		[self._active_update[0], self._active_update[1], self._active_command]
	)


func _render_interaction() -> void:
	self._call_view(&"render_interaction", [self])


func _call_view(method: StringName, arguments: Array = []) -> void:
	self.view.callv(method, arguments)


func _present_next_update() -> void:
	if self._presenting or self._queued_updates.is_empty():
		return
	var update: Array = self._queued_updates.pop_front()
	self._presenting = true
	self._call_view(&"present_model_update", update)


func _on_presentation_finished() -> void:
	if self._active_command != null:
		self._finish_active_command()
		return
	self._presenting = false
	self._present_next_update()
	if not self._presenting and self._queued_updates.is_empty():
		self.became_idle.emit()


func _finish_active_command() -> void:
	self._active_command = null
	self._active_update.clear()
	self._presenting = false
	var refresh: Callable = self._refresh_after_command
	self._refresh_after_command = Callable()
	if refresh.is_valid():
		refresh.call()
	self.model.complete_pending_command()
	self._present_next_update()
	if not self._presenting and self._queued_updates.is_empty():
		self.became_idle.emit()
