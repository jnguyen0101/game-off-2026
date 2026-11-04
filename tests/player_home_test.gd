extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var home = load("res://scenes/levels/player_home.tscn").instantiate()
	root.add_child(home)
	current_scene = home
	await process_frame
	await physics_frame
	var player = home.player
	assert(home.get_node("Floor").get_used_cells().size() == 98, "The room floor must contain all 98 tiles")
	assert(home.get_node("Floor").get_cell_source_id(Vector2i(3, 3)) == 0, "Floor tiles must use the correct atlas")
	assert(player.dialogue_active, "The morning should open with the player's thoughts")
	while player.dialogue_active:
		player.dialogue_box.advance()
	assert(not home.resume_read, "The resume must not be read automatically")
	home._on_front_door_finished()
	assert(not home.is_queued_for_deletion(), "The door must wait until the resume is read")
	assert(player.test_move(player.transform, Vector2(-100, 0)), "The left wall must block movement")
	player.position = Vector2(208, 90)
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == home.resume, "The resume must be reachable from below the desk")
	player.start_dialogue(home.resume)
	while player.dialogue_active:
		player.dialogue_box.advance()
	assert(home.resume_read, "Finishing the resume must update the opening objective")
	assert(home.front_door.interaction_prompt == "Leave for the guild", "The door must offer to leave")
	assert(home.front_door.lines[0].begins_with("Resume ready."), "The departure dialogue must update")
	home._on_front_door_finished()
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/levels/test_level.tscn", "Leaving home must load the temporary guild destination")
	current_scene.queue_free()
	print("Player home checks passed")
	quit()
