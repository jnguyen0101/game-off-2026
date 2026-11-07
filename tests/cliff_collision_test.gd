extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var town = load("res://scenes/levels/town.tscn").instantiate()
	var world := Node2D.new()
	world.y_sort_enabled = true
	root.add_child(world)
	var cliffs: TileMapLayer = town.get_node("World/CliffFaces").duplicate()
	world.add_child(cliffs)
	var player = load("res://scenes/player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	assert(cliffs.y_sort_enabled and cliffs.z_index == player.z_index, "Cliff faces must sort with the player")
	for cell in cliffs.get_used_cells():
		assert(cliffs.get_cell_tile_data(cell).get_collision_polygons_count(0) > 0, "Every painted cliff tile needs collision")
	await physics_frame
	await physics_frame
	player.position = Vector2(88, 80)
	assert(player.move_and_collide(Vector2(0, 80)) != null, "The upper ledge must stop downward movement")
	player.position = Vector2(88, 218)
	assert(player.move_and_collide(Vector2(0, -100)) != null, "The lower cliff face must stop upward movement")
	assert(player.position.y > 164, "A player pressed against the bottom must sort in front of the cliff")
	player.position = Vector2(232, 96)
	assert(player.move_and_collide(Vector2(0, 100)) == null, "The existing stair gap must remain clear")
	town.free()
	world.queue_free()
	print("Cliff collision checks passed")
	quit()
