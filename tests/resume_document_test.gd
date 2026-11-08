extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	root.size = Vector2i(320, 180)
	var progress = root.get_node("GameProgress")
	progress.resume_read = false
	progress.returning_home = true
	var home = load("res://scenes/levels/player_home.tscn").instantiate()
	root.add_child(home)
	var player = home.get_node("%Player")
	var resume = home.get_node("%Resume")
	var document = home.get_node("%ResumeDocument")
	resume.interact(player)
	assert(document.visible and paused, "Reading must open the document and pause gameplay")
	assert(not player.dialogue_active, "The resume must not open a dialogue box")
	assert(not progress.resume_read and resume.visible, "The resume must remain on the desk until closing")
	await document.slide_tween.finished
	var paper = document.get_node("Paper")
	assert(paper.size.y <= 150 and paper.size.x <= 123 and paper.position.y >= 0 and paper.position.y + paper.size.y <= 180, "The resume must preserve the compact size and fit the viewport")
	document.get_node("Paper/Margin/Column/Header/Close").pressed.emit()
	await document.closed
	assert(not document.visible and not paused, "X must close the document and restore gameplay")
	assert(progress.resume_read and not resume.visible, "Closing must collect the resume")
	assert(not resume.is_in_group("dialogue_interactable"), "The collected resume must no longer be interactable")
	home.queue_free()
	await process_frame
	progress.returning_home = true
	home = load("res://scenes/levels/player_home.tscn").instantiate()
	root.add_child(home)
	assert(not home.get_node("%Resume").visible, "The resume must remain collected after returning home")
	print("Resume document checks passed")
	quit()
