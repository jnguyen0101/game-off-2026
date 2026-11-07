extends Node2D


func _ready() -> void:
	%Player.global_position = %EntranceSpawn.global_position
	%Player.last_direction = Vector2.UP
	%Player.update_animation(Vector2.ZERO)
	%Exit.activated.connect(_leave_guild)


func _leave_guild() -> void:
	if SceneTransition.is_transitioning:
		return
	GameProgress.town_spawn = &"guild"
	SceneTransition.change_scene("res://scenes/levels/town.tscn")
