extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	root.size = Vector2i(320, 180)
	var box = load("res://scenes/ui/dialogue_box.tscn").instantiate()
	root.add_child(box)
	box.set_process(false)
	var lines: Array[String] = ["[b]Ab[/b] c.", "Second line"]
	var speakers: Array[String] = ["Marlow", "Rook"]
	box.start("Marlow", lines, null, speakers)
	assert(box.typing and box.text_label.visible_characters == 0, "New pages must begin hidden")
	assert(box.parsed_page == "Ab c.", "BBCode must not be revealed as literal characters")
	box._process(0.001)
	assert(box.text_label.visible_characters == 1 and box.text_blip.playing, "Characters must reveal gradually with a blip")
	assert(box.text_blip.pitch_scale >= 0.75 * 0.95 and box.text_blip.pitch_scale <= 0.75 * 1.05, "Marlow must use his lower voice pitch")
	box.advance()
	assert(box.page_index == 0 and not box.typing and box.text_label.visible_characters == -1, "E while typing must reveal the current page without advancing")
	assert(not box.text_blip.playing, "Skipping must stop the blip")
	box.advance()
	assert(box.page_index == 1 and box.typing and box.text_label.visible_characters == 0, "The next E must start the next page")
	assert(box.get_node("Margin/Row/SpeakerColumn/Name").text == "Rook", "Page changes must retain speaker switching")
	box._process(2.0)
	assert(box.text_blip.pitch_scale >= 1.15 * 0.95 and box.text_blip.pitch_scale <= 1.15 * 1.05, "Rook must switch to his own voice pitch")
	assert(not box.typing and box.visible, "A complete line must wait for input")
	box.advance()
	assert(not box.visible, "E must close the last completed page")
	lines.assign(["A"])
	box.start("Seasoned Thief", lines)
	assert(box.current_blip_pitch == box.rook_blip_pitch, "Rook must retain his voice before his name is revealed")
	box.start("", lines)
	box._process(0.001)
	assert(box.text_blip.pitch_scale >= 0.95 and box.text_blip.pitch_scale <= 1.05, "Player thoughts must retain the original pitch")
	box.start("Other NPC", lines)
	assert(box.current_blip_pitch == 1.0, "Other dialogue must retain the original pitch")
	lines.assign([" "])
	box.start("", lines)
	box._process(0.001)
	assert(not box.text_blip.playing, "Whitespace must not blip")
	lines.assign(["A."])
	box.blips_enabled = false
	box.start("", lines)
	box._process(0.001)
	assert(not box.text_blip.playing, "Blips must be optional")
	box.blips_enabled = true
	box.characters_per_second = 0.0
	box.start("", lines)
	assert(not box.typing and box.text_label.visible_characters == -1, "Zero speed must show text instantly")
	box.text_blip.stop()
	await create_timer(0.15).timeout
	box.queue_free()
	await process_frame
	print("Dialogue typewriter and blip checks passed")
	quit()
