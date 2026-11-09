extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var progress = root.get_node("GameProgress")
	progress.guild_test = 3
	progress.guild_overnight_complete = false
	var guild = load("res://scenes/levels/guild.tscn").instantiate()
	root.add_child(guild)
	var previous_lines: Array = guild.get_node("World/SeasonedThief/Dialogue").lines.duplicate()
	guild.queue_free()
	await process_frame
	progress.guild_overnight_complete = true
	guild = load("res://scenes/levels/guild.tscn").instantiate()
	root.add_child(guild)
	var rook = guild.get_node("World/SeasonedThief/Dialogue")
	assert(rook.speaker_name == "Rook" and rook.lines != previous_lines, "Rook must have different dialogue the next day")
	var player = guild.get_node("%Player")
	rook.interact(player)
	assert(player.dialogue_active and player.dialogue_box.pages == rook.lines, "Rook's next-day dialogue must be playable")
	while player.dialogue_active:
		player.dialogue_box.advance()
	assert(not progress.first_job_ready, "Talking to Rook must not complete the return-to-Marlow objective")
	guild.queue_free()
	await process_frame
	print("Rook next-day dialogue checks passed")
	quit()
