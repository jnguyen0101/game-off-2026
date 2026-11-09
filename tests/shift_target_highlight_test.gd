extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var progress = root.get_node("GameProgress")
	progress.guild_test = 1
	progress.shift_unlocked = false
	progress.shift_discovery_seen = true
	progress.test_chest_locked = true
	progress.test_chest_opened = false
	progress.test_crate_locked = false
	progress.test_keg_locked = false
	var guild = load("res://scenes/levels/guild.tscn").instantiate()
	root.add_child(guild)
	var player = guild.get_node("%Player")
	player.set_process(false)
	player.set_physics_process(false)
	var chest = guild.get_node("%Wooden Chest")
	var crate = guild.get_node("%Wooden Crate")
	var keg = guild.get_node("%Wooden Keg")
	var chest_component = chest.get_node("ShiftableComponent")
	var source = chest.get_node("Sprite2D")
	var old_material = source.material
	var old_position: Vector2 = source.position
	player.nearby_object = chest
	player.enter_shift_mode()
	assert(not chest_component.highlighted, "Highlighting must respect the Shift unlock")
	progress.shift_unlocked = true
	player.enter_shift_mode()
	assert(chest_component.highlighted and chest_component.outline_sprites.size() == 4, "The selected chest must gain a one-pixel outline")
	assert(source.material == old_material and source.position == old_position, "Highlighting must preserve the original sprite")
	for outline in chest_component.outline_sprites:
		assert(outline.visible and outline.show_behind_parent and outline.position.length() == 1, "Outline copies must sit one pixel behind the sprite")
		assert(outline.texture == chest_component.highlight_mask and outline.frame == source.frame, "The outline must match the sprite sheet frame")
	source.frame = 5
	chest_component._process(0)
	for outline in chest_component.outline_sprites:
		assert(outline.frame == 5, "The outline must follow the chest opening frame")
	for target in [crate, keg]:
		player.nearby_object = target
		player.carried_property = load("res://resources/properties/locked.tres")
		player.update_interaction_prompts()
		assert(target.get_node("ShiftableComponent").highlighted and not chest_component.highlighted, "Only the current destination must be highlighted")
		if target == keg:
			assert(not crate.get_node("ShiftableComponent").highlighted, "The previous target must lose its highlight")
	for target in [chest, crate, keg]:
		var component = target.get_node("ShiftableComponent")
		var visual = target.get_node("Sprite2D")
		var image: Image = visual.texture.get_image()
		if visual.region_enabled:
			image = image.get_region(visual.region_rect)
		var mask: Image = component.highlight_mask.get_image()
		assert(mask.get_size() == image.get_size(), "Masks must match their source sheet or cropped region")
		var excluded_shadow_pixels := 0
		for y in image.get_height():
			for x in image.get_width():
				var source_alpha: float = image.get_pixel(x, y).a
				if source_alpha > 0 and source_alpha < 0.99:
					assert(mask.get_pixel(x, y).a == 0, "The shadow must be excluded from the outline")
					excluded_shadow_pixels += 1
				elif source_alpha == 1:
					assert(mask.get_pixel(x, y).a == 1, "Solid object pixels must remain in the mask")
		assert(excluded_shadow_pixels > 0, "Each mask must exclude its object's shadow")
	assert(not keg.get_node("ShiftableComponent").outline_sprites[0].region_enabled, "The cropped keg mask must not inherit the source atlas region")
	player.exit_shift_mode()
	assert(not keg.get_node("ShiftableComponent").highlighted, "Releasing Shift must clear the highlight immediately")
	player.enter_shift_mode()
	player.start_dialogue(guild.get_node("%GuildHead"))
	assert(not keg.get_node("ShiftableComponent").highlighted, "Dialogue must clear the highlight")
	while player.dialogue_active:
		player.dialogue_box.advance()
	player.nearby_object = crate
	player.enter_shift_mode()
	player._on_area_2d_area_exited(crate.get_node("ShiftArea"))
	assert(not crate.get_node("ShiftableComponent").highlighted and Engine.time_scale == 1, "Leaving range must clear highlighting and slow motion")
	player.nearby_object = keg
	player.enter_shift_mode()
	keg.queue_free()
	await process_frame
	player.update_interaction_prompts()
	assert(not is_instance_valid(player.highlighted_target), "Removing a highlighted object must clear the reference safely")
	player.exit_shift_mode()
	guild.queue_free()
	await process_frame
	print("Shift target highlighting checks passed")
	quit()
