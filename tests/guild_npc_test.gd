extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var guild = load("res://scenes/levels/guild.tscn").instantiate()
	root.add_child(guild)
	current_scene = guild
	var player = guild.get_node("%Player")
	player.set_physics_process(false)
	player.set_process(false)
	var npc = guild.get_node("World/SeasonedThief")
	var dialogue = npc.get_node("Dialogue")
	player.global_position = npc.global_position + Vector2(0, 14)
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == dialogue, "The NPC must be reachable through normal interaction detection")
	assert(not npc.get_node("CollisionShape2D").disabled, "The NPC must have a solid body")
	dialogue.interact(player)
	assert(player.dialogue_active, "Interacting must start dialogue")
	while player.dialogue_active:
		player.dialogue_box.advance()
	assert(root.get_node("GameProgress").guild_test == 0, "Talking to the thief must not advance the guild head's quest")
	assert(not root.get_node("GameProgress").shift_unlocked, "Only the guild head should unlock Shift")
	print("Guild NPC dialogue checks passed")
	quit()
