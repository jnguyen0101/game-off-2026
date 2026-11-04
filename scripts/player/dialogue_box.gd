extends PanelContainer

signal finished

var pages: Array[String] = []
var page_index: int = 0


func start(speaker: String, lines: Array[String]) -> void:
	pages = lines.duplicate()
	page_index = 0
	$Margin/Content/Speaker.text = speaker
	show_page()


func advance() -> void:
	page_index += 1
	show_page()


func show_page() -> void:
	if page_index >= pages.size():
		hide()
		finished.emit()
		return
	$Margin/Content/Text.text = pages[page_index]
	$Margin/Content/Continue.text = "[E] %s" % [
		"Close" if page_index == pages.size() - 1 else "Next"
	]
	show()
