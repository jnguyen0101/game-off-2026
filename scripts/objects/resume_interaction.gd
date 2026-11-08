extends Area2D

signal activated

@export var interaction_prompt: String = "Read resume"

func _ready() -> void:
	add_to_group("interactable")

func can_interact() -> bool:
	return not GameProgress.resume_read

func interact(_player: Node) -> void:
	if can_interact():
		activated.emit()
