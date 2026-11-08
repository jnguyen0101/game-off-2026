extends Node2D

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
	if GameProgress.resume_read:
		_on_resume_read()
	if GameProgress.returning_home:
		player.global_position = %EntranceSpawn.global_position
		player.last_direction = Vector2.UP
		player.update_animation(Vector2.ZERO)
		GameProgress.returning_home = false
	else:
		_start_morning.call_deferred()


func _start_morning() -> void:
	player.start_dialogue(bed_thought)


func _on_resume_read() -> void:
	resume_read = true
	GameProgress.resume_read = true
	resume.hide()
	resume.remove_from_group("dialogue_interactable")
	resume.remove_from_group("interactable")
	resume.get_node("CollisionShape2D").set_deferred("disabled", true)
	objective.text = GameProgress.get_objective()
	front_door.interaction_prompt = "Leave for the guild"
	front_door.lines.assign(["Time to make a very convincing first impression."])
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
	GameProgress.town_spawn = &"home"
	SceneTransition.change_scene("res://scenes/levels/town.tscn")
