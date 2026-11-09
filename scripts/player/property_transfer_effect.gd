extends Control

signal state_changed
signal transfer_finished(taking: bool)

@export_range(0.1, 1.0, 0.01) var duration: float = 0.4
@export_range(0.0, 48.0, 1.0) var arc_height: float = 18.0

var flights: Array[Dictionary] = []
var pulse_tween: Tween
var rejection_tween: Tween
@onready var hotbar: Control = $"../PropertySlot"
@onready var hotbar_rest_x: float = hotbar.position.x
@onready var hotbar_rest_color: Color = hotbar.self_modulate


func is_arriving(property: ShiftProperty) -> bool:
	for flight in flights:
		if flight.property == property and flight.taking:
			return true
	return false


func play_transfer(property: ShiftProperty, target: Node, taking: bool) -> void:
	_clear_rejection()
	if property.icon == null or not is_instance_valid(target) or not target is Node2D:
		transfer_finished.emit(taking)
		return
	var start := _object_center(target) if taking else hotbar.get_global_rect().get_center()
	# A rapid second transfer continues from the icon already in flight.
	for previous in flights.duplicate():
		if previous.property == property:
			start = previous.icon.position + previous.icon.size / 2.0
			previous.tween.kill()
			previous.erase("tween")
			previous.icon.queue_free()
			flights.erase(previous)
	var icon := TextureRect.new()
	icon.name = "FlyingProperty"
	icon.texture = property.icon
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(16, 16)
	add_child(icon)
	var flight := {
		"property": property, "target": target, "taking": taking,
		"icon": icon, "start": start, "last_target": _object_center(target)
	}
	flights.append(flight)
	_update_flight(0.0, flight)
	var tween := create_tween().set_ignore_time_scale(true)
	flight.tween = tween
	tween.tween_method(_update_flight.bind(flight), 0.0, 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_finish_transfer.bind(flight))
	state_changed.emit()


func _object_center(target: Node2D) -> Vector2:
	var sprite := target.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		return sprite.get_global_transform_with_canvas() * sprite.get_rect().get_center()
	return target.get_global_transform_with_canvas().origin


func _update_flight(progress: float, flight: Dictionary) -> void:
	if is_instance_valid(flight.target):
		flight.last_target = _object_center(flight.target)
	var end: Vector2 = hotbar.get_global_rect().get_center() if flight.taking else flight.last_target
	var center: Vector2 = flight.start.lerp(end, progress)
	center.y -= sin(progress * PI) * arc_height
	flight.icon.position = (center - flight.icon.size / 2.0).round()
	flight.icon.modulate.a = 1.0 if flight.taking else 1.0 - smoothstep(0.8, 1.0, progress)


func _finish_transfer(flight: Dictionary) -> void:
	flights.erase(flight)
	flight.erase("tween")
	flight.icon.queue_free()
	if flight.taking:
		_pulse_hotbar()
	state_changed.emit()
	transfer_finished.emit(flight.taking)


func _pulse_hotbar() -> void:
	_clear_rejection()
	if pulse_tween != null:
		pulse_tween.kill()
	hotbar.pivot_offset = hotbar.size / 2.0
	hotbar.scale = Vector2.ONE
	pulse_tween = create_tween().set_ignore_time_scale(true)
	pulse_tween.tween_property(hotbar, "scale", Vector2(1.12, 1.12), 0.08)
	pulse_tween.tween_property(hotbar, "scale", Vector2.ONE, 0.12)


func play_rejection() -> void:
	_clear_rejection()
	if pulse_tween != null:
		pulse_tween.kill()
	hotbar.scale = Vector2.ONE
	rejection_tween = create_tween().set_ignore_time_scale(true)
	rejection_tween.tween_property(hotbar, "self_modulate", hotbar_rest_color * Color(1.0, 0.55, 0.45, 1.0), 0.04)
	rejection_tween.parallel().tween_property(hotbar, "position:x", hotbar_rest_x + 2.0, 0.04)
	for offset in [-2.0, 1.0, -1.0, 0.0]:
		rejection_tween.tween_property(hotbar, "position:x", hotbar_rest_x + offset, 0.04)
	rejection_tween.tween_property(hotbar, "self_modulate", hotbar_rest_color, 0.06)


func _clear_rejection() -> void:
	if rejection_tween != null:
		rejection_tween.kill()
		rejection_tween = null
	if is_instance_valid(hotbar):
		hotbar.position.x = hotbar_rest_x
		hotbar.self_modulate = hotbar_rest_color


func _exit_tree() -> void:
	_clear_rejection()
	for flight in flights:
		flight.tween.kill()
		flight.erase("tween")
	flights.clear()
	if is_instance_valid(hotbar):
		hotbar.scale = Vector2.ONE
