extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func finish_dialogue(player: Node) -> void:
	while player.dialogue_active:
		advance_page(player)


func run_test() -> void:
	var progress = root.get_node("GameProgress")
	progress.guild_test = 0
	progress.guild_overnight_complete = false
	progress.first_job_ready = false
	progress.shift_unlocked = false
	progress.test_chest_locked = true
	progress.test_chest_opened = false
	progress.test_crate_locked = false
	progress.test_keg_locked = false
	progress.shift_discovery_seen = false
	progress.carried_property = null
	progress.resume_read = true
	var transition = root.get_node("SceneTransition")
	transition.fade_duration = 0.02
	transition.black_hold_duration = 0.01
	var guild = load("res://scenes/levels/guild.tscn").instantiate()
	root.add_child(guild)
	current_scene = guild
	var player = guild.get_node("%Player")
	player.set_physics_process(false)
	var head = guild.get_node("%GuildHead")
	assert(head.lines[0].begins_with("Marlow."), "The guild head must introduce himself")
	assert(guild.get_node("World/SeasonedThief/Dialogue").speaker_name == "Seasoned Thief", "Rook's name must start unrevealed")
	var chest = guild.get_node("%Wooden Chest")
	var interaction = chest.get_node("Interaction")
	player.nearby_object = chest
	player.enter_shift_mode()
	player.transfer_property()
	player.update_interaction_prompts()
	assert(not player.shift_mode_active and Engine.time_scale == 1.0, "Shift must stay inactive before the interview")
	assert(player.carried_property == null and progress.test_chest_locked, "Properties must remain locked before the interview")
	assert(not player.property_slot.visible and not player.property_panel.visible and not player.interaction_prompt.text.contains("Shift"), "Shift UI must stay hidden before the interview")
	assert(not guild.has_node("World/TestDoor") and not guild.has_node("World/TestPrize"), "The old room test must be removed")
	for line in head.lines:
		assert(not line.contains("Shift") and not line.contains("properties"), "The guild head must not know the ability")
	interaction.interact(player)
	finish_dialogue(player)
	assert(not progress.test_chest_opened and progress.guild_test == 0, "The player should receive the assignment first")
	head.interact(player)
	assert(not progress.shift_unlocked, "Starting the interview must not unlock Shift before it finishes")
	finish_dialogue(player)
	assert(progress.shift_unlocked, "Finishing the interview must unlock Shift")
	assert(progress.guild_test == 1, "The interview must assign the chest test")
	assert(guild.get_node("%Objective").text == "Open the chest that has a lock on it", "The objective must be the simpler chest test")
	interaction.interact(player)
	finish_dialogue(player)
	assert(not progress.test_chest_opened, "E must not open a locked chest")
	player.position = chest.position + Vector2(0, 16)
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == interaction, "The chest interaction must be reachable")
	player.nearby_object = chest
	player.enter_shift_mode()
	player.transfer_property()
	finish_dialogue(player)
	player.exit_shift_mode()
	assert(player.carried_property.property_name == "LOCKED" and not progress.test_chest_locked, "Shift must steal the chest's lock")
	assert(not progress.test_chest_opened and progress.guild_test == 1, "Unlocking alone must not count as opening")
	interaction.interact(player)
	finish_dialogue(player)
	assert(progress.test_chest_opened and progress.guild_test == 2, "Opening the unlocked chest must advance the test")
	assert(chest.get_node("Sprite2D").frame == 5, "The chest must show the opened frame")
	assert(not chest.get_node("CollisionShape2D").disabled, "An unlocked chest should remain physically solid")
	assert(guild.get_node("%Objective").text == "Place LOCKED on the crate or keg", "Opening must prompt the player to place the property")
	player.transfer_property()
	assert(progress.test_chest_locked and not progress.test_chest_opened and progress.guild_test == 1, "Relocking must reset the unfinished chest test")
	assert(guild.get_node("%Objective").text == "Open the chest that has a lock on it", "Relocking must restore the chest objective")
	assert(head.lines == ["Open the locked chest. I'll be right here."], "Relocking must remove the success dialogue")
	head.interact(player)
	finish_dialogue(player)
	assert(progress.guild_test == 1, "Reporting a relocked chest must not pass the test")
	player.transfer_property()
	assert(progress.guild_test == 1 and not progress.test_chest_opened, "Unlocking again must still require opening the chest")
	interaction.interact(player)
	finish_dialogue(player)
	assert(progress.guild_test == 2, "Reopening must allow the player to finish the test")
	var crate = guild.get_node("%Wooden Crate")
	head.interact(player)
	finish_dialogue(player)
	assert(progress.guild_test == 2, "The test must require placing LOCKED on the crate")
	player.nearby_object = crate
	player.transfer_property()
	assert(progress.test_crate_locked and player.carried_property == null, "Placing must lock the crate and empty the player's hand")
	assert(guild.get_node("%Objective").text == "Return to the guild head", "Locking the crate must allow reporting back")
	player.transfer_property()
	assert(not progress.test_crate_locked and guild.get_node("%Objective").text == "Place LOCKED on the crate or keg", "Taking LOCKED back must restore the placement objective")
	player.nearby_object = guild.get_node("%Wooden Keg")
	player.transfer_property()
	assert(progress.test_keg_locked and not progress.test_crate_locked and progress.has_placed_test_lock(), "The keg must count as an alternative destination")
	guild.get_node("%Exit").interact(player)
	await transition.transition_finished
	var town = current_scene
	assert(progress.shift_unlocked, "Shift must remain unlocked after scene travel")
	assert(progress.test_keg_locked and town.get_node("World/Player").carried_property == null, "The crate lock and empty hand must survive travel")
	town.get_node("%GuildEntrance").interact(town.get_node("World/Player"))
	await transition.transition_finished
	guild = current_scene
	player = guild.get_node("%Player")
	player.set_physics_process(false)
	chest = guild.get_node("%Wooden Chest")
	assert(not progress.test_chest_locked and progress.test_chest_opened and chest.get_node("Sprite2D").frame == 5, "The chest's state must survive travel")
	assert(guild.get_node("%Wooden Keg").get_node("ShiftableComponent").has_property(load("res://resources/properties/locked.tres")), "The crate must restore LOCKED after travel")
	head = guild.get_node("%GuildHead")
	assert(head.lines[1].contains("How did you open it"), "The guild head should wonder how the player opened the chest")
	head.interact(player)
	for index in 3:
		advance_page(player)
	assert(player.dialogue_box.get_node("Margin/Row/SpeakerColumn/Name").text == "Seasoned Thief", "The interruption must initially hide Rook's name")
	advance_page(player)
	assert(player.dialogue_box.get_node("Margin/Row/SpeakerColumn/Name").text == "Marlow", "Marlow must address Rook")
	advance_page(player)
	assert(player.dialogue_box.get_node("Margin/Row/SpeakerColumn/Name").text == "Rook", "Rook's reply must use his revealed name")
	finish_dialogue(player)
	assert(progress.guild_test == 3 and guild.get_node("%Objective").text == "Go home and rest", "The debrief must complete the test")
	var thief_dialogue = guild.get_node("World/SeasonedThief/Dialogue")
	assert(not thief_dialogue.lines.is_empty(), "Passing must retain the thief's post-test dialogue")
	assert(thief_dialogue.speaker_name == "Rook", "Passing must reveal Rook's name for later conversations")
	thief_dialogue.interact(player)
	assert(player.dialogue_active, "The thief's post-test dialogue must be interactable")
	finish_dialogue(player)
	guild.queue_free()
	print("Guild chest quest checks passed")
	quit()


func advance_page(player: Node) -> void:
	player.dialogue_box.finish_typing()
	player.dialogue_box.advance()
