extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func finish_dialogue(player: Node) -> void:
	while player.dialogue_active:
		player.dialogue_box.advance()

func run_test() -> void:
	var progress = root.get_node("GameProgress")
	progress.guild_test = 1
	progress.shift_unlocked = true
	progress.test_chest_locked = true
	progress.test_chest_opened = false
	progress.shift_discovery_seen = false
	var guild = load("res://scenes/levels/guild.tscn").instantiate()
	root.add_child(guild)
	var player = guild.get_node("%Player")
	player.set_process(false)
	player.set_physics_process(false)
	var chest = guild.get_node("%Wooden Chest")
	player.nearby_object = chest
	player.enter_shift_mode()
	player.transfer_property()
	assert(player.dialogue_active and player.dialogue_box.pages == ["That… wasn’t in the book.", "I should probably put this somewhere else."], "The first stolen lock must trigger the discovery thought")
	assert(not player.shift_mode_active and Engine.time_scale == 1.0, "The thought must exit Shift Vision")
	assert(player.carried_property != null and not progress.test_chest_locked, "The stolen property must remain carried")
	assert(not player.dialogue_box.get_node("Margin/Row/SpeakerColumn").visible, "Private thoughts must not reveal the ability through an NPC speaker")
	player.transfer_property()
	assert(not progress.test_chest_locked, "Dialogue must prevent further transfers")
	finish_dialogue(player)
	chest.interact(player)
	assert(progress.test_chest_opened and not player.dialogue_box.pages.has("I should probably put this somewhere else."), "Opening the chest must not repeat the placement thought")
	finish_dialogue(player)
	player.transfer_property()
	player.transfer_property()
	assert(not player.dialogue_active, "Taking the lock again must not repeat discovery")
	chest.interact(player)
	assert(not player.dialogue_box.pages.has("I should probably put this somewhere else."), "The placement hint must only play once")
	finish_dialogue(player)
	guild.queue_free()
	await process_frame
	guild = load("res://scenes/levels/guild.tscn").instantiate()
	root.add_child(guild)
	assert(progress.shift_discovery_seen, "Tutorial thoughts must remain seen across scene changes")
	assert(not guild.get_node("%Player").dialogue_active, "Returning must not replay tutorial thoughts")
	print("Shift tutorial thought checks passed")
	quit()
