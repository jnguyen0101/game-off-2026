extends StaticBody2D

signal state_changed

@export var progress_key: StringName = &"test_crate_locked"

const LOCKED = preload("res://resources/properties/locked.tres")

func _ready() -> void:
	if GameProgress.get(progress_key):
		$ShiftableComponent.add_property(LOCKED)
	$ShiftableComponent.properties_changed.connect(_update_state)

func _update_state() -> void:
	GameProgress.set(progress_key, $ShiftableComponent.has_property(LOCKED))
	state_changed.emit()
