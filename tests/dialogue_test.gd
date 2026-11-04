extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
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
	player.queue_free()
	target.queue_free()
	print("Dialogue checks passed")
	quit()
