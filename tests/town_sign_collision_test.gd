extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var town = load("res://scenes/levels/town.tscn").instantiate()
	root.add_child(town)
	var player = town.get_node("World/Player")
	player.set_physics_process(false)
	player.set_process(false)
	for sign_name in ["InnSign", "GuildSign"]:
		var sign = town.get_node("World/" + sign_name)
		var collider = sign.get_node("StaticBody2D/CollisionShape2D2")
		player.global_position = collider.global_position + Vector2(0, 16)
		await physics_frame
		await physics_frame
		assert(player.test_move(player.global_transform, Vector2(0, -24)), "The player must collide with " + sign_name)
		assert(player.get_dialogue_target() == sign, "The sign must remain readable from outside its collider")
		sign.interact(player)
		assert(player.dialogue_active, "Reading must still open dialogue")
		while player.dialogue_active:
			player.dialogue_box.advance()
	print("Town sign collision and interaction checks passed")
	quit()
