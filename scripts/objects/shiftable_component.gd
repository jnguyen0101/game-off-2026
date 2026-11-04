class_name ShiftableComponent
extends Node

signal properties_changed

@export var properties: Array[ShiftProperty] = []


func _ready() -> void:
	properties = properties.duplicate()


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
