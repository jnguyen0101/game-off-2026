extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var town = load("res://scenes/levels/town.tscn").instantiate()
	root.add_child(town)
	var player = town.get_node("World/Player")
	player.set_physics_process(false)
	await physics_frame
	await physics_frame
	var space = town.get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 3)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.exclude = [player.get_rid()]
	query.collision_mask = 1
	var blocked := {}
	for y in range(48):
		for x in range(60):
			query.transform = Transform2D(0.0, Vector2(x * 16 + 8, y * 16 + 13.5))
			if not space.intersect_shape(query, 1).is_empty():
				blocked[Vector2i(x, y)] = true
	var start := Vector2i(player.position / 16)
	assert(not blocked.has(start), "Home spawn must be clear")
	var queue: Array[Vector2i] = [start]
	var visited := {start: true}
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + direction
			if next.x < 0 or next.x >= 60 or next.y < 0 or next.y >= 48:
				continue
			if not blocked.has(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)
	for destination in [Vector2(800, 416), Vector2(240, 416), Vector2(512, 464), Vector2(512, 288), Vector2(512, 744)]:
		var reachable := false
		for cell in visited:
			if (Vector2(cell) * 16 + Vector2(8, 8)).distance_to(destination) < 24:
				reachable = true
				break
		assert(reachable, "A town landmark is blocked: " + str(destination))
	town.queue_free()
	print("Town route checks passed")
	quit()
