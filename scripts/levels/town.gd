extends Node2D


func _ready() -> void:
	var spawn: Marker2D
	match GameProgress.town_spawn:
		&"guild":
			spawn = %GuildSpawn
		&"inn":
			spawn = %InnSpawn
		_:
			spawn = %HomeSpawn
	$World/Player.global_position = spawn.global_position
	$World/Player.last_direction = Vector2.DOWN
	$World/Player.update_animation(Vector2.ZERO)
	_limit_camera_to_map()
	GameProgress.town_spawn = &"home"
	%HomeEntrance.activated.connect(_return_home)
	%GuildEntrance.activated.connect(_enter_guild)
	%InnEntrance.activated.connect(_enter_inn)
	$TownHUD/Objective.text = GameProgress.get_objective()


func _limit_camera_to_map() -> void:
	var ground: TileMapLayer = $Grass
	var cells := ground.get_used_rect()
	var half_tile := Vector2(ground.tile_set.tile_size) * 0.5
	var first_edge := ground.to_global(ground.map_to_local(cells.position) - half_tile)
	var last_edge := ground.to_global(ground.map_to_local(cells.end - Vector2i.ONE) + half_tile)
	var camera: Camera2D = $World/Player/Camera2D
	camera.limit_left = roundi(first_edge.x)
	camera.limit_top = roundi(first_edge.y)
	camera.limit_right = roundi(last_edge.x)
	camera.limit_bottom = roundi(last_edge.y)
	camera.force_update_scroll()


func _return_home() -> void:
	if SceneTransition.is_transitioning:
		return
	GameProgress.returning_home = true
	SceneTransition.change_scene_through_door("res://scenes/levels/player_home.tscn")


func _enter_guild() -> void:
	if SceneTransition.is_transitioning:
		return
	SceneTransition.change_scene_through_door("res://scenes/levels/guild.tscn")


func _enter_inn() -> void:
	if SceneTransition.is_transitioning:
		return
	SceneTransition.change_scene_through_door("res://scenes/levels/inn.tscn")
