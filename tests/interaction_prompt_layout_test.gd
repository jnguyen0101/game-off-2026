extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	root.size = Vector2i(320, 180)
	var player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	var prompt = player.interaction_prompt
	for content in ["[E] Read sign", "[E] Open the chest and hold Shift to use Shift Vision | Scroll to choose", "", "[E] Read sign"]:
		prompt.text = content
		prompt.visible = not content.is_empty()
		prompt.custom_minimum_size.x = minf(prompt.get_theme_font("font").get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, prompt.get_theme_font_size("font_size")).x + 12, 236)
		await process_frame
		await process_frame
		if prompt.visible:
			assert(is_equal_approx(prompt.get_global_rect().end.y, 174), "Prompts must be bottom aligned on their first layout pass")
			assert(is_equal_approx(prompt.get_global_rect().get_center().x, 160), "Prompts must be centered on the viewport")
			var first_rect: Rect2 = prompt.get_global_rect()
			await process_frame
			await process_frame
			assert(prompt.get_global_rect() == first_rect, "The prompt must not jump on the next frame")
	print("Interaction prompt layout stability checks passed")
	quit()
