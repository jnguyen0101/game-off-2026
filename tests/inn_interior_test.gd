extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func finish_dialogue(player: Node) -> void:
	while player.dialogue_active:
		player.dialogue_box.advance()

func run_test() -> void:
	var progress = root.get_node("GameProgress")
	var transition = root.get_node("SceneTransition")
	transition.fade_duration = 0.01
	transition.black_hold_duration = 0.01
	progress.guild_test = 3
	progress.guild_overnight_complete = true
	progress.resume_read = true
	progress.shift_unlocked = true
	progress.first_job = 1
	progress.carried_property = load("res://resources/properties/locked.tres")
	progress.town_spawn = &"inn"
	var town = load("res://scenes/levels/town.tscn").instantiate()
	root.add_child(town)
	current_scene = town
	var player = town.get_node("World/Player")
	player.set_physics_process(false)
	assert(not town.has_node("World/Innkeeper"), "The innkeeper must now be inside the inn")
	assert(town.get_node("World/Inn/Sprite2D").global_position == Vector2(199, 353), "The town building must remain in place")
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == town.get_node("%InnEntrance"), "The inn door must be reachable from its return spawn")
	town.get_node("%InnEntrance").interact(player)
	await transition.transition_finished
	var inn = current_scene
	assert(inn.scene_file_path == "res://scenes/levels/inn.tscn", "Entering the inn must load its new interior")
	player = inn.get_node("%Player")
	player.set_physics_process(false)
	assert(player.global_position == inn.get_node("%EntranceSpawn").global_position and player.last_direction == Vector2.UP, "Entry must spawn Oliver inside facing up")
	assert(player.carried_property == progress.carried_property, "Carried properties must survive entering the inn")
	assert(inn.get_node("World").y_sort_enabled, "Player, NPC, and furniture must share Y sorting")
	assert(not inn.get_node("Floor").get_used_cells().is_empty() and not inn.get_node("Trim").get_used_cells().is_empty(), "The interior must have editable floor and trim layers")
	for test in [[Vector2(160,78),Vector2(0,-32)],[Vector2(48,190),Vector2(-32,0)],[Vector2(272,190),Vector2(32,0)],[Vector2(160,208),Vector2(0,32)]]:
		player.global_position = test[0]
		await physics_frame
		assert(player.test_move(player.global_transform, test[1]), "The room walls must block movement")
	player.global_position = Vector2(160,202)
	await physics_frame
	assert(not player.test_move(player.global_transform, Vector2(0,-90)), "The main aisle must remain clear")
	player.global_position = Vector2(160,112)
	await physics_frame
	assert(not player.test_move(player.global_transform, Vector2(64,0)), "The counter must have a reachable customer position")
	player.global_position = Vector2(224,112)
	await physics_frame
	await physics_frame
	var dialogue = inn.get_node("World/Innkeeper/Dialogue")
	assert(player.get_dialogue_target() == dialogue, "The innkeeper must be reachable across the bar")
	assert(player.test_move(player.global_transform, Vector2(0,-24)), "The bar must block the player from walking through it")
	dialogue.interact(player)
	assert(player.dialogue_active and player.dialogue_box.pages[1].contains("swallow"), "The signet-ring conversation must remain intact")
	finish_dialogue(player)
	assert(progress.first_job == 2 and inn.get_node("%Objective").text == "Recover the innkeeper's signet ring", "Speaking inside must update the quest")
	inn.get_node("%Exit").interact(player)
	await transition.transition_finished
	town = current_scene
	player = town.get_node("World/Player")
	player.set_physics_process(false)
	assert(player.global_position == town.get_node("%InnSpawn").global_position and player.last_direction == Vector2.DOWN, "Leaving must spawn Oliver outside the inn facing down")
	assert(player.carried_property != null and progress.first_job == 2, "Leaving must preserve carried properties and quest progress")
	town.get_node("%InnEntrance").interact(player)
	await transition.transition_finished
	inn = current_scene
	assert(inn.get_node("World/Innkeeper/Dialogue").lines.size() == 1, "Returning must show the client's reminder")
	inn.queue_free()
	await process_frame
	print("Inn interior, collisions, travel, and client quest checks passed")
	quit()
