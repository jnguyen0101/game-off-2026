extends Node2D


func _ready() -> void:
	%Player.global_position = %EntranceSpawn.global_position
	%Player.last_direction = Vector2.UP
	%Player.update_animation(Vector2.ZERO)
	%Exit.activated.connect(_leave_guild)
	%GuildHead.dialogue_finished.connect(_on_guild_head_finished)
	get_node("%Wooden Chest").state_changed.connect(_update_quest)
	get_node("%Wooden Crate").state_changed.connect(_update_quest)
	get_node("%Wooden Keg").state_changed.connect(_update_quest)
	_update_quest()


func _on_guild_head_finished() -> void:
	match GameProgress.guild_test:
		GameProgress.GuildTest.NOT_ASSIGNED:
			GameProgress.guild_test = GameProgress.GuildTest.ASSIGNED
			GameProgress.shift_unlocked = true
		GameProgress.GuildTest.OPENED:
			if GameProgress.test_chest_opened and not GameProgress.test_chest_locked and GameProgress.has_placed_test_lock():
				GameProgress.guild_test = GameProgress.GuildTest.COMPLETE
	_update_quest()


func _update_quest() -> void:
	%Objective.text = GameProgress.get_objective(true)
	%GuildHead.speaker_name = "Marlow"
	%GuildHead.interaction_prompt = "Talk to Marlow"
	%GuildHead.page_speakers.clear()
	if GameProgress.guild_test == GameProgress.GuildTest.COMPLETE:
		$World/SeasonedThief/Dialogue.speaker_name = "Rook"
		$World/SeasonedThief/Dialogue.interaction_prompt = "Talk to Rook"
		$World/SeasonedThief/Dialogue.lines.assign([
			"Don’t mistake his low standards for talent."
		])
	match GameProgress.guild_test:
		GameProgress.GuildTest.NOT_ASSIGNED:
			%GuildHead.lines.assign([
				"Marlow. I run the guild. You must be the applicant.",
				"Let’s see what you’ve brought me.",
				"No experience. No lockpicking. You've written 'enthusiastic' three times.",
				"Well, everyone starts somewhere. I'll give you one chance.",
				"See that chest? Open it. No key, and leave the chest in one piece.",
				"Consider this your interview. Let's see what you can do."
			])
		GameProgress.GuildTest.ASSIGNED:
			%GuildHead.lines.assign(["Open the locked chest. I'll be right here."])
		GameProgress.GuildTest.OPENED:
			if not GameProgress.has_placed_test_lock():
				%GuildHead.lines.assign(["Leave the chest open when you're done. I'll take a look in a moment."])
				return
			%GuildHead.lines.assign([
				"Open already? That was quick.",
				"The chest's intact. The lock wasn't broken. How did you open it?",
				"Never mind. You passed. Welcome to the Thieves' Guild.",
				"He let you in? Must be getting desperate.",
				"That's enough, Rook.",
				"What? I'm making him feel welcome."
			])
			%GuildHead.page_speakers.assign(["Marlow", "Marlow", "Marlow", "Seasoned Thief", "Marlow", "Rook"])
		GameProgress.GuildTest.COMPLETE:
			%GuildHead.lines.assign(["Still wondering about that lock. Keep surprising me, and you'll do well here."])


func _leave_guild() -> void:
	if SceneTransition.is_transitioning:
		return
	GameProgress.town_spawn = &"guild"
	SceneTransition.change_scene("res://scenes/levels/town.tscn")
