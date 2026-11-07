extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var transition = root.get_node("SceneTransition")
	transition.fade_duration = 0.02
	transition.black_hold_duration = 0.01
	var progress = root.get_node("GameProgress")
	progress.resume_read = true
	progress.town_spawn = &"home"
	var town = load("res://scenes/levels/town.tscn").instantiate()
	root.add_child(town)
	current_scene = town
	var player = town.get_node("World/Player")
	player.set_physics_process(false)
	player.global_position = town.get_node("%GuildSpawn").global_position
	await physics_frame
	await physics_frame
	player.move_and_collide(Vector2(0, -40))
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == town.get_node("%GuildEntrance"), "The guild entrance must be reachable at its pictured door")
	town.get_node("%GuildEntrance").interact(player)
	await transition.transition_finished
	var guild = current_scene
	assert(guild.scene_file_path == "res://scenes/levels/guild.tscn", "The guild door must load the new interior")
	player = guild.get_node("%Player")
	player.set_physics_process(false)
	assert(player.global_position == guild.get_node("%EntranceSpawn").global_position, "Entering must use the interior spawn marker")
	assert(player.last_direction == Vector2.UP, "The player must face into the room")
	assert(not player.dialogue_active, "Entering must not automatically open dialogue")
	await physics_frame
	await physics_frame
	assert(player.move_and_collide(Vector2(0, 80)) != null, "The bottom trim must keep the player inside")
	var trim: TileMapLayer = guild.get_node("Trim")
	for cell in trim.get_used_cells():
		assert(trim.get_cell_tile_data(cell).get_collision_polygons_count(0) > 0, "Every perimeter tile must block movement")
	player.position = guild.get_node("%Exit").position + Vector2(0, -12)
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == guild.get_node("%Exit"), "The exit must be reachable inside the room")
	guild.get_node("%Exit").interact(player)
	await transition.transition_finished
	town = current_scene
	assert(town.scene_file_path == "res://scenes/levels/town.tscn", "The interior exit must return to town")
	player = town.get_node("World/Player")
	assert(player.global_position == town.get_node("%GuildSpawn").global_position, "Leaving must spawn outside the guild, not at home")
	assert(player.last_direction == Vector2.DOWN, "Leaving must face away from the door")
	assert(progress.resume_read, "Guild travel must preserve opening progress")
	assert(not paused and not transition.is_transitioning, "The fade must restore gameplay")
	town.queue_free()
	print("Guild transition checks passed")
	quit()
