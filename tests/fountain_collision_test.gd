extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var town = load("res://scenes/levels/town.tscn").instantiate()
	root.add_child(town)
	var player = town.get_node("World/Player")
	player.set_physics_process(false)
	var fountain = town.get_node("World/MarketFountain")
	await physics_frame
	await physics_frame
	for direction in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
		player.global_position = Vector2(504, 494) + direction * 48
		var collision = player.move_and_collide(-direction * 70)
		assert(collision != null and collision.get_collider() == fountain, "The fountain must block movement from " + str(direction))
		if direction == Vector2.DOWN:
			assert(player.global_position.y > fountain.global_position.y, "The player must draw in front when touching the fountain's bottom")
	town.queue_free()
	print("Fountain collision checks passed")
	quit()
