extends CharacterBody2D

@export var move_speed: float = 70.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shift_prompt: Label = $ShiftHUD/ShiftPrompt
@onready var carried_label: Label = $ShiftHUD/CarriedProperty
@onready var feedback_label: Label = $ShiftHUD/Feedback
@onready var property_panel: ScrollContainer = $ShiftHUD/PropertyPanel
@onready var property_list: VBoxContainer = $ShiftHUD/PropertyPanel/PropertyList
@onready var shift_filter: ColorRect = $ShiftWorldEffect/Filter
@onready var dialogue_box: PanelContainer = $ShiftHUD/DialogueBox

var dialogue_active: bool = false
var dialogue_source: Area2D = null


func _ready() -> void:
	dialogue_box.finished.connect(_on_dialogue_finished)


func get_dialogue_target() -> Area2D:
	var nearest: Area2D = null
	var best_distance := INF
	for area in $Area2D.get_overlapping_areas():
		if area.is_in_group("dialogue_interactable") and area.can_interact():
			var distance := global_position.distance_squared_to(area.global_position)
			if distance < best_distance:
				nearest = area
				best_distance = distance
	return nearest


func start_dialogue(target: Area2D) -> void:
	if dialogue_active or target.lines.is_empty():
		return
	exit_shift_mode()
	dialogue_source = target
	dialogue_active = true
	velocity = Vector2.ZERO
	update_animation(Vector2.ZERO)
	dialogue_box.start(
		target.speaker_name if target.is_character else "",
		target.lines,
		target.portrait if target.is_character else null
	)
	update_shift_prompts()


func _on_dialogue_finished() -> void:
	dialogue_active = false
	var source := dialogue_source
	dialogue_source = null
	if is_instance_valid(source):
		source.dialogue_finished.emit()
	update_shift_prompts()

var last_direction := Vector2.DOWN
var nearby_object: Node = null
var carried_property: ShiftProperty = null
var shift_mode_active: bool = false
var feedback_until: int = 0
var selection_target: ShiftableComponent = null
var selected_property_index: int = 0
var visible_properties: Array[ShiftProperty] = []


func _input(event: InputEvent) -> void:
	if dialogue_active:
		return
	if not shift_mode_active or carried_property != null:
		return
	if event is InputEventMouseButton and event.pressed:
		var step := 0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			step = -1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			step = 1
		if step != 0:
			var shiftable := get_nearby_shiftable()
			sync_property_selection(shiftable)
			if not visible_properties.is_empty():
				selected_property_index = wrapi(selected_property_index + step, 0, visible_properties.size())
				update_shift_prompts()
				get_viewport().set_input_as_handled()


func sync_property_selection(shiftable: ShiftableComponent) -> void:
	var previous: ShiftProperty = null
	if selected_property_index < visible_properties.size():
		previous = visible_properties[selected_property_index]
	visible_properties.clear()
	if shiftable != null:
		for property in shiftable.properties:
			if property != null:
				visible_properties.append(property)
	if shiftable != selection_target:
		selected_property_index = 0
		selection_target = shiftable
	elif previous in visible_properties:
		selected_property_index = visible_properties.find(previous)
	else:
		selected_property_index = 0


func update_property_list() -> void:
	property_panel.visible = shift_mode_active and not visible_properties.is_empty()

	while property_list.get_child_count() < visible_properties.size():
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		property_list.add_child(row)
	for index in property_list.get_child_count():
		var row := property_list.get_child(index) as Label
		row.visible = index < visible_properties.size()
		if not row.visible:
			continue
		var selected := carried_property == null and index == selected_property_index
		row.text = ("> " if selected else "  ") + visible_properties[index].property_name
		row.modulate = Color(1.0, 0.85, 0.45) if selected else Color.WHITE
		if selected and property_panel.visible:
			property_panel.ensure_control_visible(row)


func _physics_process(_delta: float) -> void:
	if dialogue_active:
		return
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
		exit_shift_mode()
		update_shift_prompts()

func _process(_delta: float) -> void:
	if dialogue_active:
		if Input.is_action_just_pressed("interact"):
			dialogue_box.advance()
		return
	if Input.is_action_just_pressed("shift_mode"):
		enter_shift_mode()

	if Input.is_action_just_released("shift_mode"):
		exit_shift_mode()
		
	if (shift_mode_active and Input.is_action_just_pressed("interact")):
		transfer_property()
	elif not Input.is_action_pressed("shift_mode") and Input.is_action_just_pressed("interact"):
		var target := get_dialogue_target()
		if target != null:
			target.interact(self)
	update_shift_prompts()


func update_shift_prompts() -> void:
	carried_label.text = "Carrying: " + (
		carried_property.property_name if carried_property != null else "Nothing"
	)
	feedback_label.visible = Time.get_ticks_msec() < feedback_until
	var shiftable := get_nearby_shiftable()
	sync_property_selection(shiftable)
	update_property_list()
	shift_prompt.text = ""
	if dialogue_active:
		property_panel.hide()
		return
	var dialogue_target := get_dialogue_target()
	if not shift_mode_active and dialogue_target != null:
		shift_prompt.text = "[E] " + dialogue_target.interaction_prompt
		if shiftable != null:
			shift_prompt.text += " | Hold Shift to use Shift Vision"
		return
	if shiftable == null:
		if shift_mode_active:
			shift_prompt.text = "Move near an object | Release Shift to exit"
		return
	if not shift_mode_active:
		shift_prompt.text = "Hold Shift to use Shift Vision"
	elif carried_property != null:
		if shiftable.has_property(carried_property):
			shift_prompt.text = "%s already has %s" % [nearby_object.name, carried_property.property_name]
		else:
			shift_prompt.text = "[E] Place %s on %s" % [carried_property.property_name, nearby_object.name]
	elif not visible_properties.is_empty():
		shift_prompt.text = "[E] Steal %s from %s" % [visible_properties[selected_property_index].property_name, nearby_object.name]
		if visible_properties.size() > 1:
			shift_prompt.text += " | Scroll to choose"
	else:
		shift_prompt.text = "%s has no property to steal" % nearby_object.name


func show_shift_feedback(message: String) -> void:
	feedback_label.text = message
	feedback_until = Time.get_ticks_msec() + 2000
		
func enter_shift_mode() -> void:
	if dialogue_active or nearby_object == null:
		return

	shift_mode_active = true
	selection_target = null
	Engine.time_scale = 0.25
	shift_filter.set_active(true)

func exit_shift_mode() -> void:
	shift_mode_active = false
	Engine.time_scale = 1.0
	shift_filter.set_active(false)
	
func _exit_tree() -> void:
	Engine.time_scale = 1.0

func get_nearby_shiftable() -> ShiftableComponent:
	if not is_instance_valid(nearby_object):
		return null

	return nearby_object.get_node_or_null("ShiftableComponent")
	
func transfer_property() -> void:
	var shiftable := get_nearby_shiftable()
	
	if shiftable == null:
		return
		
	if carried_property == null:
		sync_property_selection(shiftable)
		if visible_properties.is_empty():
			return
			
		carried_property = visible_properties[selected_property_index]
		shiftable.remove_property(carried_property)
		
		show_shift_feedback("Stole %s" % carried_property.property_name)
		
	else:
		if shiftable.has_property(carried_property):
			return
		shiftable.add_property(carried_property)
		show_shift_feedback("Placed %s on %s" % [carried_property.property_name, nearby_object.name])
		carried_property = null
