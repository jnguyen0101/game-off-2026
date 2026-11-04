extends StaticBody2D


@onready var shiftable: ShiftableComponent = $ShiftableComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	shiftable.properties_changed.connect(_update_locked_state)
	_update_locked_state()


func _update_locked_state() -> void:
	var locked := false
	for property in shiftable.properties:
		if property != null and property.property_name == "LOCKED":
			locked = true
			break

	collision_shape.set_deferred("disabled", not locked)
