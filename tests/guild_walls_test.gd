extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var guild = load("res://scenes/levels/guild.tscn").instantiate()
	root.add_child(guild)
	var player = guild.get_node("%Player")
	player.set_physics_process(false)
	await physics_frame
	await physics_frame
	for name in ["Trim", "BackWalls"]:
		var layer: TileMapLayer = guild.get_node(name)
		for cell in layer.get_used_cells():
			assert(layer.get_cell_tile_data(cell).get_collision_polygons_count(0) > 0, "Every painted wall tile needs collision: " + name + str(cell))
	for motion in [Vector2(-180, 0), Vector2(180, 0), Vector2(0, -120)]:
		player.position = Vector2(160, 100)
		assert(player.move_and_collide(motion) != null, "The main room perimeter must block " + str(motion))
	for motion in [Vector2(-100, 0), Vector2(100, 0), Vector2(0, 100)]:
		player.position = Vector2(160, 179)
		assert(player.move_and_collide(motion) != null, "The entrance hall perimeter must block " + str(motion))
	player.position = Vector2(160, 179)
	assert(player.move_and_collide(Vector2(0, -70)) == null, "The entrance hall must connect to the main room")
	player.position = guild.get_node("%Exit").position + Vector2(0, -12)
	await physics_frame
	await physics_frame
	assert(player.get_dialogue_target() == guild.get_node("%Exit"), "The wall must not prevent use of the exit")
	guild.queue_free()
	print("Guild wall checks passed")
	quit()
