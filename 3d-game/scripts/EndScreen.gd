# res://scripts/EndScreen.gd
extends Control

# --- Adjust these paths to match your scene tree if necessary ---
var PATH_RECENT_LABEL: String = "MarginContainer/Panel/VBoxContainer/RecentHBox/Label/RecentLabel"
var PATH_HIGHSCORES_VBOX: String = "MarginContainer/Panel/HighscoresVBox"
var PATH_QUIT_BUTTON: String = "MarginContainer/Panel/VBoxContainer/ButtonsHBox/QuitButton"

# node refs
var lbl_recent: Label = null
var vbox_highscores: VBoxContainer = null
var btn_quit: Button = null

# storage
const HIGHSCORE_FILE: String = "user://highscores.json"
const MAX_SCORES: int = 5

# display / tolerance
const FLOAT_EPS: float = 0.001
const RECENT_EPS: float = 0.05   # 50 ms tolerance for matching recent time
const DEBUG: bool = false

# runtime state
var highscores: Array = []       # in-memory list for current track
var last_time: float = 0.0       # most recent run's time
var recent_recorded: bool = false
var recent_index: int = -1       # index in highscores[] of the newly-recorded run (or -1)
var track_id: String = "default"

func _ready() -> void:
	# resolve nodes safely
	lbl_recent = get_node_or_null(PATH_RECENT_LABEL) as Label
	vbox_highscores = get_node_or_null(PATH_HIGHSCORES_VBOX) as VBoxContainer
	btn_quit = get_node_or_null(PATH_QUIT_BUTTON) as Button

	if lbl_recent == null:
		push_warning("EndScreen: RecentLabel missing: " + PATH_RECENT_LABEL)
	if vbox_highscores == null:
		push_warning("EndScreen: HighscoresVBox missing: " + PATH_HIGHSCORES_VBOX)
	if btn_quit == null:
		push_warning("EndScreen: QuitButton missing: " + PATH_QUIT_BUTTON)

	_safe_connect_button(btn_quit, "_on_quit_pressed")

	# -----------------------------
	# ROBUST CAPTURE: grab race info immediately from RaceManager
	# -----------------------------
	var captured_time: float = 0.0
	var captured_track: String = "default"

	if typeof(RaceManager) != TYPE_NIL:
		# capture time
		if "last_time" in RaceManager:
			var v = RaceManager.last_time
			if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
				captured_time = float(v)
		elif RaceManager is Object:
			var maybe_t = RaceManager.get("last_time")
			if typeof(maybe_t) in [TYPE_INT, TYPE_FLOAT]:
				captured_time = float(maybe_t)

		# capture track id
		if "last_track" in RaceManager:
			var t = RaceManager.last_track
			if typeof(t) == TYPE_STRING and t.strip_edges() != "":
				captured_track = str(t)
		elif RaceManager is Object:
			var maybe_tr = RaceManager.get("last_track")
			if typeof(maybe_tr) == TYPE_STRING and str(maybe_tr).strip_edges() != "":
				captured_track = str(maybe_tr)

	if DEBUG:
		print("[DEBUG] EndScreen captured_time=", captured_time, " captured_track=", captured_track)

	# load + record (per-track)
	_load_highscores_for(captured_track)

	if captured_time > 0.0:
		_add_to_highscores_for(captured_track, captured_time)
		# ensure local display values reflect captured run
		last_time = captured_time
		track_id = captured_track
		recent_recorded = true
	else:
		track_id = captured_track

	# Always update recent label if we have a last_time
	if lbl_recent and last_time > 0.0:
		lbl_recent.text = "Your time: " + _format_time(last_time)
	elif lbl_recent:
		lbl_recent.text = "Your time: --:--.---"

	_display_highscores()
	show()

	# Optional: clear RaceManager values after capture to avoid accidental reuse
	if typeof(RaceManager) != TYPE_NIL:
		if "last_time" in RaceManager:
			RaceManager.last_time = 0.0
		elif RaceManager is Object:
			RaceManager.set("last_time", 0.0)
		if "last_track" in RaceManager:
			RaceManager.last_track = ""
		elif RaceManager is Object:
			RaceManager.set("last_track", "")

# -----------------------
# Per-track storage helpers
# -----------------------
func _get_highscores_dict() -> Dictionary:
	var f: FileAccess = FileAccess.open(HIGHSCORE_FILE, FileAccess.ModeFlags.READ)
	if not f:
		return {}
	var txt: String = f.get_as_text()
	f.close()
	if txt.strip_edges() == "":
		return {}
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	elif typeof(parsed) == TYPE_ARRAY:
		# legacy single-array format -> place under "default"
		return {"default": parsed}
	else:
		return {}

func _save_highscores_dict(d: Dictionary) -> void:
	var f: FileAccess = FileAccess.open(HIGHSCORE_FILE, FileAccess.ModeFlags.WRITE)
	if not f:
		push_warning("EndScreen: could not open highscores for write: " + HIGHSCORE_FILE)
		return
	f.store_string(JSON.stringify(d))
	f.close()

func _load_highscores_for(p_track_id: String) -> void:
	highscores.clear()
	if p_track_id == "" or p_track_id == null:
		p_track_id = "default"
	var dict := _get_highscores_dict()
	var arr: Array = []
	if dict.has(p_track_id) and typeof(dict[p_track_id]) == TYPE_ARRAY:
		arr = dict[p_track_id]
	for item in arr:
		if typeof(item) == TYPE_INT or typeof(item) == TYPE_FLOAT:
			highscores.append(float(item))
	highscores.sort()
	if highscores.size() > MAX_SCORES:
		highscores = highscores.slice(0, MAX_SCORES)

func _add_to_highscores_for(p_track_id: String, new_time: float) -> void:
	# Merge / sort / trim and save per-track
	if p_track_id == "" or p_track_id == null:
		p_track_id = "default"
	var dict := _get_highscores_dict()
	var arr: Array = []
	if dict.has(p_track_id) and typeof(dict[p_track_id]) == TYPE_ARRAY:
		arr = dict[p_track_id].duplicate()
	arr.append(float(new_time))
	arr.sort()
	if arr.size() > MAX_SCORES:
		arr = arr.slice(0, MAX_SCORES)
	dict[p_track_id] = arr
	_save_highscores_dict(dict)

	# update in-memory list for UI
	highscores.clear()
	for item in arr:
		if typeof(item) == TYPE_INT or typeof(item) == TYPE_FLOAT:
			highscores.append(float(item))

	# find recent index using RECENT_EPS tolerance
	recent_index = -1
	for i in range(highscores.size()):
		if abs(highscores[i] - float(new_time)) <= RECENT_EPS:
			recent_index = i
			break

	# ensure last_time for display is set
	last_time = float(new_time)

	if DEBUG:
		print("[DEBUG] highscores for", p_track_id, "=", highscores, " recent_index=", recent_index)

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
	header.text = "Top " + str(MAX_SCORES) + " Times (" + track_id + ")"
	header.add_theme_constant_override("font_size", 18)
	vbox_highscores.add_child(header)

	var recent_in_list: bool = false
	for i in range(highscores.size()):
		var t: float = float(highscores[i])
		var row: HBoxContainer = HBoxContainer.new()

		var rank_lbl: Label = Label.new()
		rank_lbl.text = str(i + 1) + "."
		rank_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var time_lbl: Label = Label.new()
		time_lbl.text = _format_time(t)

		# Prefer index match; fallback to tolerant float compare
		var is_recent: bool = (i == recent_index) or (abs(t - last_time) <= RECENT_EPS)

		if is_recent:
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

	# if recent not in top list, show it below as "Recent"
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
# Helpers & formatting
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

func _safe_connect_button(btn: Button, method_name: String) -> void:
	if btn == null:
		return
	var conns := btn.get_signal_connection_list("pressed")
	for conn in conns:
		if conn.has("target") and conn.has("method"):
			if conn["target"] == self and str(conn["method"]) == method_name:
				return
	btn.pressed.connect(Callable(self, method_name))

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
			get_tree().quit()

# -----------------------
# RaceManager helpers (compat)
# -----------------------
func _has_racemanager_autoload() -> bool:
	return typeof(RaceManager) != TYPE_NIL
