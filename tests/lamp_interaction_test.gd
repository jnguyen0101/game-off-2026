extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var home = load("res://scenes/levels/player_home.tscn").instantiate()
	root.add_child(home)
	await process_frame
	var player = home.player
	while player.dialogue_active:
		player.dialogue_box.advance()
	var lamp = home.get_node("Furniture/Bedroom/Lamp/Interaction")
	assert(not lamp.is_on and lamp.interaction_prompt == "Turn on lamp", "Lamp should start off")
	player.position = lamp.global_position + Vector2(16, 0)
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == lamp, "The lamp must be detected without dialogue pages")
	lamp.interact(player)
	assert(lamp.is_on and lamp.get_node("Glow").visible and lamp.get_node("Light").visible, "Turning on must show the glow and light")
	assert(lamp.interaction_prompt == "Turn off lamp", "The prompt must reflect the lamp's state")
	assert(not player.dialogue_active, "Toggling must not open dialogue")
	lamp.interact(player)
	assert(not lamp.is_on and not lamp.get_node("Glow").visible and not lamp.get_node("Light").visible, "Turning off must hide the glow and light")
	home.queue_free()
	print("Lamp interaction checks passed")
	quit()
