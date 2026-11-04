extends Area2D

signal dialogue_finished

@export var interaction_prompt: String = "Read"
@export var speaker_name: String = ""
@export_multiline var lines: Array[String] = []


func _ready() -> void:
	add_to_group("dialogue_interactable")
