extends Node2D

func _ready() -> void:
	%Player.global_position = %EntranceSpawn.global_position
	%Player.last_direction = Vector2.UP
	if GameProgress.returning_from_inn_upstairs:
		GameProgress.returning_from_inn_upstairs = false
		%Player.global_position = %StairSpawn.global_position
		%Player.last_direction = Vector2.DOWN
	%Player.update_animation(Vector2.ZERO)
	%Exit.activated.connect(_leave_inn)
	%StairsUp.activated.connect(_go_upstairs)
	$World/Innkeeper/Dialogue.dialogue_finished.connect(_on_innkeeper_finished)
	_update_innkeeper()


func _update_innkeeper() -> void:
	%Objective.text = GameProgress.get_objective()
	var innkeeper = $World/Innkeeper/Dialogue
	match GameProgress.first_job:
		GameProgress.FirstJob.TALK_TO_INNKEEPER:
			innkeeper.lines.assign([
				"Marlow sent you? I was starting to think he'd forgotten.",
				"Brass signet, little swallow engraved on the face. It was my father's.",
				"The palace collector took it when I couldn't cover the levy.",
				"I paid three days ago. He kept the ring anyway.",
				"They log seized goods in the collection office, by the palace's delivery entrance.",
				"Please bring it back. It's worth more to me than it is to them."
			])
		GameProgress.FirstJob.CLIENT_BRIEFED:
			innkeeper.lines.assign(["Brass, with a swallow engraved on it. The collection office should still have it."])
		_:
			innkeeper.lines.assign(["Welcome to the Wayward Pick. Looking for a room, or just somewhere to rest your feet?"])


func _on_innkeeper_finished() -> void:
	if GameProgress.first_job == GameProgress.FirstJob.TALK_TO_INNKEEPER:
		GameProgress.first_job = GameProgress.FirstJob.CLIENT_BRIEFED
	_update_innkeeper()


func _leave_inn() -> void:
	if SceneTransition.is_transitioning:
		return
	GameProgress.town_spawn = &"inn"
	SceneTransition.change_scene_through_door("res://scenes/levels/town.tscn")


func _go_upstairs() -> void:
	SceneTransition.change_scene_on_stairs("res://scenes/levels/inn_upstairs.tscn")
