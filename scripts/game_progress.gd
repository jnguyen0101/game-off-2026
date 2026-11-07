extends Node

# Opening progress for this play session; reset when the game restarts.
var resume_read: bool = false
var returning_home: bool = false
var town_spawn: StringName = &"home"
