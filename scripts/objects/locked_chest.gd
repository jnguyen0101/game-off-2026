extends StaticBody2D

signal opened
signal state_changed

const LOCKED = preload("res://resources/properties/locked.tres")

@onready var shiftable: ShiftableComponent = $ShiftableComponent


func _ready() -> void:
	if not GameProgress.test_chest_locked:
		shiftable.remove_property(LOCKED)
	shiftable.properties_changed.connect(_update_state)
	_update_state()


func _update_state() -> void:
	GameProgress.test_chest_locked = shiftable.has_property(LOCKED)
	if GameProgress.test_chest_locked:
		GameProgress.test_chest_opened = false
		if GameProgress.guild_test == GameProgress.GuildTest.OPENED:
			GameProgress.guild_test = GameProgress.GuildTest.ASSIGNED
	$Sprite2D.frame = 5 if GameProgress.test_chest_opened else 0
	$Interaction.interaction_prompt = "Inspect locked chest" if GameProgress.test_chest_locked else (
		"Look inside chest" if GameProgress.test_chest_opened else "Open chest"
	)
	state_changed.emit()


func interact(player: Node) -> void:
	var message: String
	if GameProgress.guild_test == GameProgress.GuildTest.NOT_ASSIGNED:
		message = "I should speak to the guild head first."
	elif GameProgress.test_chest_locked:
		message = "Locked. Hold Shift to see its properties, then press E to take LOCKED."
	elif GameProgress.test_chest_opened:
		message = "Nothing else in here."
	else:
		GameProgress.test_chest_opened = true
		if GameProgress.guild_test == GameProgress.GuildTest.ASSIGNED:
			GameProgress.guild_test = GameProgress.GuildTest.OPENED
		_update_state()
		opened.emit()
		message = "The lid opens. That should do it."
	$Interaction.lines.assign([message])
	player.start_dialogue($Interaction)
