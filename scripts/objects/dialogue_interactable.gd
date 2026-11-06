extends Area2D

signal dialogue_finished

@export var interaction_prompt: String = "Read"
@export var is_character: bool = false
@export var speaker_name: String = ""
@export var portrait: Texture2D
@export_multiline var lines: Array[String] = []


func _ready() -> void:
	add_to_group("dialogue_interactable")


func can_interact() -> bool:
	return not lines.is_empty()


func interact(player: Node) -> void:
	player.start_dialogue(self)
