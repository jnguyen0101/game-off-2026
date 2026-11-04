extends Node2D

var resume_read: bool = false

@onready var player = %Player
@onready var resume = $Furniture/Resume
@onready var front_door = $Furniture/FrontDoor
@onready var objective: Label = $HomeHUD/Objective


func _ready() -> void:
	resume.dialogue_finished.connect(_on_resume_read)
	front_door.dialogue_finished.connect(_on_front_door_finished)
	_start_morning.call_deferred()


func _start_morning() -> void:
	player.start_dialogue($Furniture/BedThought)


func _on_resume_read() -> void:
	resume_read = true
	objective.text = "Head to the Thieves' Guild"
	front_door.interaction_prompt = "Leave for the guild"
	front_door.lines.assign(["Resume ready. Time to make a very convincing first impression."])


func _on_front_door_finished() -> void:
	if not resume_read:
		return
	# Temporary destination until the town and guild hall have their own maps.
	get_tree().change_scene_to_file.call_deferred("res://scenes/levels/test_level.tscn")
