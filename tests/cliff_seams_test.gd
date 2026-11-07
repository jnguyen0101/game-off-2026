extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var town = load("res://scenes/levels/town.tscn").instantiate()
	var layers: Array[TileMapLayer] = []
	for path in ["UpperGround", "World/CliffFaces"]:
		var layer: TileMapLayer = town.get_node(path).duplicate()
		root.add_child(layer)
		layers.append(layer)
	var player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	await physics_frame
	await physics_frame
	# This edge crosses upper-ground strips, the cliff lip, and the wall face.
	var contact_x := -INF
	for y in range(88, 145, 4):
		player.position = Vector2(330, y)
		assert(player.move_and_collide(Vector2(-90, 0)) != null, "The cliff side must be solid at y=" + str(y))
		if contact_x == -INF:
			contact_x = player.position.x
		assert(absf(player.position.x - contact_x) < 0.05, "Side-edge collision should not bump at seams")
	# Ground fill and decorative shadow strips should stay nonblocking.
	assert(layers[0].get_cell_tile_data(Vector2i(5, 5)).get_collision_polygons_count(0) == 0, "Plain grass must remain walkable")
	assert(layers[1].get_cell_tile_data(Vector2i(17, 10)).get_collision_polygons_count(0) == 0, "The lower shadow trim must remain nonblocking")
	for layer in layers:
		layer.queue_free()
	town.free()
	player.queue_free()
	print("Cliff seam checks passed")
	quit()
