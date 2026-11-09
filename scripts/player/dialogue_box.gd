extends PanelContainer

signal finished

@export_range(0.0, 100.0, 1.0) var characters_per_second: float = 38.0
@export var punctuation_pause: float = 0.12
@export var blips_enabled: bool = true
@export_range(0.5, 2.0, 0.05) var marlow_blip_pitch: float = 0.85
@export_range(0.5, 2.0, 0.05) var rook_blip_pitch: float = 0.75
@export_range(0.5, 2.0, 0.05) var innkeeper_blip_pitch: float = 1.15

var typing: bool = false
var current_blip_pitch: float = 1.0
var reveal_delay: float = 0.0
var parsed_page: String = ""
var blip_counter: int = 0
@onready var text_label: RichTextLabel = $Margin/Row/Content/Text
@onready var text_blip: AudioStreamPlayer = $TextBlip

var pages: Array[String] = []
var page_index: int = 0
var default_speaker: String = ""
var page_speakers: Array[String] = []


func _ready() -> void:
	minimum_size_changed.connect(_fit_height)


func _fit_height() -> void:
	_apply_height.call_deferred()


func _apply_height() -> void:
	# Grow upward while keeping the lower edge six pixels above the viewport.
	offset_bottom = -6.0
	offset_top = offset_bottom - maxf(56.0, get_combined_minimum_size().y)


func start(speaker: String, lines: Array[String], portrait: Texture2D = null, speakers: Array[String] = []) -> void:
	pages = lines.duplicate()
	default_speaker = speaker
	page_speakers = speakers.duplicate()
	page_index = 0
	$Margin/Row/SpeakerColumn/Name.text = speaker
	$Margin/Row/SpeakerColumn/Name.visible = not speaker.is_empty()
	$Margin/Row/SpeakerColumn/Portrait.texture = portrait
	$Margin/Row/SpeakerColumn/Portrait.visible = portrait != null
	$Margin/Row/SpeakerColumn.visible = portrait != null or not speaker.is_empty()
	show_page()


func advance() -> void:
	if typing:
		finish_typing()
		return
	page_index += 1
	show_page()


func show_page() -> void:
	if page_index >= pages.size():
		typing = false
		text_blip.stop()
		hide()
		finished.emit()
		return
	var speaker := page_speakers[page_index] if page_index < page_speakers.size() else default_speaker
	match speaker.strip_edges().to_lower():
		"marlow", "guild head":
			current_blip_pitch = marlow_blip_pitch
		"rook", "seasoned thief":
			current_blip_pitch = rook_blip_pitch
		"innkeeper":
			current_blip_pitch = innkeeper_blip_pitch
		_:
			current_blip_pitch = 1.0
	$Margin/Row/SpeakerColumn/Name.text = speaker
	$Margin/Row/SpeakerColumn/Name.visible = not speaker.is_empty()
	# A portrait supplied for the main speaker must not represent another speaker.
	var show_portrait: bool = $Margin/Row/SpeakerColumn/Portrait.texture != null and speaker == default_speaker
	$Margin/Row/SpeakerColumn/Portrait.visible = show_portrait
	$Margin/Row/SpeakerColumn.visible = show_portrait or not speaker.is_empty()
	$Margin/Row/Content/Text.text = pages[page_index]
	parsed_page = text_label.get_parsed_text()
	text_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	text_label.visible_characters = 0
	typing = not parsed_page.is_empty() and characters_per_second > 0.0
	reveal_delay = 0.0
	blip_counter = 0
	text_blip.stop()
	_update_continue_prompt()
	if not typing:
		finish_typing()
	show()


func _process(delta: float) -> void:
	if not visible or not typing:
		return
	reveal_delay -= delta
	var played_blip := false
	while typing and reveal_delay <= 0.0:
		var character := parsed_page.substr(text_label.visible_characters, 1)
		text_label.visible_characters += 1
		reveal_delay += 1.0 / maxf(characters_per_second, 1.0)
		if character.strip_edges() != "":
			blip_counter += 1
			if blips_enabled and not played_blip and blip_counter % 2 == 1:
				text_blip.pitch_scale = current_blip_pitch * randf_range(0.95, 1.05)
				text_blip.play()
				played_blip = true
		if character in [".", ",", "!", "?", ":", ";", "…"]:
			reveal_delay += punctuation_pause
		if text_label.visible_characters >= parsed_page.length():
			finish_typing(false)


func finish_typing(stop_sound: bool = true) -> void:
	typing = false
	text_label.visible_characters = -1
	if stop_sound:
		text_blip.stop()
	_update_continue_prompt()


func _update_continue_prompt() -> void:
	$Margin/Row/Content/Continue.text = "[E] %s" % (
		"Skip" if typing else ("Close" if page_index == pages.size() - 1 else "Next")
	)
