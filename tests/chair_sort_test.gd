extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var home = load("res://scenes/levels/player_home.tscn").instantiate()
	root.add_child(home)
	await process_frame
	await physics_frame
	var player = home.player
	player.set_physics_process(false)
	while player.dialogue_active:
		player.dialogue_box.advance()
	var chair: StaticBody2D = home.get_node("Furniture/Chair")
	var desk: StaticBody2D = home.get_node("Furniture/Desk")
	player.global_position = Vector2(chair.global_position.x, 100)
	var collision = player.move_and_collide(Vector2(0, -50))
	assert(collision != null and collision.get_collider() == chair, "The player should stop against the chair")
	assert(player.global_position.y > chair.global_position.y, "The player should sort in front when pressed against the chair")
	assert(chair.global_position.y > desk.global_position.y, "The chair should still sort in front of the desk")
	assert(chair.get_node("Sprite2D").global_position == Vector2(143, 62), "Chair artwork must stay in place")
	assert(chair.get_node("CollisionShape2D").global_position == Vector2(143, 63.5), "Chair collision must stay in place")
	home.queue_free()
	print("Chair sorting checks passed")
	quit()
