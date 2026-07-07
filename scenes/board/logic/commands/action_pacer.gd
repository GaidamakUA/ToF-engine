class_name ActionPacer
extends RefCounted


func wait_after(_result: CommandResult) -> void:
	if false:
		await (Engine.get_main_loop() as SceneTree).process_frame
	return
