# res://scripts/EndScreen.gd
extends Control

# --- Configure these paths to match your scene if necessary ---
var PATH_RECENT_LABEL: String = "MarginContainer/Panel/VBoxContainer/RecentHBox/Label/RecentLabel"
var PATH_HIGHSCORES_VBOX: String = "MarginContainer/Panel/HighscoresVBox"
var PATH_QUIT_BUTTON: String = "MarginContainer/Panel/VBoxContainer/ButtonsHBox/QuitButton"

# resolved nodes (populated in _ready)
var lbl_recent: Label = null
var vbox_highscores: VBoxContainer = null
var btn_quit: Button = null

const HIGHSCORE_FILE: String = "user://highscores.json"
const MAX_SCORES: int = 5
const FLOAT_EPS: float = 0.001
const DEBUG: bool = false

var highscores: Array = []
var last_time: float = 0.0
var recent_recorded: bool = false

func _ready() -> void:
	# Resolve nodes safely
	lbl_recent = get_node_or_null(PATH_RECENT_LABEL) as Label
	vbox_highscores = get_node_or_null(PATH_HIGHSCORES_VBOX) as VBoxContainer
	btn_quit = get_node_or_null(PATH_QUIT_BUTTON) as Button

	# Non-fatal warnings for missing nodes
	if lbl_recent == null:
		push_warning("EndScreen: RecentLabel not found at: " + PATH_RECENT_LABEL)
	if vbox_highscores == null:
		push_warning("EndScreen: HighscoresVBox not found at: " + PATH_HIGHSCORES_VBOX)
	if btn_quit == null:
		push_warning("EndScreen: QuitButton not found at: " + PATH_QUIT_BUTTON)

	# Connect quit button safely
	_safe_connect_button(btn_quit, "_on_quit_pressed")

	# Load highscores and show UI
	_load_highscores()

	# Capture last_time from RaceManager if available
	if _capture_racemanager_time():
		_record_recent_and_display()
	else:
		if lbl_recent:
			lbl_recent.text = "Your time: --:--.---"
		_display_highscores()
		show()

# Public API — show end screen with a given recent time
func show_end(recent_time_seconds: float) -> void:
	last_time = recent_time_seconds
	_record_recent_and_display()

# Internal: record recent run once and display highscores
func _record_recent_and_display() -> void:
	if recent_recorded == false and last_time > 0.0:
		if lbl_recent:
			lbl_recent.text = "Your time: " + _format_time(last_time)
		_add_to_highscores(last_time)
		recent_recorded = true
	_display_highscores()
	show()
	if DEBUG:
		print("[EndScreen] show_end; last_time=", last_time, " highscores=", highscores)

# -----------------------
# Safe connect helper
# -----------------------
func _safe_connect_button(btn: Button, method_name: String) -> void:
	if btn == null:
		return
	# Check existing connections via get_signal_connection_list
	var conns := btn.get_signal_connection_list("pressed")
	for conn in conns:
		if conn.has("target") and conn.has("method"):
			if conn["target"] == self and str(conn["method"]) == method_name:
				# already connected
				return
	# connect now
	btn.pressed.connect(Callable(self, method_name))

# -----------------------
# Highscore persistence & merging
# -----------------------
func _add_to_highscores(new_time: float) -> void:
	# reload from disk to merge safely
	_load_highscores()
	highscores.append(float(new_time))
	highscores.sort() # ascending: lower is better
	if highscores.size() > MAX_SCORES:
		highscores = highscores.slice(0, MAX_SCORES)
	_save_highscores()
	if DEBUG:
		print("[EndScreen] _add_to_highscores ->", highscores)

func _load_highscores() -> void:
	highscores.clear()
	var f: FileAccess = FileAccess.open(HIGHSCORE_FILE, FileAccess.ModeFlags.READ)
	if not f:
		if DEBUG:
			print("[EndScreen] _load_highscores: no file at", ProjectSettings.globalize_path(HIGHSCORE_FILE))
		return
	var txt: String = f.get_as_text()
	f.close()
	if txt.strip_edges() == "":
		return

	var parsed = JSON.parse_string(txt)
	var arr: Array = []

	if typeof(parsed) == TYPE_DICTIONARY:
		var err = parsed.get("error", null)
		var res = parsed.get("result", null)
		if err == OK and typeof(res) == TYPE_ARRAY:
			arr = res
	elif typeof(parsed) == TYPE_ARRAY:
		# might be [err, result] or plain array
		if parsed.size() >= 2 and parsed[0] == OK and typeof(parsed[1]) == TYPE_ARRAY:
			arr = parsed[1]
		else:
			arr = parsed
	else:
		# fallback: treat as array if possible
		if typeof(parsed) == TYPE_ARRAY:
			arr = parsed

	for item in arr:
		if typeof(item) == TYPE_INT or typeof(item) == TYPE_FLOAT:
			highscores.append(float(item))

	highscores.sort()
	if highscores.size() > MAX_SCORES:
		highscores = highscores.slice(0, MAX_SCORES)

	if DEBUG:
		print("[EndScreen] _load_highscores ->", highscores)

func _save_highscores() -> void:
	var f: FileAccess = FileAccess.open(HIGHSCORE_FILE, FileAccess.ModeFlags.WRITE)
	if not f:
		push_warning("EndScreen: failed to open highscores for write: " + HIGHSCORE_FILE)
		return
	var out := JSON.stringify(highscores)
	f.store_string(out)
	f.close()
	if DEBUG:
		print("[EndScreen] _save_highscores wrote:", out, "to", ProjectSettings.globalize_path(HIGHSCORE_FILE))

# -----------------------
# UI rendering
# -----------------------
func _display_highscores() -> void:
	if vbox_highscores == null:
		return

	# clear previous children
	for c in vbox_highscores.get_children():
		vbox_highscores.remove_child(c)
		c.queue_free()

	var header: Label = Label.new()
	header.text = "Top " + str(MAX_SCORES) + " Times"
	header.add_theme_constant_override("font_size", 18)
	vbox_highscores.add_child(header)

	var recent_in_list: bool = false
	var i: int = 0
	while i < highscores.size():
		var t: float = float(highscores[i])
		var row: HBoxContainer = HBoxContainer.new()

		var rank_lbl: Label = Label.new()
		rank_lbl.text = str(i + 1) + "."
		rank_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var time_lbl: Label = Label.new()
		time_lbl.text = _format_time(t)

		if abs(t - last_time) < FLOAT_EPS:
			time_lbl.add_theme_constant_override("font_size", 16)
			var recent_tag: Label = Label.new()
			recent_tag.text = "  ← NEW"
			recent_tag.add_theme_constant_override("font_size", 14)
			row.add_child(rank_lbl)
			row.add_child(time_lbl)
			row.add_child(recent_tag)
			recent_in_list = true
		else:
			row.add_child(rank_lbl)
			row.add_child(time_lbl)

		vbox_highscores.add_child(row)
		i += 1

	if not recent_in_list and last_time > 0.0:
		var sep: HSeparator = HSeparator.new()
		vbox_highscores.add_child(sep)
		var recent_row: HBoxContainer = HBoxContainer.new()
		var rlabel: Label = Label.new()
		rlabel.text = "Recent: "
		rlabel.add_theme_constant_override("font_size", 15)
		var rtime: Label = Label.new()
		rtime.text = _format_time(last_time)
		rtime.add_theme_constant_override("font_size", 15)
		rtime.add_theme_constant_override("font_weight", 700)
		recent_row.add_child(rlabel)
		recent_row.add_child(rtime)
		vbox_highscores.add_child(recent_row)

# -----------------------
# Formatting helper
# -----------------------
func _format_time(secs: float) -> String:
	var total_ms: int = int(round(secs * 1000.0))
	var ms: int = total_ms % 1000
	var s: int = int((total_ms / 1000) % 60)
	var m: int = int(total_ms / (1000 * 60))
	var m_str: String = "%02d" % m
	var s_str: String = "%02d" % s
	var ms_str: String = "%03d" % ms
	return m_str + ":" + s_str + "." + ms_str

# -----------------------
# Quit -> menu handler
# -----------------------
func _on_quit_pressed() -> void:
	var menu_scene: String = "res://scenes/main_menu/main_menu.tscn"
	if ResourceLoader.exists(menu_scene):
		get_tree().change_scene_to_file(menu_scene)
	else:
		var fallback_scene: String = "res://scenes/main.tscn"
		if ResourceLoader.exists(fallback_scene):
			get_tree().change_scene_to_file(fallback_scene)
		else:
			# If no menu scenes found, as a last resort just quit
			get_tree().quit()

# -----------------------
# RaceManager helpers (safe)
# -----------------------
func _has_racemanager_autoload() -> bool:
	return typeof(RaceManager) != TYPE_NIL

func _capture_racemanager_time() -> bool:
	if not _has_racemanager_autoload():
		return false

	var val = null
	if "last_time" in RaceManager:
		val = RaceManager.last_time
	elif RaceManager is Object:
		var maybe = RaceManager.get("last_time")
		if typeof(maybe) != TYPE_NIL:
			val = maybe

	if typeof(val) == TYPE_NIL:
		return false

	if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
		if float(val) > 0.0:
			last_time = float(val)
			# clear it to avoid reuse
			if "last_time" in RaceManager:
				RaceManager.last_time = 0.0
			elif RaceManager is Object:
				RaceManager.set("last_time", 0.0)
			return true
	return false
