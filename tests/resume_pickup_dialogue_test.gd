extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var progress = root.get_node("GameProgress")
	progress.resume_read = false
	progress.returning_home = true
	var home = load("res://scenes/levels/player_home.tscn").instantiate()
	root.add_child(home)
	var player = home.get_node("%Player")
	var document = home.get_node("%ResumeDocument")
	home.get_node("%Resume").interact(player)
	assert(document.paper.position.y > root.size.y, "Opening must start below the screen")
	await document.slide_tween.finished
	assert(is_zero_approx(document.slide_offset), "Opening must glide into place while the world is paused")
	document.close_button.mouse_entered.emit()
	await document.hover_tween.finished
	assert(document.close_style.bg_color.a > 0.5, "Hover must darken the button")
	document.close_document()
	assert(paused and not progress.resume_read, "Pickup must wait until the exit animation finishes")
	document.close_document()
	await document.closed
	assert(not paused and not document.visible, "The resume popup must close first")
	assert(progress.resume_read and not home.get_node("%Resume").visible, "The resume must be collected")
	assert(player.dialogue_active and player.dialogue_source == home.get_node("%ResumePickupThought"), "Collecting must start the pickup thought")
	assert(not player.dialogue_box.get_node("Margin/Row/SpeakerColumn").visible, "A private thought must not show a speaker name")
	player.dialogue_box.advance()
	assert(not player.dialogue_active, "Dismissing the thought must return control")
	home.queue_free()
	await process_frame
	progress.returning_home = true
	home = load("res://scenes/levels/player_home.tscn").instantiate()
	root.add_child(home)
	assert(not home.get_node("%Player").dialogue_active, "Returning home must not replay the pickup thought")
	print("Resume pickup dialogue checks passed")
	quit()
