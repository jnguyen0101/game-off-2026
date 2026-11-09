extends Node

# Opening progress for this play session; reset when the game restarts.
var resume_read: bool = false
var shift_unlocked: bool = false
var returning_home: bool = false
var town_spawn: StringName = &"home"
var returning_from_inn_upstairs: bool = false

enum GuildTest { NOT_ASSIGNED, ASSIGNED, OPENED, COMPLETE }
var guild_test: GuildTest = GuildTest.NOT_ASSIGNED
var test_chest_locked: bool = true
var test_chest_opened: bool = false
var test_crate_locked: bool = false
var test_keg_locked: bool = false
var shift_discovery_seen: bool = false
var guild_overnight_complete: bool = false
var waking_next_morning: bool = false
var first_job_ready: bool = false
enum FirstJob { NOT_ASSIGNED, TALK_TO_INNKEEPER, CLIENT_BRIEFED }
var first_job: FirstJob = FirstJob.NOT_ASSIGNED
var carried_property: ShiftProperty = null


func get_objective(in_guild: bool = false) -> String:
	match guild_test:
		GuildTest.ASSIGNED:
			return "Pass Marlow's interview"
		GuildTest.OPENED:
			if not has_placed_test_lock():
				return "Place LOCKED on another object"
			return "Return to the guild head"
		GuildTest.COMPLETE:
			if not guild_overnight_complete:
				return "Go home and rest"
			match first_job:
				FirstJob.TALK_TO_INNKEEPER:
					return "Speak to the innkeeper"
				FirstJob.CLIENT_BRIEFED:
					return "Recover the innkeeper's signet ring"
			return "Return to Marlow for your first job"
	return "Speak to the guild head" if in_guild else (
		"Head to the Thieves' Guild" if resume_read else "Explore the town"
	)


func has_placed_test_lock() -> bool:
	return test_crate_locked or test_keg_locked
