extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	var target := Node2D.new()
	var shiftable := ShiftableComponent.new()
	shiftable.name = "ShiftableComponent"
	target.add_child(shiftable)
	root.add_child(target)
	var first := ShiftProperty.new()
	first.property_name = "FIRST"
	var second := ShiftProperty.new()
	second.property_name = "SECOND"
	shiftable.add_property(first)
	shiftable.add_property(second)
	player.nearby_object = target
	player.enter_shift_mode()
	player.update_shift_prompts()

	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	root.push_input(wheel)
	assert(player.selected_property_index == 1, "Scrolling up should wrap to the last property")
	player.transfer_property()
	assert(player.carried_property == second, "E must take the highlighted property")
	assert(shiftable.properties == [first], "Other properties must remain on the object")
	root.push_input(wheel)
	assert(player.carried_property == second, "Scrolling must not change the carried property")
	player.transfer_property()
	assert(player.carried_property == null, "Placing must empty the player's hand")
	assert(shiftable.has_property(second), "Placing must restore the property")

	shiftable.remove_property(first)
	shiftable.remove_property(second)
	player.update_shift_prompts()
	assert(not player.property_panel.visible, "Empty objects must hide the selection list")
	player.transfer_property()
	assert(player.carried_property == null, "An empty object must not produce a property")
	var detection_area := Area2D.new()
	target.add_child(detection_area)
	Input.action_press("shift_mode")
	player._on_area_2d_area_exited(detection_area)
	assert(Input.is_action_pressed("shift_mode"), "Shift must still be held during the exit check")
	assert(not player.shift_mode_active, "Leaving the target area must deactivate Shift Vision")
	assert(player.nearby_object == null, "Leaving the target area must clear the target")
	assert(not player.property_panel.visible, "Leaving the target area must hide the property list")
	assert(Engine.time_scale == 1.0, "Leaving Shift Vision must restore normal time")
	Input.action_release("shift_mode")
	player.queue_free()
	target.queue_free()
	print("Shift selection checks passed")
	quit()
