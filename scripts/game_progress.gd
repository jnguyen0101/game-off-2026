extends Node

# Opening progress for this play session; reset when the game restarts.
var resume_read: bool = false
var shift_unlocked: bool = false
var returning_home: bool = false
var town_spawn: StringName = &"home"

enum GuildTest { NOT_ASSIGNED, ASSIGNED, OPENED, COMPLETE }
var guild_test: GuildTest = GuildTest.NOT_ASSIGNED
var test_chest_locked: bool = true
var test_chest_opened: bool = false
var test_crate_locked: bool = false
var test_keg_locked: bool = false
var carried_property: ShiftProperty = null


func get_objective(in_guild: bool = false) -> String:
	match guild_test:
		GuildTest.ASSIGNED:
			return "Open the chest that has a lock on it"
		GuildTest.OPENED:
			if not has_placed_test_lock():
				return "Place LOCKED on the crate or keg"
			return "Return to the guild head"
		GuildTest.COMPLETE:
			return "Guild test complete"
	return "Speak to the guild head" if in_guild else (
		"Head to the Thieves' Guild" if resume_read else "Explore the town"
	)


func has_placed_test_lock() -> bool:
	return test_crate_locked or test_keg_locked
