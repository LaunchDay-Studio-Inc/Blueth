extends Node

const GameScript = preload("res://scripts/game/game.gd")
const DataScript = preload("res://scripts/game/data.gd")
const MetaProgressionScript = preload("res://scripts/game/meta_progression.gd")

var menu_layer: CanvasLayer
var menu_root: Control

var result_label: Label
var play_button: Button
var quit_button: Button

var hero_buttons: Array = []
var hero_profiles: Array = []
var selected_hero_index = 0

var realm_buttons: Array = []
var realm_profiles: Array = []
var selected_realm_index = 0

var hero_name_label: Label
var hero_tagline_label: Label
var hero_weapon_label: Label
var hero_preview: TextureRect
var realm_name_label: Label
var realm_desc_label: Label

var shards_label: Label
var meta_summary_label: Label
var meta_buttons_by_id: Dictionary = {}
var meta_progression

var current_game
var run_active = false


func _ready() -> void:
	hero_profiles = DataScript.all_heroes()
	realm_profiles = DataScript.all_realms()
	selected_realm_index = _find_realm_index("riftcore")
	meta_progression = MetaProgressionScript.new()
	_build_menu()
	_refresh_menu_ui()


func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)

	menu_root = Control.new()
	menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(menu_root)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.09, 0.12)
	menu_root.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 760)
	center.add_child(panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vb)

	var title = Label.new()
	title.text = "BLUETH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 62)
	vb.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Arena roguelike - 15 realm levels, 17-minute survival run"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.64, 0.84, 0.93))
	subtitle.add_theme_font_size_override("font_size", 20)
	vb.add_child(subtitle)

	var select_title = Label.new()
	select_title.text = "Select Blueth Build"
	select_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_title.add_theme_font_size_override("font_size", 26)
	vb.add_child(select_title)

	var hero_row_panel = PanelContainer.new()
	vb.add_child(hero_row_panel)

	var hero_row = HBoxContainer.new()
	hero_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_row.add_theme_constant_override("separation", 10)
	hero_row_panel.add_child(hero_row)

	for i in range(hero_profiles.size()):
		var hero = hero_profiles[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(170, 48)
		button.text = String(hero["name"]).replace("Blueth ", "")
		button.pressed.connect(_on_hero_selected.bind(i))
		hero_row.add_child(button)
		hero_buttons.append(button)

	var hero_panel = PanelContainer.new()
	hero_panel.custom_minimum_size = Vector2(0.0, 220.0)
	vb.add_child(hero_panel)

	var hero_panel_row = HBoxContainer.new()
	hero_panel_row.add_theme_constant_override("separation", 20)
	hero_panel.add_child(hero_panel_row)

	hero_preview = TextureRect.new()
	hero_preview.custom_minimum_size = Vector2(230, 190)
	hero_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	hero_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_panel_row.add_child(hero_preview)

	var hero_info_vb = VBoxContainer.new()
	hero_info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_panel_row.add_child(hero_info_vb)

	hero_name_label = Label.new()
	hero_name_label.add_theme_font_size_override("font_size", 34)
	hero_info_vb.add_child(hero_name_label)

	hero_tagline_label = Label.new()
	hero_tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_tagline_label.custom_minimum_size = Vector2(460, 56)
	hero_tagline_label.add_theme_font_size_override("font_size", 18)
	hero_info_vb.add_child(hero_tagline_label)

	hero_weapon_label = Label.new()
	hero_weapon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_weapon_label.add_theme_color_override("font_color", Color(0.53, 0.82, 0.90))
	hero_weapon_label.add_theme_font_size_override("font_size", 17)
	hero_info_vb.add_child(hero_weapon_label)

	var realm_title = Label.new()
	realm_title.text = "Select Realm"
	realm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	realm_title.add_theme_font_size_override("font_size", 26)
	vb.add_child(realm_title)

	var realm_row_panel = PanelContainer.new()
	vb.add_child(realm_row_panel)

	var realm_row = HBoxContainer.new()
	realm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	realm_row.add_theme_constant_override("separation", 10)
	realm_row_panel.add_child(realm_row)

	for i in range(realm_profiles.size()):
		var realm = realm_profiles[i]
		var realm_button = Button.new()
		realm_button.custom_minimum_size = Vector2(190, 44)
		realm_button.text = realm.get("name", "Realm")
		realm_button.pressed.connect(_on_realm_selected.bind(i))
		realm_row.add_child(realm_button)
		realm_buttons.append(realm_button)

	var realm_panel = PanelContainer.new()
	realm_panel.custom_minimum_size = Vector2(0.0, 118.0)
	vb.add_child(realm_panel)

	var realm_vb = VBoxContainer.new()
	realm_vb.add_theme_constant_override("separation", 4)
	realm_panel.add_child(realm_vb)

	realm_name_label = Label.new()
	realm_name_label.add_theme_font_size_override("font_size", 24)
	realm_vb.add_child(realm_name_label)

	realm_desc_label = Label.new()
	realm_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	realm_desc_label.custom_minimum_size = Vector2(760, 50)
	realm_desc_label.add_theme_font_size_override("font_size", 16)
	realm_vb.add_child(realm_desc_label)

	var meta_panel = PanelContainer.new()
	meta_panel.custom_minimum_size = Vector2(0.0, 270.0)
	vb.add_child(meta_panel)

	var meta_vb = VBoxContainer.new()
	meta_vb.add_theme_constant_override("separation", 6)
	meta_panel.add_child(meta_vb)

	var meta_title = Label.new()
	meta_title.text = "Persistent Skill Tree"
	meta_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_title.add_theme_font_size_override("font_size", 24)
	meta_vb.add_child(meta_title)

	shards_label = Label.new()
	shards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shards_label.add_theme_color_override("font_color", Color(0.58, 0.96, 0.84))
	shards_label.add_theme_font_size_override("font_size", 17)
	meta_vb.add_child(shards_label)

	meta_summary_label = Label.new()
	meta_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_summary_label.custom_minimum_size = Vector2(720, 40)
	meta_summary_label.add_theme_font_size_override("font_size", 15)
	meta_vb.add_child(meta_summary_label)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 175.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meta_vb.add_child(scroll)

	var meta_grid = GridContainer.new()
	meta_grid.columns = 2
	meta_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_grid.add_theme_constant_override("h_separation", 8)
	meta_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(meta_grid)

	for node in meta_progression.get_nodes_for_ui():
		var node_id = String(node.get("id", ""))
		var node_button = Button.new()
		node_button.custom_minimum_size = Vector2(0.0, 76.0)
		node_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node_button.clip_text = false
		node_button.pressed.connect(_on_meta_upgrade_pressed.bind(node_id))
		meta_grid.add_child(node_button)
		meta_buttons_by_id[node_id] = node_button

	result_label = Label.new()
	result_label.text = "Move with WASD/Arrow keys. Pick hero + realm, then spend shards in the skill tree before starting."
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.custom_minimum_size = Vector2(600, 92)
	result_label.add_theme_font_size_override("font_size", 18)
	vb.add_child(result_label)

	play_button = Button.new()
	play_button.text = "Start Run"
	play_button.custom_minimum_size = Vector2(0, 56)
	play_button.pressed.connect(_on_play_pressed)
	vb.add_child(play_button)

	quit_button = Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(0, 46)
	quit_button.pressed.connect(_on_quit_pressed)
	vb.add_child(quit_button)


func _find_realm_index(realm_id: String) -> int:
	for i in range(realm_profiles.size()):
		var realm = realm_profiles[i]
		if String(realm.get("id", "")) == realm_id:
			return i
	return 0


func _refresh_menu_ui() -> void:
	_refresh_hero_ui()
	_refresh_realm_ui()
	_refresh_meta_ui()
	_refresh_play_button_text()


func _refresh_hero_ui() -> void:
	if hero_profiles.is_empty():
		return

	selected_hero_index = clamp(selected_hero_index, 0, hero_profiles.size() - 1)
	var hero = hero_profiles[selected_hero_index]
	var weapon_id = String(hero.get("weapon", "shotgun"))
	var weapon_data = DataScript.WEAPONS.get(weapon_id, {"name": "Weapon", "desc": ""})

	for i in range(hero_buttons.size()):
		var button: Button = hero_buttons[i]
		button.disabled = i == selected_hero_index

	hero_name_label.text = hero.get("name", "Blueth")
	hero_tagline_label.text = hero.get("tagline", "")
	hero_weapon_label.text = "%s\n%s" % [weapon_data["name"], weapon_data["desc"]]

	var texture_path = "res://assets/ui/hero_%s.svg" % hero.get("id", "warden")
	if ResourceLoader.exists(texture_path):
		hero_preview.texture = load(texture_path)
	else:
		hero_preview.texture = null


func _refresh_realm_ui() -> void:
	if realm_profiles.is_empty():
		return

	selected_realm_index = clamp(selected_realm_index, 0, realm_profiles.size() - 1)
	var realm = realm_profiles[selected_realm_index]

	for i in range(realm_buttons.size()):
		var button: Button = realm_buttons[i]
		button.disabled = i == selected_realm_index

	realm_name_label.text = "Realm: %s" % realm.get("name", "Riftcore")
	realm_desc_label.text = realm.get("desc", "")


func _refresh_meta_ui() -> void:
	var modifiers: Dictionary = meta_progression.get_run_modifiers()
	var hp_bonus = (float(modifiers.get("max_hp_mult", 1.0)) - 1.0) * 100.0
	var dmg_bonus = (float(modifiers.get("damage_mult", 1.0)) - 1.0) * 100.0
	var fire_bonus = (float(modifiers.get("fire_rate_mult", 1.0)) - 1.0) * 100.0
	var move_bonus = (float(modifiers.get("move_speed_mult", 1.0)) - 1.0) * 100.0
	var incoming_pct = float(modifiers.get("damage_taken_mult", 1.0)) * 100.0
	shards_label.text = "Shards %d  |  Lifetime %d  |  Runs %d" % [
		meta_progression.get_shards(),
		meta_progression.get_total_shards_earned(),
		meta_progression.get_runs_played()
	]
	meta_summary_label.text = "Current bonuses: +%.0f%% HP, +%.0f%% damage, +%.0f%% fire rate, +%.0f%% move speed, %.0f%% incoming damage." % [
		hp_bonus,
		dmg_bonus,
		fire_bonus,
		move_bonus,
		incoming_pct
	]

	for node in meta_progression.get_nodes_for_ui():
		var node_id = String(node.get("id", ""))
		if not meta_buttons_by_id.has(node_id):
			continue

		var button: Button = meta_buttons_by_id[node_id]
		var rank = int(node.get("rank", 0))
		var max_rank = int(node.get("max_rank", 0))
		var is_maxed = rank >= max_rank
		var cost_text = "MAXED" if is_maxed else "Cost: %d shards" % int(node.get("cost", 0))
		button.text = "%s [%d/%d]\n%s\n%s" % [
			node.get("name", "Node"),
			rank,
			max_rank,
			node.get("desc", ""),
			cost_text
		]
		button.disabled = is_maxed or not bool(node.get("can_upgrade", false))


func _refresh_play_button_text() -> void:
	if hero_profiles.is_empty() or realm_profiles.is_empty():
		return
	var hero = hero_profiles[selected_hero_index]
	var realm = realm_profiles[selected_realm_index]
	play_button.text = "Start Run: %s @ %s" % [hero.get("name", "Blueth"), realm.get("name", "Riftcore")]


func _on_hero_selected(index: int) -> void:
	selected_hero_index = index
	_refresh_hero_ui()
	_refresh_play_button_text()


func _on_realm_selected(index: int) -> void:
	selected_realm_index = index
	_refresh_realm_ui()
	_refresh_play_button_text()


func _on_meta_upgrade_pressed(node_id: String) -> void:
	if run_active:
		return

	if meta_progression.upgrade_node(node_id):
		result_label.text = "Meta upgrade purchased: %s" % node_id
	else:
		result_label.text = "Not enough shards for that node yet."
	_refresh_meta_ui()


func _on_play_pressed() -> void:
	_start_run()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _start_run() -> void:
	if current_game != null:
		current_game.queue_free()

	var hero = hero_profiles[selected_hero_index]
	var realm = realm_profiles[selected_realm_index]
	var run_modifiers = meta_progression.get_run_modifiers()
	current_game = GameScript.new()
	current_game.setup_run({
		"hero_id": hero.get("id", "warden"),
		"realm_id": realm.get("id", "riftcore"),
		"meta": run_modifiers
	})
	add_child(current_game)
	current_game.run_finished.connect(_on_run_finished)

	menu_layer.hide()
	run_active = true


func _on_run_finished(victory: bool, stats: Dictionary) -> void:
	if current_game != null:
		current_game.queue_free()
		current_game = null

	var seconds = int(stats.get("time_survived", 0.0))
	var mm = int(float(seconds) / 60.0)
	var ss = int(seconds % 60)
	var time_text = "%02d:%02d" % [mm, ss]
	var verdict = "Victory" if victory else "Defeat"
	var mastery_earned = max(0, int(stats.get("mastery_earned", 0)))
	meta_progression.add_shards(mastery_earned)
	var total_shards = meta_progression.get_shards()

	result_label.text = "%s\nHero: %s\nRealm: %s\nWeapon: %s\nTime: %s  Level: %d  Kills: %d\nMastery gained: +%d (Bank: %d)" % [
		verdict,
		stats.get("hero", "Blueth"),
		stats.get("realm", "Riftcore"),
		stats.get("weapon", "Unknown"),
		time_text,
		int(stats.get("level", 1)),
		int(stats.get("kills", 0)),
		mastery_earned,
		total_shards
	]

	_refresh_meta_ui()
	_refresh_play_button_text()
	menu_layer.show()
	run_active = false
