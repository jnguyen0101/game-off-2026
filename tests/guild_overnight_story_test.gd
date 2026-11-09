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
	progress.resume_read = true
	progress.shift_unlocked = true
	progress.returning_home = true
	progress.guild_test = 0
	progress.guild_overnight_complete = false
	progress.waking_next_morning = false
	progress.first_job_ready = false
	var home = load("res://scenes/levels/player_home.tscn").instantiate()
	root.add_child(home)
	current_scene = home
	home.get_node("%BedThought").interact(home.get_node("%Player"))
	finish_dialogue(home.get_node("%Player"))
	assert(not transition.is_transitioning and not progress.guild_overnight_complete, "Sleep must not skip the application and guild test")
	home.queue_free()
	await process_frame
	progress.guild_test = 2
	progress.test_chest_locked = false
	progress.test_chest_opened = true
	progress.test_crate_locked = true
	progress.test_keg_locked = false
	progress.carried_property = null
	var guild = load("res://scenes/levels/guild.tscn").instantiate()
	root.add_child(guild)
	current_scene = guild
	var player = guild.get_node("%Player")
	player.set_physics_process(false)
	var head = guild.get_node("%GuildHead")
	assert(head.lines[-2].contains("Come back tomorrow"), "Acceptance must invite Oliver back tomorrow")
	assert(head.page_speakers[-1] == "Marlow" and head.page_speakers[-2] == "Marlow", "Marlow must deliver the bedtime instructions")
	head.interact(player)
	finish_dialogue(player)
	assert(progress.guild_test == 3 and progress.get_objective() == "Go home and rest", "Acceptance must send the player home")
	guild.get_node("%Exit").interact(player)
	await transition.transition_finished
	var town = current_scene
	assert(town.get_node("TownHUD/Objective").text == "Go home and rest", "Town must preserve the rest objective")
	town.get_node("%HomeEntrance").interact(town.get_node("World/Player"))
	await transition.transition_finished
	home = current_scene
	home.sleep_hold_duration = 0.02
	player = home.get_node("%Player")
	player.set_physics_process(false)
	home.get_node("%FrontDoor").interact(player)
	assert(player.dialogue_box.pages[0].contains("rest"), "The blocked exit must explain why Oliver should stay home")
	finish_dialogue(player)
	assert(current_scene == home and not transition.is_transitioning, "Oliver must not be able to leave before sleeping")
	assert(not progress.guild_overnight_complete, "Checking the door must not advance the night")
	player.global_position = home.get_node("%MorningSpawn").global_position
	await physics_frame
	await physics_frame
	var bed = home.get_node("%BedThought")
	assert(player.get_dialogue_target() == bed, "The bed's sleep interaction must be reachable")
	assert(bed.interaction_prompt == "Go to sleep" and not player.dialogue_active, "Returning home must offer sleep without replaying the opening")
	bed.interact(player)
	assert(player.dialogue_box.pages == bed.lines and player.dialogue_box.pages.size() == 2, "Bedtime must show Oliver's configured acceptance reflection")
	finish_dialogue(player)
	assert(transition.is_transitioning and paused, "Finishing the reflection must begin a protected fade")
	assert(progress.guild_overnight_complete, "The scripted night must advance once")
	await transition.transition_finished
	home = current_scene
	player = home.get_node("%Player")
	player.set_physics_process(false)
	assert(not paused and progress.guild_overnight_complete and not progress.waking_next_morning, "Morning must restore gameplay and consume the wake flag")
	assert(player.global_position == home.get_node("%MorningSpawn").global_position and player.last_direction == Vector2.DOWN, "Oliver must wake beside the bed facing down")
	assert(player.dialogue_active and player.dialogue_source == home.get_node("%NextMorningThought"), "Morning must use the new thought instead of the resume introduction")
	assert(home.get_node("%Objective").text == "Return to Marlow for your first job", "Morning must point the player back to Marlow")
	assert(not home.get_node("%Resume").visible, "Sleeping must not respawn the collected resume")
	assert(progress.shift_unlocked and progress.test_chest_opened and progress.test_crate_locked, "Sleeping must preserve Shift and test-object progress")
	finish_dialogue(player)
	home.get_node("%BedThought").interact(player)
	finish_dialogue(player)
	assert(not transition.is_transitioning, "The player must not repeat the scripted night")
	home.get_node("%FrontDoor").interact(player)
	finish_dialogue(player)
	await transition.transition_finished
	town = current_scene
	assert(town.get_node("TownHUD/Objective").text == "Return to Marlow for your first job", "The morning objective must survive travel")
	town.get_node("%GuildEntrance").interact(town.get_node("World/Player"))
	await transition.transition_finished
	guild = current_scene
	player = guild.get_node("%Player")
	player.set_physics_process(false)
	head = guild.get_node("%GuildHead")
	assert(guild.get_node("World/SeasonedThief/Dialogue").lines[0].begins_with("Back again?"), "Rook must use his next-day greeting")
	assert(head.lines[0].begins_with("Morning"), "Marlow must greet Oliver the next morning")
	head.interact(player)
	finish_dialogue(player)
	assert(progress.first_job_ready and progress.get_objective() == "Speak to the innkeeper", "Returning to Marlow must finish the overnight beat")
	assert(guild.get_node("%Wooden Chest").get_node("Sprite2D").frame == 5, "The tutorial chest must remain open the next day")
	guild.queue_free()
	await process_frame
	print("Guild acceptance, overnight, and next-morning story checks passed")
	quit()
