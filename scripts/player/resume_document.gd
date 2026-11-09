extends Control

signal closed

@export var open_duration: float = 0.55
@export var close_duration: float = 0.45

var previous_pause: bool = false
var closing: bool = false
var slide_offset: float = 0.0
var rest_top: float
var rest_bottom: float
var slide_tween: Tween
var hover_tween: Tween

@onready var paper: PanelContainer = $Paper
@onready var close_button: Button = $Paper/Margin/Column/Header/Close

func _ready() -> void:
	hide()
	paper.add_theme_stylebox_override("panel", preload("res://assets/ui/resume_paper_style.tres"))
	rest_top = paper.offset_top
	rest_bottom = paper.offset_bottom
	close_button.pressed.connect(close_document)
	close_button.mouse_entered.connect(_set_close_hover.bind(true))
	close_button.mouse_exited.connect(_set_close_hover.bind(false))

func _set_close_hover(hovered: bool) -> void:
	if hover_tween != null:
		hover_tween.kill()
	hover_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	var color := Color(0.75, 0.75, 0.75, 1.0) if hovered else Color.WHITE
	hover_tween.tween_property(close_button, "self_modulate", color, 0.1)

func _set_slide_offset(value: float) -> void:
	slide_offset = value
	paper.offset_top = rest_top + value
	paper.offset_bottom = rest_bottom + value

func _bottom_offset() -> float:
	return size.y * 0.5 - rest_top + 8.0

func open_document() -> void:
	if visible:
		return
	previous_pause = get_tree().paused
	closing = false
	if hover_tween != null:
		hover_tween.kill()
	close_button.self_modulate = Color.WHITE
	_set_slide_offset(_bottom_offset())
	show()
	get_tree().paused = true
	$PageFlipSound.play()
	close_button.grab_focus()
	slide_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	slide_tween.tween_method(_set_slide_offset, slide_offset, 0.0, open_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func close_document() -> void:
	if not visible or closing:
		return
	closing = true
	$PageFlipSound.play()
	if slide_tween != null:
		slide_tween.kill()
	slide_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	slide_tween.tween_method(_set_slide_offset, slide_offset, _bottom_offset(), close_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await slide_tween.finished
	hide()
	_set_slide_offset(0.0)
	closing = false
	get_tree().paused = previous_pause
	closed.emit()
