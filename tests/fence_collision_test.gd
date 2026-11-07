extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var town = load("res://scenes/levels/town.tscn").instantiate()
	var fences: TileMapLayer = town.get_node("World/Fences").duplicate()
	root.add_child(fences)
	var player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	await physics_frame
	await physics_frame
	# Check collision at tile centers and seams along the existing lower fence.
	var contact_y := -INF
	for x in range(56, 193, 8):
		player.position = Vector2(x, 150)
		assert(player.move_and_collide(Vector2(0, -80)) != null, "Fence collision must be continuous at x=" + str(x))
		if contact_y == -INF:
			contact_y = player.position.y
		assert(absf(player.position.y - contact_y) < 0.05, "Fence tiles must stop the player at the same height")
	# All touching painted segments must share collision along their tile edge.
	for cell in fences.get_used_cells():
		for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + direction
			if fences.get_cell_source_id(neighbor) == -1:
				continue
			var a := fences.get_cell_tile_data(cell).get_collision_polygon_points(0, 0)
			var b := fences.get_cell_tile_data(neighbor).get_collision_polygon_points(0, 0)
			var connected := false
			for sample in range(-8, 9):
				var p := Vector2(8, sample) if direction == Vector2i.RIGHT else Vector2(sample, 8)
				if Geometry2D.is_point_in_polygon(p, a) and Geometry2D.is_point_in_polygon(p - Vector2(direction) * 16, b):
					connected = true
					break
			assert(connected, "Connected fence tiles must share a solid seam at " + str(cell))
	town.free()
	fences.queue_free()
	player.queue_free()
	print("Fence collision checks passed")
	quit()
