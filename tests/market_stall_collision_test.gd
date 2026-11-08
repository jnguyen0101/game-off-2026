extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var town = load("res://scenes/levels/town.tscn").instantiate()
	root.add_child(town)
	var player = town.get_node("World/Player")
	player.set_physics_process(false)
	player.set_process(false)
	assert(town.get_node("World").y_sort_enabled, "Stalls and player must share a Y-sorted parent")
	var artwork_positions = [Vector2(436, 416), Vector2(614, 430), Vector2(432, 548), Vector2(596, 558)]
	for index in 4:
		var stall = town.get_node("World/MarketStall%d" % (index + 1))
		var sprite = stall.get_node("Sprite2D")
		var collider = stall.get_node("CollisionShape2D")
		assert(sprite.global_position == artwork_positions[index], "Stall artwork must remain in place")
		assert(stall.z_index == player.z_index and not stall.y_sort_enabled, "Each stall must sort as one object alongside the player")
		assert(stall.global_position.y > collider.global_position.y, "The sorting point must sit toward the front of the counter")
		for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			player.global_position = collider.global_position - direction * 32.0 - Vector2(-0.5, 5.5)
			await physics_frame
			await physics_frame
			assert(player.test_move(player.global_transform, direction * 32.0), "The counter must block the player on every side")
		player.global_position = collider.global_position + Vector2(0, 20)
		await physics_frame
		await physics_frame
		assert(not player.test_move(player.global_transform, Vector2(12, 0)), "The player must be able to walk along the front")
	print("Market stall collision and sorting setup checks passed")
	quit()
