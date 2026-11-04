extends ColorRect

@export_range(0.01, 1.0) var fade_duration: float = 0.1

var fade_tween: Tween


func _ready() -> void:
	material = material.duplicate()
	material.set_shader_parameter("strength", 0.0)
	hide()


func set_active(active: bool) -> void:
	if fade_tween != null:
		fade_tween.kill()
	show()
	fade_tween = create_tween().set_ignore_time_scale(true)
	fade_tween.tween_property(material, "shader_parameter/strength", 1.0 if active else 0.0, fade_duration)
	if not active:
		fade_tween.tween_callback(hide)
