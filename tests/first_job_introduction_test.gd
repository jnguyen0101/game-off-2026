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
	progress.guild_test = 0
	progress.first_job = 0
	progress.guild_overnight_complete = false
	progress.first_job_ready = false
	var inn = load("res://scenes/levels/inn.tscn").instantiate()
	root.add_child(inn)
	current_scene = inn
	var player = inn.get_node("World/Player")
	player.set_physics_process(false)
	var npc = inn.get_node("World/Innkeeper")
	player.global_position = npc.global_position + Vector2(0, 26)
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == npc.get_node("Dialogue"), "The innkeeper must be reachable across the inn counter")
	assert(player.test_move(player.global_transform, Vector2(0, -24)), "The innkeeper must have a solid body")
	npc.get_node("Dialogue").interact(player)
	finish_dialogue(player)
	assert(progress.first_job == 0, "Meeting the innkeeper before assignment must not skip the story")
	inn.queue_free()
	await process_frame
	progress.guild_test = 3
	var guild = load("res://scenes/levels/guild.tscn").instantiate()
	root.add_child(guild)
	current_scene = guild
	player = guild.get_node("%Player")
	player.set_physics_process(false)
	var head = guild.get_node("%GuildHead")
	head.interact(player)
	finish_dialogue(player)
	assert(progress.first_job == 0, "The first job must wait until the next morning")
	progress.guild_overnight_complete = true
	guild._update_quest()
	assert(head.lines.size() == head.page_speakers.size() and head.page_speakers.has("Oliver"), "The briefing must switch correctly between Marlow and Oliver")
	for line in head.lines:
		assert(not line.contains("Shift"), "Marlow must not know Oliver's ability")
	head.interact(player)
	assert(progress.first_job == 0, "Starting the briefing must not assign the job before it finishes")
	finish_dialogue(player)
	assert(progress.first_job == 1 and progress.first_job_ready, "Finishing the briefing must assign the first job")
	assert(guild.get_node("%Objective").text == "Speak to the innkeeper", "The assignment must point the player to the client")
	guild.get_node("%Exit").interact(player)
	await transition.transition_finished
	var town = current_scene
	assert(town.get_node("TownHUD/Objective").text == "Speak to the innkeeper", "The objective must survive travel")
	town.get_node("%InnEntrance").interact(town.get_node("World/Player"))
	await transition.transition_finished
	inn = current_scene
	player = inn.get_node("World/Player")
	npc = inn.get_node("World/Innkeeper")
	assert(npc.get_node("Dialogue").lines[1].contains("swallow"), "The client must identify the signet")
	npc.get_node("Dialogue").interact(player)
	assert(progress.first_job == 1, "The client conversation must finish before progressing")
	finish_dialogue(player)
	assert(progress.first_job == 2 and inn.get_node("%Objective").text == "Recover the innkeeper's signet ring", "The client must hand off to the ring recovery objective")
	inn.get_node("%Exit").interact(player)
	await transition.transition_finished
	town = current_scene
	town.get_node("%HomeEntrance").interact(town.get_node("World/Player"))
	await transition.transition_finished
	var home = current_scene
	assert(home.get_node("%Objective").text == "Recover the innkeeper's signet ring", "Home must show the active first-job objective")
	home.get_node("%FrontDoor").interact(home.get_node("%Player"))
	finish_dialogue(home.get_node("%Player"))
	await transition.transition_finished
	town = current_scene
	town.get_node("%InnEntrance").interact(town.get_node("World/Player"))
	await transition.transition_finished
	inn = current_scene
	assert(inn.get_node("World/Innkeeper/Dialogue").lines.size() == 1 and progress.first_job == 2, "Revisiting the innkeeper must show a reminder and preserve progress")
	inn.get_node("%Exit").interact(inn.get_node("%Player"))
	await transition.transition_finished
	town = current_scene
	town.get_node("%GuildEntrance").interact(town.get_node("World/Player"))
	await transition.transition_finished
	guild = current_scene
	head = guild.get_node("%GuildHead")
	assert(head.lines[0].contains("No other souvenirs"), "Marlow must remind Oliver about the assigned job")
	head.interact(guild.get_node("%Player"))
	finish_dialogue(guild.get_node("%Player"))
	assert(progress.first_job == 2, "Talking to Marlow again must not reset the first job")
	guild.queue_free()
	await process_frame
	print("First-job assignment, innkeeper interaction, and persistence checks passed")
	quit()
