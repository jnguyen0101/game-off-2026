extends CharacterBody2D

@export var move_speed: float = 70.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction := Vector2.DOWN


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
