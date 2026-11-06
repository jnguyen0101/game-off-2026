extends PanelContainer

signal finished

var pages: Array[String] = []
var page_index: int = 0


func _ready() -> void:
	minimum_size_changed.connect(_fit_height)


func _fit_height() -> void:
	_apply_height.call_deferred()


func _apply_height() -> void:
	# Grow upward while keeping the lower edge six pixels above the viewport.
	offset_bottom = -6.0
	offset_top = offset_bottom - maxf(56.0, get_combined_minimum_size().y)


func start(speaker: String, lines: Array[String], portrait: Texture2D = null) -> void:
	pages = lines.duplicate()
	page_index = 0
	$Margin/Row/SpeakerColumn/Name.text = speaker
	$Margin/Row/SpeakerColumn/Name.visible = not speaker.is_empty()
	$Margin/Row/SpeakerColumn/Portrait.texture = portrait
	$Margin/Row/SpeakerColumn/Portrait.visible = portrait != null
	$Margin/Row/SpeakerColumn.visible = portrait != null or not speaker.is_empty()
	show_page()


func advance() -> void:
	page_index += 1
	show_page()


func show_page() -> void:
	if page_index >= pages.size():
		hide()
		finished.emit()
		return
	$Margin/Row/Content/Text.text = pages[page_index]
	$Margin/Row/Content/Continue.text = "[E] %s" % [
		"Close" if page_index == pages.size() - 1 else "Next"
	]
	show()
