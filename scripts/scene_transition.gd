extends CanvasLayer

signal transition_finished(error: int)

@export var fade_duration: float = 0.22
@export var black_hold_duration: float = 0.08

var is_transitioning: bool = false
var overlay: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	overlay.hide()


func _input(_event: InputEvent) -> void:
	if is_transitioning:
		get_viewport().set_input_as_handled()


func change_scene(path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	var tree := get_tree()
	var was_paused := tree.paused
	tree.paused = true
	overlay.show()
	await _fade_to(1.0)
	var error := tree.change_scene_to_file(path)
	if error == OK:
		# Destination _ready and spawn placement finish behind the black overlay.
		await tree.process_frame
		await tree.process_frame
		await tree.create_timer(black_hold_duration, true, false, true).timeout
	else:
		push_error("Could not change scene to %s (error %d)" % [path, error])
	await _fade_to(0.0)
	overlay.hide()
	tree.paused = was_paused
	is_transitioning = false
	transition_finished.emit(error)


func _fade_to(alpha: float) -> void:
	var tween := create_tween().set_ignore_time_scale(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "color:a", alpha, fade_duration)
	await tween.finished
