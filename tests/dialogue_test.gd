extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	root.size = Vector2i(320, 180)
	var player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	player.dialogue_box.characters_per_second = 0.0
	var target = load("res://scenes/objects/dialogue_interactable.tscn").instantiate()
	var lines: Array[String] = ["First page", "Last page"]
	target.lines = lines
	root.add_child(target)
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == target, "Nearby dialogue objects should be detected")
	player.start_dialogue(target)
	assert(player.dialogue_active and player.dialogue_box.visible, "E interaction should open dialogue")
	assert(player.dialogue_box.page_index == 0, "Opening must show the first page")
	player.enter_shift_mode()
	assert(not player.shift_mode_active, "Shift must be blocked during dialogue")
	Input.action_press("move_right")
	player._physics_process(0.016)
	assert(player.velocity == Vector2.ZERO, "Dialogue must prevent movement")
	Input.action_release("move_right")
	player.dialogue_box.advance()
	assert(player.dialogue_active and player.dialogue_box.page_index == 1, "Next should advance one page")
	player.dialogue_box.advance()
	assert(not player.dialogue_active and not player.dialogue_box.visible, "Last page should close and unlock controls")
	player.start_dialogue(target)
	assert(player.dialogue_box.page_index == 0, "Repeat interactions should restart dialogue")
	player.dialogue_box.advance()
	player.dialogue_box.advance()
	var portrait := GradientTexture2D.new()
	portrait.width = 32
	portrait.height = 32
	target.portrait = portrait
	target.is_character = true
	target.speaker_name = "Guild Head"
	target.lines.assign(["No experience. No lockpicking. You have written 'enthusiastic' three times. One chance. Let's see what you can do."])
	player.start_dialogue(target)
	await process_frame
	await process_frame
	var column = player.dialogue_box.get_node("Margin/Row/SpeakerColumn")
	assert(column.visible and column.get_node("Portrait").texture == portrait, "Dialogue should show the configured portrait")
	assert(column.get_node("Name").text == "Guild Head", "The name should appear beneath the portrait")
	assert(player.dialogue_box.size.y <= 64.0, "The portrait and text must fit the compact dialogue box")
	assert(is_equal_approx(player.dialogue_box.position.y + player.dialogue_box.size.y, 174.0), "The dialogue bottom must stay six pixels above the viewport edge")
	var text_label = player.dialogue_box.get_node("Margin/Row/Content/Text")
	assert(text_label.get_minimum_size().y <= text_label.size.y, "Dialogue text should fit without clipping")
	player.dialogue_box.advance()
	target.lines.assign(["First speaker", "Second speaker"])
	target.page_speakers.assign(["Marlow", "Rook"])
	player.start_dialogue(target)
	assert(column.get_node("Name").text == "Marlow", "The first page must use its speaker")
	player.dialogue_box.advance()
	assert(column.get_node("Name").text == "Rook", "Advancing must switch speakers")
	assert(not column.get_node("Portrait").visible, "Another speaker must not inherit the main speaker's portrait")
	player.dialogue_box.advance()
	target.is_character = false
	player.start_dialogue(target)
	assert(not column.visible, "Object dialogue must hide names and portraits even when configured")
	player.dialogue_box.advance()
	player.dialogue_box.advance()
	target.portrait = null
	target.speaker_name = ""
	player.start_dialogue(target)
	assert(not column.visible and column.get_node("Portrait").texture == null, "Narration must hide and clear the previous portrait")
	player.dialogue_box.advance()
	player.dialogue_box.advance()
	player.queue_free()
	target.queue_free()
	print("Dialogue checks passed")
	quit()
