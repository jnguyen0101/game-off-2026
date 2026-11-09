extends Node2D

@export var sleep_hold_duration: float = 0.8

var resume_read: bool = false

@onready var player = %Player
@onready var resume = %Resume
@onready var front_door = %FrontDoor
@onready var objective: Label = %Objective
@onready var bed_thought = %BedThought


func _ready() -> void:
	resume.activated.connect(_open_resume)
	%ResumeDocument.closed.connect(_on_resume_closed)
	front_door.dialogue_finished.connect(_on_front_door_finished)
	bed_thought.dialogue_finished.connect(_on_bed_thought_finished)
	if GameProgress.resume_read:
		_on_resume_read()
	_update_home_story()
	if GameProgress.waking_next_morning:
		player.global_position = %MorningSpawn.global_position
		player.last_direction = Vector2.DOWN
		player.update_animation(Vector2.ZERO)
		GameProgress.waking_next_morning = false
		GameProgress.returning_home = false
		_start_next_morning.call_deferred()
	elif GameProgress.returning_home:
		player.global_position = %EntranceSpawn.global_position
		player.last_direction = Vector2.UP
		player.update_animation(Vector2.ZERO)
		GameProgress.returning_home = false
	elif GameProgress.guild_test != GameProgress.GuildTest.COMPLETE:
		_start_morning.call_deferred()


func _start_morning() -> void:
	player.start_dialogue(bed_thought)


func _start_next_morning() -> void:
	player.start_dialogue(%NextMorningThought)


func _update_home_story() -> void:
	objective.text = GameProgress.get_objective()
	if not resume_read and GameProgress.guild_test == GameProgress.GuildTest.NOT_ASSIGNED:
		objective.text = "Read your resume"
	if GameProgress.guild_test == GameProgress.GuildTest.COMPLETE:
		if not GameProgress.guild_overnight_complete:
			bed_thought.interaction_prompt = "Go to sleep"
			bed_thought.lines.assign([
				"They actually let me join. Me.",
				"I should get some sleep before I convince myself it was all a dream."
			])
			front_door.interaction_prompt = "Check door"
			front_door.lines.assign(["Marlow said to get some rest. My first job's tomorrow."])
		else:
			bed_thought.interaction_prompt = "Look at bed"
			bed_thought.lines.assign(["I've only just got up. Marlow's expecting me."])
			front_door.interaction_prompt = "Leave for the guild"
			front_door.lines.assign(["Better not be late on my first day as an actual guild member."])
	elif resume_read:
		bed_thought.lines.assign(["No napping. I've got an interview to survive."])


func _on_bed_thought_finished() -> void:
	if GameProgress.guild_test != GameProgress.GuildTest.COMPLETE or GameProgress.guild_overnight_complete:
		return
	if SceneTransition.is_transitioning:
		return
	GameProgress.guild_overnight_complete = true
	GameProgress.waking_next_morning = true
	GameProgress.returning_home = false
	player.exit_shift_mode()
	SceneTransition.change_scene("res://scenes/levels/player_home.tscn", sleep_hold_duration)


func _on_resume_read() -> void:
	resume_read = true
	GameProgress.resume_read = true
	resume.hide()
	resume.remove_from_group("dialogue_interactable")
	resume.remove_from_group("interactable")
	resume.get_node("CollisionShape2D").set_deferred("disabled", true)
	front_door.interaction_prompt = "Leave for the guild"
	front_door.lines.assign(["Time to make a very convincing first impression."])
	_update_home_story()
	player.update_interaction_prompts()


func _open_resume() -> void:
	if resume_read:
		return
	player.exit_shift_mode()
	player.velocity = Vector2.ZERO
	player.update_animation(Vector2.ZERO)
	%ResumeDocument.open_document()


func _on_resume_closed() -> void:
	if resume_read:
		return
	_on_resume_read()
	player.start_dialogue(%ResumePickupThought)


func _on_front_door_finished() -> void:
	if not resume_read:
		return
	if GameProgress.guild_test == GameProgress.GuildTest.COMPLETE and not GameProgress.guild_overnight_complete:
		return
	GameProgress.town_spawn = &"home"
	SceneTransition.change_scene_through_door("res://scenes/levels/town.tscn")
