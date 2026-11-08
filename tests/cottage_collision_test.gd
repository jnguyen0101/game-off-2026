extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var town = load("res://scenes/levels/town.tscn").instantiate()
	root.add_child(town)
	var player = town.get_node("World/Player")
	player.set_physics_process(false)
	player.set_process(false)
	var names = ["WestCottage", "EastCottage"]
	var art_positions = [Vector2(180, 542), Vector2(817, 559)]
	var sizes = [Vector2(64, 30), Vector2(80, 28)]
	for index in 2:
		var cottage = town.get_node("World/" + names[index])
		var collider = cottage.get_node("CollisionShape2D")
		assert(cottage.get_node("Sprite2D").global_position == art_positions[index], "The cottage artwork must remain in place")
		assert(collider.shape.size == sizes[index], "Each cottage must use its own wall footprint")
		var front_y: float = collider.global_position.y + collider.shape.size.y / 2.0
		assert(is_equal_approx(cottage.global_position.y + 5.0, front_y), "Sorting must align the player feet with the front wall")
		assert(cottage.z_index == player.z_index and cottage.get_parent().y_sort_enabled, "Cottages must share player Y sorting")
		for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var distance: float = (collider.shape.size.x if direction.x != 0 else collider.shape.size.y) / 2.0 + 14.0
			player.global_position = collider.global_position - direction * distance - Vector2(-0.5, 5.5)
			await physics_frame
			await physics_frame
			assert(player.test_move(player.global_transform, direction * distance), "The cottage must block movement from all sides")
	print("Cottage collision and sorting setup checks passed")
	quit()
