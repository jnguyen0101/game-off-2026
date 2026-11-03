extends CharacterBody2D

@export var move_speed: float = 70.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction := Vector2.DOWN
var nearby_object: Node = null
var carried_property: ShiftProperty = null
var shift_mode_active: bool = false


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	
	velocity = direction * move_speed
	update_animation(direction)
	move_and_slide()

func update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		last_direction = direction

		if abs(direction.x) >= abs(direction.y):
			animated_sprite.play("walk_right")

			if direction.x > 0:
				animated_sprite.flip_h = false
			else:
				animated_sprite.flip_h = true

		else:
			animated_sprite.flip_h = false

			if direction.y > 0:
				animated_sprite.play("walk_down")
			else:
				animated_sprite.play("walk_up")

	else:
		if abs(last_direction.x) > abs(last_direction.y):
			animated_sprite.play("idle_right")

			if last_direction.x > 0:
				animated_sprite.flip_h = false
			else:
				animated_sprite.flip_h = true

		else:
			animated_sprite.flip_h = false

			if last_direction.y > 0:
				animated_sprite.play("idle_down")
			else:
				animated_sprite.play("idle_up")


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("shiftable"):
		nearby_object = area.get_parent()


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.get_parent() == nearby_object:
		nearby_object = null

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("shift_mode"):
		enter_shift_mode()

	if Input.is_action_just_released("shift_mode"):
		exit_shift_mode()
		
	if (shift_mode_active and Input.is_action_just_pressed("interact")):
		transfer_property()
		
func enter_shift_mode() -> void:
	if nearby_object == null:
		return

	shift_mode_active = true
	Engine.time_scale = 0.25

func exit_shift_mode() -> void:
	shift_mode_active = false
	Engine.time_scale = 1.0
	
func _exit_tree() -> void:
	Engine.time_scale = 1.0

func get_nearby_shiftable() -> ShiftableComponent:
	if nearby_object == null:
		return null

	return nearby_object.get_node_or_null("ShiftableComponent")
	
func transfer_property() -> void:
	var shiftable := get_nearby_shiftable()
	
	if shiftable == null:
		return
		
	if carried_property == null:
		if not shiftable.has_properties():
			return
			
		carried_property = shiftable.properties[0]
		shiftable.remove_property(carried_property)
		
		print("Stole: ", carried_property.property_name)
		
	else:
		shiftable.add_property(carried_property)
		print("Placed: ", carried_property.property_name)
		carried_property = null
