extends "res://scripts/objects/dialogue_interactable.gd"


func can_interact() -> bool:
	return true


func interact(player: Node) -> void:
	get_parent().interact(player)
