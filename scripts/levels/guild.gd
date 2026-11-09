extends Node2D


func _ready() -> void:
	%Player.global_position = %EntranceSpawn.global_position
	%Player.last_direction = Vector2.UP
	%Player.update_animation(Vector2.ZERO)
	%Exit.activated.connect(_leave_guild)
	%GuildHead.dialogue_finished.connect(_on_guild_head_finished)
	%Player.property_taken.connect(_on_property_taken)
	get_node("%Wooden Chest").state_changed.connect(_update_quest)
	get_node("%Wooden Crate").state_changed.connect(_update_quest)
	get_node("%Wooden Keg").state_changed.connect(_update_quest)
	_update_quest()


func _on_property_taken(target: Node, property: ShiftProperty) -> void:
	if GameProgress.shift_discovery_seen or GameProgress.guild_test != GameProgress.GuildTest.ASSIGNED:
		return
	if target != get_node("%Wooden Chest") or property != preload("res://resources/properties/locked.tres"):
		return
	GameProgress.shift_discovery_seen = true
	%Player.start_dialogue(%ShiftDiscoveryThought)


func _on_guild_head_finished() -> void:
	match GameProgress.guild_test:
		GameProgress.GuildTest.NOT_ASSIGNED:
			GameProgress.guild_test = GameProgress.GuildTest.ASSIGNED
			GameProgress.shift_unlocked = true
		GameProgress.GuildTest.OPENED:
			if GameProgress.test_chest_opened and not GameProgress.test_chest_locked and GameProgress.has_placed_test_lock():
				GameProgress.guild_test = GameProgress.GuildTest.COMPLETE
		GameProgress.GuildTest.COMPLETE:
			if GameProgress.guild_overnight_complete:
				GameProgress.first_job_ready = true
				if GameProgress.first_job == GameProgress.FirstJob.NOT_ASSIGNED:
					GameProgress.first_job = GameProgress.FirstJob.TALK_TO_INNKEEPER
	_update_quest()


func _update_quest() -> void:
	%Objective.text = GameProgress.get_objective(true)
	%GuildHead.speaker_name = "Marlow"
	%GuildHead.interaction_prompt = "Talk to Marlow"
	%GuildHead.page_speakers.clear()
	if GameProgress.guild_test == GameProgress.GuildTest.COMPLETE:
		$World/SeasonedThief/Dialogue.speaker_name = "Rook"
		$World/SeasonedThief/Dialogue.interaction_prompt = "Talk to Rook"
		if GameProgress.guild_overnight_complete:
			$World/SeasonedThief/Dialogue.lines.assign([
				"Back again? I was hoping you'd sleep on it and find another profession.",
				"Try not to make Marlow regret his decision."
			])
		else:
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
				"What? I'm making him feel welcome.",
				"Come back tomorrow. I'll have the details of your first job ready.",
				"And get some sleep. Enthusiasm's no substitute."
			])
			%GuildHead.page_speakers.assign(["Marlow", "Marlow", "Marlow", "Seasoned Thief", "Marlow", "Rook", "Marlow", "Marlow"])
		GameProgress.GuildTest.COMPLETE:
			if not GameProgress.guild_overnight_complete:
				%GuildHead.lines.assign(["Go home and get some rest, Filch. Come back tomorrow for your first job."])
			elif GameProgress.first_job == GameProgress.FirstJob.NOT_ASSIGNED:
				%GuildHead.lines.assign([
					"Morning, Filch. You're on time. That's a promising start.",
					"The innkeeper's missing a ring. Brass signet. Belonged to her father.",
					"A palace collector took it against an unpaid levy. She paid. He kept it.",
					"Isn't that technically returning something?",
					"Get through the locked door first. We'll argue about terminology afterward.",
					"Speak to the innkeeper. Get a description, then bring back the ring. Leave everything else where it is."
				])
				%GuildHead.page_speakers.assign(["Marlow", "Marlow", "Marlow", "Oliver", "Marlow", "Marlow"])
			elif GameProgress.first_job == GameProgress.FirstJob.TALK_TO_INNKEEPER:
				%GuildHead.lines.assign(["Speak to the innkeeper at the Wayward Pick. She'll tell you what you're looking for."])
			else:
				%GuildHead.lines.assign(["Bring back the signet, Filch. One ring. No other souvenirs."])


func _leave_guild() -> void:
	if SceneTransition.is_transitioning:
		return
	GameProgress.town_spawn = &"guild"
	SceneTransition.change_scene_through_door("res://scenes/levels/town.tscn")
