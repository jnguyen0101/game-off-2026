extends "res://scripts/objects/dialogue_interactable.gd"

@export var device_name: String = "radio"
@export_range(0.0, 1.0, 0.05) var music_start_delay: float = 0.5

var pending_start: Tween

@onready var music: AudioStreamPlayer2D = $Music
@onready var button_click: AudioStreamPlayer2D = $Music/ButtonClick


func _ready() -> void:
	super._ready()
	music.finished.connect(_update_prompt)
	_update_prompt()


func can_interact() -> bool:
	return true


func interact(_player: Node) -> void:
	button_click.play()
	if pending_start != null:
		pending_start.kill()
		pending_start = null
	elif music.playing:
		music.stop()
	else:
		pending_start = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
		pending_start.tween_interval(music_start_delay)
		pending_start.tween_callback(_start_music)
	_update_prompt()


func _start_music() -> void:
	pending_start = null
	music.play()
	_update_prompt()


func _update_prompt() -> void:
	interaction_prompt = ("Turn off %s" if music.playing or pending_start != null else "Turn on %s") % device_name
