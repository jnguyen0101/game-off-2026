extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	root.size = Vector2i(320, 180)
	var progress = root.get_node("GameProgress")
	progress.shift_unlocked = true
	progress.test_chest_locked = true
	progress.test_chest_opened = false
	progress.carried_property = null
	var player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	var chest = load("res://scenes/objects/locked_chest.tscn").instantiate()
	chest.position = Vector2(140, 80)
	root.add_child(chest)
	var property = load("res://resources/properties/locked.tres")
	var effect = player.transfer_effect
	player.nearby_object = chest
	player.enter_shift_mode()
	player.update_interaction_prompts()
	var started := Time.get_ticks_msec()
	player.transfer_property()
	assert(player.carried_property == property and not progress.test_chest_locked, "Taking must transfer the property immediately")
	assert(effect.flights.size() == 1 and effect.is_arriving(property), "Taking must launch an icon toward the hotbar")
	assert(not player.carried_icon.visible, "The slot icon must stay hidden until arrival")
	assert(effect.flights[0].icon.texture == property.icon, "The effect must use the property's assigned icon")
	await effect.transfer_finished
	assert(Time.get_ticks_msec() - started < 1200, "The animation must not take four times longer in Shift slow motion")
	assert(effect.flights.is_empty() and player.carried_icon.visible, "Arrival must reveal the hotbar icon and clean up the flight")
	player.transfer_property()
	assert(player.carried_property == null and progress.test_chest_locked, "Placing must update gameplay immediately")
	assert(effect.flights.size() == 1 and not effect.flights[0].taking, "Placing must animate toward the receiving object")
	var flight: Dictionary = effect.flights[0]
	effect._update_flight(0.5, flight)
	var before: Vector2 = flight.last_target
	player.get_node("Camera2D").global_position += Vector2(20, 0)
	player.get_node("Camera2D").force_update_scroll()
	effect._update_flight(0.5, flight)
	assert(flight.last_target != before, "Moving the camera must update the projected destination")
	chest.position.x += 20
	effect._update_flight(0.5, flight)
	assert(flight.last_target == effect._object_center(chest), "The destination must follow world-to-screen projection")
	assert(not player.carried_icon.visible, "An empty hand must not retain its old icon")
	await effect.transfer_finished
	player.transfer_property()
	player.transfer_property()
	assert(effect.flights.size() == 1 and not effect.is_arriving(property), "Rapid reverse transfers must replace the previous flight")
	chest.queue_free()
	await process_frame
	await effect.transfer_finished
	assert(effect.flights.is_empty(), "A removed destination must not leave a stuck animation")
	var target := Node2D.new()
	var component := ShiftableComponent.new()
	component.name = "ShiftableComponent"
	target.add_child(component)
	root.add_child(target)
	var no_icon := ShiftProperty.new()
	no_icon.property_name = "NO_ICON"
	component.add_property(no_icon)
	player.nearby_object = target
	player.transfer_property()
	player.update_interaction_prompts()
	assert(player.carried_property == no_icon and effect.flights.is_empty(), "Properties without icons must still transfer normally")
	player.exit_shift_mode()
	player.queue_free()
	target.queue_free()
	await process_frame
	print("Property transfer animation checks passed")
	quit()
