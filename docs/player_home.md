# Starting home

Press F5 to start in `scenes/levels/player_home.tscn`, or open the scene and press
F6. E advances the opening thoughts. Walk to the desk on the right and press E
to read the resume. Then approach the front door at the bottom and press E to
leave. The destination is temporarily the existing test level, where the guild
head interaction lives; a town street and guild hall can replace this later.

The scene uses Kenmi's existing interior assets, wall and furniture collision,
and a fixed camera for the 320x180 room. Furniture and interaction positions are
editable in the scene. Dialogue is stored in each interaction's Lines array.
There are no floating names. The home never reveals Shift to another character.

Reading the resume changes the local objective and departure dialogue. This
opening state resets when the home scene is reloaded; persistent story progress,
an actual resume inventory item, and a return route are not implemented yet.

Validate with Godot headlessly using `--path . --script res://tests/player_home_test.gd`.
