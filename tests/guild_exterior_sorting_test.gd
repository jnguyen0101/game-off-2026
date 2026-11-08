extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var town = load("res://scenes/levels/town.tscn").instantiate()
	root.add_child(town)
	var guild = town.get_node("World/Guild")
	assert(guild.y_sort_enabled and guild.get_parent().y_sort_enabled, "Guild sections must join world sorting")
	var names = ["WestWing", "Sprite2D", "EastWing"]
	for index in 3:
		var part = guild.get_node(names[index])
		var art_top_left: Vector2 = part.global_position + part.offset - part.region_rect.size / 2.0
		assert(art_top_left == Vector2(694 + 64 * index, 288), "The three sections must preserve the original artwork without gaps")
		assert(part.region_rect.position == Vector2(64 * index, 0), "Each section must show the correct texture region")
	assert(guild.get_node("WestWing").global_position.y == 382 and guild.get_node("EastWing").global_position.y == 382, "Wings must sort at their own front edge")
	assert(guild.get_node("Sprite2D").global_position.y == 396, "The entrance must retain its lower sorting edge")
	assert(town.get_node("%GuildEntrance").global_position == Vector2(782, 390), "The entrance must remain in place")
	assert(town.get_node("%GuildSpawn").global_position == Vector2(782, 403), "The return spawn must remain in place")
	assert(guild.get_node("CollisionShape2D").position == Vector2(0, -22.875), "Existing building colliders must remain in place")
	print("Guild exterior sorting setup checks passed")
	quit()
