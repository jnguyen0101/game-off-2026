extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var progress = root.get_node("GameProgress")
	progress.shift_unlocked = true
	progress.carried_property = null
	var player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	var effect = player.transfer_effect
	var rest_x: float = player.property_slot.position.x
	player.transfer_property()
	assert(player.feedback_label.visible and player.feedback_label.text == "Move closer to an object.", "A missing target must explain what to do")
	assert(effect.rejection_tween != null, "Failure must trigger hotbar feedback")
	var target := Node2D.new()
	var component := ShiftableComponent.new()
	component.name = "ShiftableComponent"
	target.add_child(component)
	root.add_child(target)
	player.nearby_object = target
	player.transfer_property()
	assert(player.feedback_label.text == "No properties to take.", "Empty objects must explain the failure")
	assert(player.carried_property == null and component.properties.is_empty() and effect.flights.is_empty(), "Failure must not mutate properties or launch an icon")
	var property = load("res://resources/properties/locked.tres")
	component.add_property(property)
	player.carried_property = property
	player.update_interaction_prompts()
	Engine.time_scale = 0.25
	var started := Time.get_ticks_msec()
	for index in 3:
		player.transfer_property()
	assert(player.feedback_label.text == "Already LOCKED.", "Duplicate properties must give a specific reason")
	assert(player.feedback_label.get_theme_color("font_color") == Color(1.0, 0.55, 0.45), "Failure text must use its warning color")
	assert(player.carried_property == property and component.properties == [property], "Rejection must preserve the carried and target properties")
	await effect.rejection_tween.finished
	assert(Time.get_ticks_msec() - started < 800, "Rejection animation must ignore Shift slow motion")
	assert(is_equal_approx(player.property_slot.position.x, rest_x) and player.property_slot.self_modulate == Color.WHITE, "Repeated failures must not leave the slot displaced or tinted")
	component.remove_property(property)
	player.transfer_property()
	assert(player.carried_property == null and component.has_property(property), "A valid transfer must still work after failure")
	assert(player.feedback_label.get_theme_color("font_color") == Color(1.0, 0.85, 0.45), "Success must restore the normal feedback color")
	assert(effect.rejection_tween == null and is_equal_approx(player.property_slot.position.x, rest_x), "Success must clear rejection feedback immediately")
	player.transfer_property()
	assert(effect.is_arriving(property), "Taking must start the normal transfer animation")
	component.add_property(property)
	var flight_icon = effect.flights[0].icon
	player.transfer_property()
	assert(player.feedback_label.text == "Already LOCKED." and effect.is_arriving(property) and effect.flights[0].icon == flight_icon, "A rejection must not cancel an existing valid flight")
	await effect.transfer_finished
	assert(player.carried_icon.visible, "The valid incoming icon must still arrive after rejection")
	player.dialogue_active = true
	var previous_feedback: String = player.feedback_label.text
	player.transfer_property()
	assert(player.feedback_label.text == previous_feedback, "Dialogue must continue blocking transfers quietly")
	player.dialogue_active = false
	player.exit_shift_mode()
	player.queue_free()
	target.queue_free()
	await process_frame
	print("Property transfer failure feedback checks passed")
	quit()
