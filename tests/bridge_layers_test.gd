extends SceneTree


func _initialize() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var town = load("res://scenes/levels/town.tscn").instantiate()
	root.add_child(town)
	var deck: TileMapLayer = town.get_node("World/BridgeDeck")
	var rails: TileMapLayer = town.get_node("World/BridgeRailings")
	assert(deck.z_index < town.get_node("World/Player").z_index, "The deck must render below the player")
	assert(rails.y_sort_enabled and rails.z_index == town.get_node("World/Player").z_index, "Railings must sort with the player")
	assert(deck.get_used_cells().size() == 10 and rails.get_used_cells().size() == 10, "All original bridge tiles must be preserved")
	for cell in deck.get_used_cells():
		var tile := deck.get_cell_tile_data(cell)
		assert(tile.get_collision_polygons_count(0) == 0, "Walking surface must remain clear")
	for cell in rails.get_used_cells():
		var tile := rails.get_cell_tile_data(cell)
		assert(tile.get_collision_polygons_count(0) > 0, "Railings must preserve their collision")
		var point := rails.map_to_local(cell).y + tile.y_sort_origin
		assert(point > 0, "Railings must sort at their map position")
	town.queue_free()
	print("Bridge layer checks passed")
	quit()
