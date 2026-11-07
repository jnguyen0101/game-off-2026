extends "res://scripts/objects/dialogue_interactable.gd"

signal activated


func can_interact() -> bool:
	return true


func interact(_player: Node) -> void:
	activated.emit()
