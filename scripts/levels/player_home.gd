extends Node2D

var resume_read: bool = false

@onready var player = %Player
@onready var resume = %Resume
@onready var front_door = %FrontDoor
@onready var objective: Label = %Objective
@onready var bed_thought = %BedThought


func _ready() -> void:
	resume.dialogue_finished.connect(_on_resume_read)
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
	objective.text = "Head to the Thieves' Guild"
	front_door.interaction_prompt = "Leave for the guild"
	front_door.lines.assign(["Resume ready. Time to make a very convincing first impression."])


func _on_front_door_finished() -> void:
	if not resume_read:
		return
	GameProgress.town_spawn = &"home"
	SceneTransition.change_scene("res://scenes/levels/town.tscn")
