extends Node2D


func _ready() -> void:
	var spawn: Marker2D = %GuildSpawn if GameProgress.town_spawn == &"guild" else %HomeSpawn
	$World/Player.global_position = spawn.global_position
	$World/Player.last_direction = Vector2.DOWN
	$World/Player.update_animation(Vector2.ZERO)
	GameProgress.town_spawn = &"home"
	%HomeEntrance.activated.connect(_return_home)
	%GuildEntrance.activated.connect(_enter_guild)
	$TownHUD/Objective.text = "Head to the Thieves' Guild" if GameProgress.resume_read else "Explore the town"


func _return_home() -> void:
	if SceneTransition.is_transitioning:
		return
	GameProgress.returning_home = true
	SceneTransition.change_scene("res://scenes/levels/player_home.tscn")


func _enter_guild() -> void:
	if SceneTransition.is_transitioning:
		return
	SceneTransition.change_scene("res://scenes/levels/guild.tscn")
