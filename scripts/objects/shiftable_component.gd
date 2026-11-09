class_name ShiftableComponent
extends Node

signal properties_changed

@export var properties: Array[ShiftProperty] = []
@export var highlight_sprite: Sprite2D
## White/opaque pixels receive an outline; transparent pixels are excluded.
## Match the source sheet, or use a cropped mask matching its region size.
@export var highlight_mask: Texture2D
@export var highlight_color: Color = Color(1.0, 0.85, 0.45, 0.8)

var highlighted: bool = false
var outline_sprites: Array[Sprite2D] = []


func _ready() -> void:
	properties = properties.duplicate()
	set_process(false)


func set_highlighted(active: bool) -> void:
	if active and outline_sprites.is_empty():
		_create_outline()
	highlighted = active and not outline_sprites.is_empty()
	for sprite in outline_sprites:
		if is_instance_valid(sprite):
			sprite.visible = highlighted
	if highlighted:
		_sync_outline()
	set_process(highlighted)


func _create_outline() -> void:
	if not is_instance_valid(highlight_sprite):
		highlight_sprite = get_parent().get_node_or_null("Sprite2D") as Sprite2D
	if not is_instance_valid(highlight_sprite):
		return
	var outline_material := ShaderMaterial.new()
	outline_material.shader = preload("res://shaders/shift_target_outline.gdshader")
	outline_material.set_shader_parameter("outline_color", highlight_color)
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var sprite := Sprite2D.new()
		sprite.name = "ShiftOutline"
		sprite.position = direction
		sprite.show_behind_parent = true
		sprite.material = outline_material
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		highlight_sprite.add_child(sprite)
		outline_sprites.append(sprite)


func _process(_delta: float) -> void:
	_sync_outline()


func _exit_tree() -> void:
	for sprite in outline_sprites:
		if is_instance_valid(sprite):
			sprite.hide()
			sprite.queue_free()


func _sync_outline() -> void:
	if not is_instance_valid(highlight_sprite):
		highlighted = false
		set_process(false)
		return
	for sprite in outline_sprites:
		sprite.texture = highlight_mask if highlight_mask != null else highlight_sprite.texture
		sprite.centered = highlight_sprite.centered
		sprite.offset = highlight_sprite.offset
		sprite.hframes = highlight_sprite.hframes
		sprite.vframes = highlight_sprite.vframes
		sprite.frame = highlight_sprite.frame
		sprite.flip_h = highlight_sprite.flip_h
		sprite.flip_v = highlight_sprite.flip_v
		var cropped_mask := highlight_mask != null and highlight_sprite.region_enabled and highlight_mask.get_size() == highlight_sprite.region_rect.size
		sprite.region_enabled = highlight_sprite.region_enabled and not cropped_mask
		sprite.region_rect = highlight_sprite.region_rect
		sprite.region_filter_clip_enabled = highlight_sprite.region_filter_clip_enabled


func has_properties() -> bool:
	return not properties.is_empty()


func has_property(property: ShiftProperty) -> bool:
	return property in properties


func remove_property(property: ShiftProperty) -> void:
	if not has_property(property):
		return
	properties.erase(property)
	properties_changed.emit()


func add_property(property: ShiftProperty) -> void:
	if property not in properties:
		properties.append(property)
		properties_changed.emit()
