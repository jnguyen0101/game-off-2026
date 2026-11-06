extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var home = load("res://scenes/levels/player_home.tscn").instantiate()
	var player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	for path in ["Furniture/Kitchen/Fridge", "Furniture/Kitchen/Plant", "Furniture/Bedroom/Plant"]:
		var body = home.get_node(path).duplicate()
		body.position = Vector2(100, 100)
		root.add_child(body)
		player.global_position = Vector2(100, 150)
		await physics_frame
		await physics_frame
		var collision = player.move_and_collide(Vector2(0, -80))
		assert(collision != null and collision.get_collider() == body, "The object must physically stop the player: " + path)
		await physics_frame
		await physics_frame
		var interaction = body.get_node("Interaction")
		assert(player.get_dialogue_target() == interaction, "Dialogue must be reachable at the collision edge: " + path)
		interaction.interact(player)
		assert(player.dialogue_active, "E interaction must still open dialogue: " + path)
		while player.dialogue_active:
			player.dialogue_box.advance()
		body.free()
	home.free()
	player.queue_free()
	print("Solid interaction checks passed")
	quit()
