extends AudioStreamPlayer

@export var grass: AudioStream
@export var dirt: AudioStream
@export var wood: AudioStream
@export var stone: AudioStream

func play_step(feet: Vector2) -> void:
	var surface := _surface_at(feet)
	match surface:
		&"grass": stream = grass
		&"dirt": stream = dirt
		&"wood": stream = wood
		&"stone": stream = stone
		_: return
	play()


func _surface_at(feet: Vector2) -> StringName:
	var surface: StringName = &""
	var top_layer: TileMapLayer
	for node in get_tree().get_nodes_in_group(&"footstep_surface"):
		var layer := node as TileMapLayer
		if layer == null or not layer.enabled or not layer.is_visible_in_tree():
			continue
		var cell := layer.local_to_map(layer.to_local(feet))
		if layer.get_cell_source_id(cell) < 0:
			continue
		# Higher layers cover lower ones. Later layers win ties, as with the terrace.
		if top_layer == null or layer.z_index >= top_layer.z_index:
			top_layer = layer
			surface = layer.get_meta(&"footstep_surface")
	return surface
