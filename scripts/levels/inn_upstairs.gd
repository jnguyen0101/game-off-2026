extends Node2D


func _ready() -> void:
	%Player.last_direction = Vector2.DOWN
	%Player.update_animation(Vector2.ZERO)
	%Objective.text = GameProgress.get_objective()
	%StairsDown.activated.connect(_go_downstairs)


func _go_downstairs() -> void:
	if SceneTransition.is_transitioning:
		return
	GameProgress.returning_from_inn_upstairs = true
	SceneTransition.change_scene_on_stairs("res://scenes/levels/inn.tscn")
