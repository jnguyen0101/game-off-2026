extends "res://scripts/objects/dialogue_interactable.gd"

@export var starts_on: bool = false
var is_on: bool = false


func _ready() -> void:
	super._ready()
	is_on = starts_on
	update_lamp()


func can_interact() -> bool:
	return true


func interact(_player: Node) -> void:
	is_on = not is_on
	update_lamp()
	$StringSound.play()


func update_lamp() -> void:
	interaction_prompt = "Turn off lamp" if is_on else "Turn on lamp"
	$Glow.visible = is_on
	$Light.visible = is_on
	$"../Sprite2D".modulate = Color(1.0, 0.9, 0.65) if is_on else Color.WHITE
