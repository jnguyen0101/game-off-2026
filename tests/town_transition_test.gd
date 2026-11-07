extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var transition = root.get_node("SceneTransition")
	transition.fade_duration = 0.02
	transition.black_hold_duration = 0.01
	var progress = root.get_node("GameProgress")
	progress.resume_read = false
	progress.returning_home = false
	var home = load("res://scenes/levels/player_home.tscn").instantiate()
	root.add_child(home)
	current_scene = home
	await process_frame
	while home.player.dialogue_active:
		home.player.dialogue_box.advance()
	home._on_front_door_finished()
	await process_frame
	assert(current_scene == home, "The player must read the resume before leaving")
	home.player.start_dialogue(home.resume)
	while home.player.dialogue_active:
		home.player.dialogue_box.advance()
	home.player.start_dialogue(home.front_door)
	while home.player.dialogue_active:
		home.player.dialogue_box.advance()
	assert(transition.is_transitioning and paused, "Travel must freeze gameplay while fading")
	transition.change_scene("res://scenes/levels/player_home.tscn")
	assert(transition.overlay.size == root.get_visible_rect().size, "The fade must cover the whole viewport")
	await transition.transition_finished
	assert(not paused and not transition.overlay.visible, "Travel must restore gameplay and clear the overlay")
	var town = current_scene
	assert(town.scene_file_path == "res://scenes/levels/town.tscn", "The home door must lead to town")
	assert(not town.get_node("Grass").get_used_cells().is_empty(), "The town must have an editable ground layer")
	var player = town.get_node("World/Player")
	assert(player.global_position == town.get_node("%HomeSpawn").global_position, "The player must appear at HomeSpawn")
	assert(not player.dialogue_active, "The town must not automatically return the player home")
	var house = town.get_node("World/PlayerHouse")
	player.set_physics_process(false)
	await physics_frame
	var collision = player.move_and_collide(Vector2(0, -48))
	assert(collision != null and collision.get_collider() == house, "The house must block movement")
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == town.get_node("%HomeEntrance"), "The pictured door must be reachable from outside")
	town.get_node("%HomeEntrance").interact(player)
	await transition.transition_finished
	assert(current_scene.scene_file_path == "res://scenes/levels/player_home.tscn", "Entering home must return to the home scene")
	assert(current_scene.resume_read, "Resume progress must survive scene changes")
	assert(not current_scene.player.dialogue_active, "Returning must not replay the wake-up introduction")
	assert(current_scene.player.global_position == current_scene.get_node("%EntranceSpawn").global_position, "The player must return at EntranceSpawn")
	assert(current_scene.player.last_direction == Vector2.UP, "The player must face up when returning home")
	assert(current_scene.player.animated_sprite.animation == &"idle_up", "Returning home must show the upward idle animation")
	current_scene.queue_free()
	print("Town transition checks passed")
	quit()
