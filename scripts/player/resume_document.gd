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
var close_style: StyleBoxFlat

@onready var paper: PanelContainer = $Paper
@onready var close_button: Button = $Paper/Margin/Column/Header/Close

func _ready() -> void:
	hide()
	rest_top = paper.offset_top
	rest_bottom = paper.offset_bottom
	close_button.pressed.connect(close_document)
	close_style = close_button.get_theme_stylebox("normal").duplicate()
	for state in ["normal", "hover", "pressed"]:
		close_button.add_theme_stylebox_override(state, close_style)
	close_button.mouse_entered.connect(_set_close_hover.bind(true))
	close_button.mouse_exited.connect(_set_close_hover.bind(false))

func _set_close_hover(hovered: bool) -> void:
	if hover_tween != null:
		hover_tween.kill()
	hover_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	var color := Color(0.12, 0.08, 0.05, 0.55) if hovered else Color(0.2, 0.14, 0.1, 0.25)
	hover_tween.tween_property(close_style, "bg_color", color, 0.1)

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
	close_style.bg_color = Color(0.2, 0.14, 0.1, 0.25)
	_set_slide_offset(_bottom_offset())
	show()
	get_tree().paused = true
	close_button.grab_focus()
	slide_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	slide_tween.tween_method(_set_slide_offset, slide_offset, 0.0, open_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func close_document() -> void:
	if not visible or closing:
		return
	closing = true
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
