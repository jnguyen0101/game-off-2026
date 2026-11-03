class_name ShiftableComponent
extends Node

@export var properties: Array[ShiftProperty] = []


func has_properties() -> bool:
	return not properties.is_empty()


func has_property(property: ShiftProperty) -> bool:
	return property in properties


func remove_property(property: ShiftProperty) -> void:
	properties.erase(property)


func add_property(property: ShiftProperty) -> void:
	if property not in properties:
		properties.append(property)
