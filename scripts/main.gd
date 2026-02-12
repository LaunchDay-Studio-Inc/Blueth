extends Node

const GameScript = preload("res://scripts/game/game.gd")
const DataScript = preload("res://scripts/game/data.gd")
const MetaProgressionScript = preload("res://scripts/game/meta_progression.gd")
const MENU_BACKDROP_PATH = "res://assets/ui/menu_backdrop.svg"
const UI_CLICK_SFX_PATH = "res://assets/audio/sfx_click.wav"

var menu_layer: CanvasLayer
var menu_root: Control

var home_page: Control
var play_page: Control
var settings_page: Control
var menu_scroll: ScrollContainer

var play_now_button: Button
var settings_button: Button

var home_bank_label: Label

var play_notice_label: Label
var settings_notice_label: Label

var result_overlay: Control
var result_label: Label
var result_continue_button: Button
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
var achievements_label: Label
var meta_buttons_by_id: Dictionary = {}
var shop_buttons_by_id: Dictionary = {}
var meta_progression

var music_slider: HSlider
var music_value_label: Label
var sfx_slider: HSlider
var sfx_value_label: Label
var flash_slider: HSlider
var flash_value_label: Label
var shake_slider: HSlider
var shake_value_label: Label
var bg_slider: HSlider
var bg_value_label: Label
var show_enemy_hp_checkbox: CheckBox
var show_boss_hp_checkbox: CheckBox
var show_damage_numbers_checkbox: CheckBox
var reduced_particles_checkbox: CheckBox

var ui_sfx_player: AudioStreamPlayer

var current_game
var run_active = false


func _ready() -> void:
	hero_profiles = DataScript.all_heroes()
	realm_profiles = DataScript.all_realms()
	meta_progression = MetaProgressionScript.new()
	if meta_progression.is_realm_unlocked("riftcore"):
		selected_realm_index = _find_realm_index("riftcore")
	else:
		selected_realm_index = _find_realm_index("frostfields")
	_build_menu()
	_set_menu_page("home")
	_refresh_menu_ui()


func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)

	ui_sfx_player = AudioStreamPlayer.new()
	add_child(ui_sfx_player)
	ui_sfx_player.bus = "Master"
	if ResourceLoader.exists(UI_CLICK_SFX_PATH):
		ui_sfx_player.stream = load(UI_CLICK_SFX_PATH)

	menu_root = Control.new()
	menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(menu_root)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.09, 0.12)
	menu_root.add_child(bg)

	if ResourceLoader.exists(MENU_BACKDROP_PATH):
		var backdrop = TextureRect.new()
		backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
		backdrop.texture = load(MENU_BACKDROP_PATH)
		backdrop.stretch_mode = TextureRect.STRETCH_SCALE
		backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backdrop.modulate = Color(1.0, 1.0, 1.0, 0.76)
		menu_root.add_child(backdrop)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	menu_root.add_child(margin)

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.08, 0.12, 0.93), Color(0.36, 0.72, 0.88), 16))
	margin.add_child(panel)

	menu_scroll = ScrollContainer.new()
	menu_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_scroll.follow_focus = true
	panel.add_child(menu_scroll)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.add_child(vb)

	var title = Label.new()
	title.text = "BLUETH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0))
	vb.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Arena roguelike - 15 realm levels, 17-minute survival run"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.63, 0.88, 0.97))
	subtitle.add_theme_font_size_override("font_size", 20)
	vb.add_child(subtitle)

	hero_buttons.clear()
	realm_buttons.clear()
	meta_buttons_by_id.clear()
	shop_buttons_by_id.clear()

	home_page = VBoxContainer.new()
	(home_page as VBoxContainer).add_theme_constant_override("separation", 14)
	home_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(home_page)

	play_now_button = Button.new()
	play_now_button.text = "PLAY NOW"
	play_now_button.custom_minimum_size = Vector2(0, 88)
	play_now_button.add_theme_font_size_override("font_size", 28)
	_style_menu_button(play_now_button, Color(0.30, 0.79, 0.95), false)
	play_now_button.pressed.connect(_on_play_now_pressed)
	home_page.add_child(play_now_button)

	settings_button = Button.new()
	settings_button.text = "Settings"
	settings_button.custom_minimum_size = Vector2(0, 54)
	_style_menu_button(settings_button, Color(0.36, 0.83, 0.92), false)
	settings_button.pressed.connect(_on_settings_pressed)
	home_page.add_child(settings_button)

	home_bank_label = Label.new()
	home_bank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_bank_label.add_theme_font_size_override("font_size", 18)
	home_bank_label.add_theme_color_override("font_color", Color(0.58, 0.96, 0.84))
	home_page.add_child(home_bank_label)

	play_page = VBoxContainer.new()
	(play_page as VBoxContainer).add_theme_constant_override("separation", 12)
	play_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_page.visible = false
	vb.add_child(play_page)

	var select_title = Label.new()
	select_title.text = "Select Blueth Build"
	select_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_title.add_theme_font_size_override("font_size", 26)
	play_page.add_child(select_title)

	var hero_row_panel = PanelContainer.new()
	hero_row_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.13, 0.19, 0.86), Color(0.28, 0.63, 0.80), 12))
	play_page.add_child(hero_row_panel)

	var hero_row = GridContainer.new()
	hero_row.columns = 3
	hero_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_row.add_theme_constant_override("h_separation", 10)
	hero_row.add_theme_constant_override("v_separation", 10)
	hero_row_panel.add_child(hero_row)

	for i in range(hero_profiles.size()):
		var hero = hero_profiles[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 48.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = String(hero["name"]).replace("Blueth ", "")
		_style_menu_button(button, Color(0.29, 0.74, 0.90), false)
		button.pressed.connect(_on_hero_selected.bind(i))
		hero_row.add_child(button)
		hero_buttons.append(button)

	var hero_panel = PanelContainer.new()
	hero_panel.custom_minimum_size = Vector2(0.0, 220.0)
	hero_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.11, 0.17, 0.88), Color(0.31, 0.66, 0.84), 12))
	play_page.add_child(hero_panel)

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
	hero_tagline_label.custom_minimum_size = Vector2(0, 56)
	hero_tagline_label.add_theme_font_size_override("font_size", 18)
	hero_info_vb.add_child(hero_tagline_label)

	hero_weapon_label = Label.new()
	hero_weapon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_weapon_label.add_theme_color_override("font_color", Color(0.63, 0.90, 0.98))
	hero_weapon_label.add_theme_font_size_override("font_size", 17)
	hero_info_vb.add_child(hero_weapon_label)

	var realm_title = Label.new()
	realm_title.text = "Select Realm"
	realm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	realm_title.add_theme_font_size_override("font_size", 26)
	play_page.add_child(realm_title)

	var realm_row_panel = PanelContainer.new()
	realm_row_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.13, 0.19, 0.86), Color(0.35, 0.70, 0.87), 12))
	play_page.add_child(realm_row_panel)

	var realm_row = GridContainer.new()
	realm_row.columns = 2
	realm_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	realm_row.add_theme_constant_override("h_separation", 10)
	realm_row.add_theme_constant_override("v_separation", 10)
	realm_row_panel.add_child(realm_row)

	for i in range(realm_profiles.size()):
		var realm = realm_profiles[i]
		var realm_button = Button.new()
		realm_button.custom_minimum_size = Vector2(0.0, 44.0)
		realm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		realm_button.text = realm.get("name", "Realm")
		_style_menu_button(realm_button, Color(0.47, 0.74, 0.97), false)
		realm_button.pressed.connect(_on_realm_selected.bind(i))
		realm_row.add_child(realm_button)
		realm_buttons.append(realm_button)

	var realm_panel = PanelContainer.new()
	realm_panel.custom_minimum_size = Vector2(0.0, 118.0)
	realm_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.11, 0.17, 0.88), Color(0.37, 0.72, 0.89), 12))
	play_page.add_child(realm_panel)

	var realm_vb = VBoxContainer.new()
	realm_vb.add_theme_constant_override("separation", 4)
	realm_panel.add_child(realm_vb)

	realm_name_label = Label.new()
	realm_name_label.add_theme_font_size_override("font_size", 24)
	realm_vb.add_child(realm_name_label)

	realm_desc_label = Label.new()
	realm_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	realm_desc_label.custom_minimum_size = Vector2(0, 50)
	realm_desc_label.add_theme_font_size_override("font_size", 16)
	realm_vb.add_child(realm_desc_label)

	play_notice_label = Label.new()
	play_notice_label.text = "Choose a hero and realm, then start the run."
	play_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	play_notice_label.custom_minimum_size = Vector2(0, 58)
	play_notice_label.add_theme_font_size_override("font_size", 16)
	play_notice_label.add_theme_color_override("font_color", Color(0.89, 0.98, 1.0))
	play_page.add_child(play_notice_label)

	play_button = Button.new()
	play_button.text = "Start Run"
	play_button.custom_minimum_size = Vector2(0, 56)
	_style_menu_button(play_button, Color(0.30, 0.79, 0.95), false)
	play_button.pressed.connect(_on_play_pressed)
	play_page.add_child(play_button)

	var back_from_play = Button.new()
	back_from_play.text = "Back"
	back_from_play.custom_minimum_size = Vector2(0, 46)
	_style_menu_button(back_from_play, Color(0.75, 0.62, 0.40), false)
	back_from_play.pressed.connect(_on_back_to_home_pressed)
	play_page.add_child(back_from_play)

	settings_page = VBoxContainer.new()
	(settings_page as VBoxContainer).add_theme_constant_override("separation", 12)
	settings_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_page.visible = false
	vb.add_child(settings_page)

	var settings_title = Label.new()
	settings_title.text = "Settings"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_font_size_override("font_size", 26)
	settings_page.add_child(settings_title)

	settings_notice_label = Label.new()
	settings_notice_label.text = "Adjust accessibility and spend shards in the persistent skill tree."
	settings_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_notice_label.custom_minimum_size = Vector2(0, 54)
	settings_notice_label.add_theme_font_size_override("font_size", 15)
	settings_notice_label.add_theme_color_override("font_color", Color(0.89, 0.98, 1.0))
	settings_page.add_child(settings_notice_label)

	var tabs = TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(0.0, 560.0)
	settings_page.add_child(tabs)

	var skill_tab = VBoxContainer.new()
	skill_tab.name = "Skill Tree"
	skill_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(skill_tab as VBoxContainer).add_theme_constant_override("separation", 12)
	tabs.add_child(skill_tab)

	var meta_panel = PanelContainer.new()
	meta_panel.custom_minimum_size = Vector2(0.0, 270.0)
	meta_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.10, 0.15, 0.90), Color(0.44, 0.82, 0.93), 12))
	skill_tab.add_child(meta_panel)

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
	meta_summary_label.custom_minimum_size = Vector2(0, 40)
	meta_summary_label.add_theme_font_size_override("font_size", 15)
	meta_vb.add_child(meta_summary_label)

	achievements_label = Label.new()
	achievements_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievements_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	achievements_label.custom_minimum_size = Vector2(0, 42)
	achievements_label.add_theme_font_size_override("font_size", 14)
	achievements_label.add_theme_color_override("font_color", Color(0.76, 0.93, 1.0))
	meta_vb.add_child(achievements_label)

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
		_style_menu_button(node_button, Color(0.36, 0.83, 0.92), true)
		node_button.pressed.connect(_on_meta_upgrade_pressed.bind(node_id))
		meta_grid.add_child(node_button)
		meta_buttons_by_id[node_id] = node_button

	var shop_tab = VBoxContainer.new()
	shop_tab.name = "Shop"
	shop_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(shop_tab as VBoxContainer).add_theme_constant_override("separation", 12)
	tabs.add_child(shop_tab)

	var shop_panel = PanelContainer.new()
	shop_panel.custom_minimum_size = Vector2(0.0, 250.0)
	shop_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.10, 0.15, 0.90), Color(0.44, 0.82, 0.93), 12))
	shop_tab.add_child(shop_panel)

	var shop_vb = VBoxContainer.new()
	shop_vb.add_theme_constant_override("separation", 6)
	shop_panel.add_child(shop_vb)

	var shop_title = Label.new()
	shop_title.text = "Shop (Permanent Skills)"
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title.add_theme_font_size_override("font_size", 22)
	shop_vb.add_child(shop_title)

	var shop_hint = Label.new()
	shop_hint.text = "Spend shards to permanently start runs with these skills."
	shop_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_hint.custom_minimum_size = Vector2(0.0, 44.0)
	shop_hint.add_theme_font_size_override("font_size", 14)
	shop_hint.add_theme_color_override("font_color", Color(0.76, 0.93, 1.0))
	shop_vb.add_child(shop_hint)

	var shop_scroll = ScrollContainer.new()
	shop_scroll.custom_minimum_size = Vector2(0.0, 158.0)
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_vb.add_child(shop_scroll)

	var shop_grid = GridContainer.new()
	shop_grid.columns = 2
	shop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_grid.add_theme_constant_override("h_separation", 8)
	shop_grid.add_theme_constant_override("v_separation", 8)
	shop_scroll.add_child(shop_grid)

	for item in meta_progression.get_shop_items_for_ui():
		var item_id = String(item.get("id", ""))
		var item_button = Button.new()
		item_button.custom_minimum_size = Vector2(0.0, 74.0)
		item_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_button.clip_text = false
		_style_menu_button(item_button, Color(0.58, 0.96, 0.84), true)
		item_button.pressed.connect(_on_shop_item_pressed.bind(item_id))
		shop_grid.add_child(item_button)
		shop_buttons_by_id[item_id] = item_button

	var access_tab = VBoxContainer.new()
	access_tab.name = "Accessibility"
	access_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	access_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(access_tab as VBoxContainer).add_theme_constant_override("separation", 12)
	tabs.add_child(access_tab)

	var access_panel = PanelContainer.new()
	access_panel.custom_minimum_size = Vector2(0.0, 210.0)
	access_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.10, 0.15, 0.90), Color(0.44, 0.82, 0.93), 12))
	access_tab.add_child(access_panel)

	var access_vb = VBoxContainer.new()
	access_vb.add_theme_constant_override("separation", 8)
	access_panel.add_child(access_vb)

	var access_title = Label.new()
	access_title.text = "Accessibility"
	access_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	access_title.add_theme_font_size_override("font_size", 22)
	access_vb.add_child(access_title)

	var access_grid = GridContainer.new()
	access_grid.columns = 3
	access_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	access_grid.add_theme_constant_override("h_separation", 10)
	access_grid.add_theme_constant_override("v_separation", 10)
	access_vb.add_child(access_grid)

	var settings = meta_progression.get_settings()
	var music_default = int(round(float(settings.get("music_volume", 0.85)) * 100.0))
	var sfx_default = int(round(float(settings.get("sfx_volume", 1.0)) * 100.0))
	var flash_default = int(round(float(settings.get("flash_scale", 1.0)) * 100.0))
	var shake_default = int(round(float(settings.get("shake_scale", 1.0)) * 100.0))
	var bg_default = int(round(float(settings.get("bg_intensity", 1.0)) * 100.0))

	var music_row = _add_access_slider(access_grid, "Music", "music_volume", 0, 100, music_default)
	music_slider = music_row["slider"]
	music_value_label = music_row["value_label"]
	var sfx_row = _add_access_slider(access_grid, "SFX", "sfx_volume", 0, 100, sfx_default)
	sfx_slider = sfx_row["slider"]
	sfx_value_label = sfx_row["value_label"]
	var flash_row = _add_access_slider(access_grid, "Screen Flash", "flash_scale", 0, 100, flash_default)
	flash_slider = flash_row["slider"]
	flash_value_label = flash_row["value_label"]
	var shake_row = _add_access_slider(access_grid, "Camera Shake", "shake_scale", 0, 100, shake_default)
	shake_slider = shake_row["slider"]
	shake_value_label = shake_row["value_label"]
	var bg_row = _add_access_slider(access_grid, "Background", "bg_intensity", 40, 100, bg_default)
	bg_slider = bg_row["slider"]
	bg_value_label = bg_row["value_label"]

	var toggles = VBoxContainer.new()
	toggles.add_theme_constant_override("separation", 6)
	access_vb.add_child(toggles)

	show_enemy_hp_checkbox = CheckBox.new()
	show_enemy_hp_checkbox.text = "Show enemy HP bars"
	show_enemy_hp_checkbox.button_pressed = float(settings.get("show_enemy_hp", 0.0)) >= 0.5
	show_enemy_hp_checkbox.toggled.connect(_on_setting_checkbox_toggled.bind("show_enemy_hp"))
	toggles.add_child(show_enemy_hp_checkbox)

	show_boss_hp_checkbox = CheckBox.new()
	show_boss_hp_checkbox.text = "Show boss HP bar"
	show_boss_hp_checkbox.button_pressed = float(settings.get("show_boss_hp", 1.0)) >= 0.5
	show_boss_hp_checkbox.toggled.connect(_on_setting_checkbox_toggled.bind("show_boss_hp"))
	toggles.add_child(show_boss_hp_checkbox)

	show_damage_numbers_checkbox = CheckBox.new()
	show_damage_numbers_checkbox.text = "Show damage numbers + hit popups"
	show_damage_numbers_checkbox.button_pressed = float(settings.get("show_damage_numbers", 1.0)) >= 0.5
	show_damage_numbers_checkbox.toggled.connect(_on_setting_checkbox_toggled.bind("show_damage_numbers"))
	toggles.add_child(show_damage_numbers_checkbox)

	reduced_particles_checkbox = CheckBox.new()
	reduced_particles_checkbox.text = "Reduced particles (performance + comfort)"
	reduced_particles_checkbox.button_pressed = float(settings.get("reduced_particles", 0.0)) >= 0.5
	reduced_particles_checkbox.toggled.connect(_on_setting_checkbox_toggled.bind("reduced_particles"))
	toggles.add_child(reduced_particles_checkbox)

	var back_from_settings = Button.new()
	back_from_settings.text = "Back"
	back_from_settings.custom_minimum_size = Vector2(0, 46)
	_style_menu_button(back_from_settings, Color(0.75, 0.62, 0.40), false)
	back_from_settings.pressed.connect(_on_back_to_home_pressed)
	settings_page.add_child(back_from_settings)

	quit_button = Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(0, 46)
	_style_menu_button(quit_button, Color(0.75, 0.40, 0.52), false)
	quit_button.pressed.connect(_on_quit_pressed)
	quit_button.visible = not OS.has_feature("web")
	settings_page.add_child(quit_button)

	_build_result_overlay()


func _build_result_overlay() -> void:
	result_overlay = Control.new()
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_overlay.visible = false
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_root.add_child(result_overlay)

	var shade = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	result_overlay.add_child(shade)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_overlay.add_child(center)

	var panel = PanelContainer.new()
	# Give the results modal a real width so wrapped text doesn't collapse to a 1-column layout.
	panel.custom_minimum_size = Vector2(760.0, 340.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.08, 0.12, 0.96), Color(0.36, 0.72, 0.88), 16))
	center.add_child(panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vb)

	result_label = Label.new()
	result_label.text = ""
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.custom_minimum_size = Vector2(720.0, 200.0)
	result_label.add_theme_font_size_override("font_size", 18)
	result_label.add_theme_color_override("font_color", Color(0.89, 0.98, 1.0))
	vb.add_child(result_label)

	result_continue_button = Button.new()
	result_continue_button.text = "Continue"
	result_continue_button.custom_minimum_size = Vector2(0, 52)
	_style_menu_button(result_continue_button, Color(0.30, 0.79, 0.95), false)
	result_continue_button.pressed.connect(_on_result_continue_pressed)
	vb.add_child(result_continue_button)



func _add_access_slider(
	grid: GridContainer,
	label_text: String,
	setting_key: String,
	min_value: int,
	max_value: int,
	default_value: int
) -> Dictionary:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	grid.add_child(label)

	var slider = HSlider.new()
	slider.min_value = float(min_value)
	slider.max_value = float(max_value)
	slider.step = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = float(default_value)
	slider.value_changed.connect(_on_setting_slider_changed.bind(setting_key))
	grid.add_child(slider)

	var value_label = Label.new()
	value_label.text = "%d%%" % default_value
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(value_label)

	return {
		"slider": slider,
		"value_label": value_label
	}


func _make_panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_size = 6
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	return style


func _style_menu_button(button: Button, accent: Color, compact: bool) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.13, 0.19, 0.94)
	normal.border_color = accent
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2

	var hover = normal.duplicate()
	hover.bg_color = Color(0.11, 0.20, 0.29, 0.98)

	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.13, 0.25, 0.35, 0.98)

	var disabled = normal.duplicate()
	disabled.bg_color = Color(0.07, 0.09, 0.13, 0.86)
	disabled.border_color = Color(0.24, 0.34, 0.44, 0.74)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.94, 0.99, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.62, 0.72, 0.82))
	button.add_theme_font_size_override("font_size", 14 if compact else 18)


func _find_realm_index(realm_id: String) -> int:
	for i in range(realm_profiles.size()):
		var realm = realm_profiles[i]
		if String(realm.get("id", "")) == realm_id:
			return i
	return 0


func _first_unlocked_realm_index() -> int:
	for i in range(realm_profiles.size()):
		var realm_id = String(realm_profiles[i].get("id", ""))
		if meta_progression.is_realm_unlocked(realm_id):
			return i
	return 0


func _set_menu_page(page: String) -> void:
	if home_page == null or play_page == null or settings_page == null:
		return

	home_page.visible = page == "home"
	play_page.visible = page == "play"
	settings_page.visible = page == "settings"

	# Always reset scroll when changing pages so critical buttons never end up off-screen.
	if menu_scroll != null:
		menu_scroll.scroll_vertical = 0
		menu_scroll.scroll_horizontal = 0


func _on_play_now_pressed() -> void:
	_play_ui_click()
	_set_menu_page("play")
	if play_notice_label != null:
		play_notice_label.text = "Choose a hero and realm, then start the run."


func _on_settings_pressed() -> void:
	_play_ui_click()
	_set_menu_page("settings")
	if settings_notice_label != null:
		settings_notice_label.text = "Adjust accessibility and spend shards in the persistent skill tree."


func _on_back_to_home_pressed() -> void:
	_play_ui_click()
	_set_menu_page("home")


func _on_result_continue_pressed() -> void:
	_play_ui_click()
	if result_overlay != null:
		result_overlay.visible = false
	_set_menu_page("home")


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
	var selected_id = String(realm_profiles[selected_realm_index].get("id", ""))
	if not meta_progression.is_realm_unlocked(selected_id):
		selected_realm_index = _first_unlocked_realm_index()
	var realm = realm_profiles[selected_realm_index]

	for i in range(realm_buttons.size()):
		var realm_i = realm_profiles[i]
		var realm_id = String(realm_i.get("id", ""))
		var unlocked = meta_progression.is_realm_unlocked(realm_id)
		var button: Button = realm_buttons[i]
		var base_name = realm_i.get("name", "Realm")
		button.text = base_name if unlocked else "%s (Locked)" % base_name
		button.disabled = (i == selected_realm_index) or (not unlocked)

	realm_name_label.text = "Realm: %s" % realm.get("name", "Riftcore")
	var desc = String(realm.get("desc", ""))
	if String(realm.get("id", "")) == "endless":
		var record = meta_progression.get_endless_record()
		var best_time = float(record.get("best_time", 0.0))
		if best_time > 1.0:
			desc += "\nRecord: %s  Lv %d  Kills %d" % [
				_format_time_mmss(best_time),
				int(record.get("best_level", 0)),
				int(record.get("best_kills", 0))
			]
	realm_desc_label.text = desc


func _format_time_mmss(seconds: float) -> String:
	var total = int(seconds)
	var mm = int(float(total) / 60.0)
	var ss = int(total % 60)
	return "%02d:%02d" % [mm, ss]


func _refresh_meta_ui() -> void:
	var modifiers: Dictionary = meta_progression.get_run_modifiers()
	var hp_bonus = (float(modifiers.get("max_hp_mult", 1.0)) - 1.0) * 100.0
	var dmg_bonus = (float(modifiers.get("damage_mult", 1.0)) - 1.0) * 100.0
	var fire_bonus = (float(modifiers.get("fire_rate_mult", 1.0)) - 1.0) * 100.0
	var move_bonus = (float(modifiers.get("move_speed_mult", 1.0)) - 1.0) * 100.0
	var incoming_pct = float(modifiers.get("damage_taken_mult", 1.0)) * 100.0
	if home_bank_label != null:
		home_bank_label.text = "Bank Shards: %d" % meta_progression.get_shards()
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

	var ach_parts: Array = []
	for ach in meta_progression.get_achievements_for_ui():
		var unlocked = bool(ach.get("unlocked", false))
		var mark = "[x]" if unlocked else "[ ]"
		ach_parts.append("%s %s" % [mark, ach.get("name", "Achievement")])
	achievements_label.text = "Achievements: %s" % ", ".join(ach_parts)

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

	for item in meta_progression.get_shop_items_for_ui():
		var item_id = String(item.get("id", ""))
		if not shop_buttons_by_id.has(item_id):
			continue
		var item_button: Button = shop_buttons_by_id[item_id]
		var owned = bool(item.get("owned", false))
		var cost = int(item.get("cost", 0))
		var status = "OWNED" if owned else "Cost: %d shards" % cost
		item_button.text = "%s\n%s\n%s" % [
			item.get("name", "Skill"),
			item.get("desc", ""),
			status
		]
		item_button.disabled = owned or (not bool(item.get("can_buy", false)))


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
	var realm_id = ""
	if index >= 0 and index < realm_profiles.size():
		realm_id = String(realm_profiles[index].get("id", ""))
	if realm_id != "" and not meta_progression.is_realm_unlocked(realm_id):
		if play_notice_label != null:
			play_notice_label.text = "Realm locked. Clear earlier realms to unlock new realms (Endless unlocks after Umbra Vault)."
		return
	selected_realm_index = index
	_refresh_realm_ui()
	_refresh_play_button_text()


func _on_setting_slider_changed(value: float, setting_key: String) -> void:
	var pct = int(round(value))
	var normalized = clamp(float(pct) / 100.0, 0.0, 1.0)
	meta_progression.set_setting(setting_key, normalized)
	_set_slider_label(setting_key, pct)


func _on_setting_checkbox_toggled(pressed: bool, setting_key: String) -> void:
	meta_progression.set_setting(setting_key, 1.0 if pressed else 0.0)


func _play_ui_click() -> void:
	if ui_sfx_player == null or ui_sfx_player.stream == null:
		return
	if meta_progression == null:
		return

	var settings = meta_progression.get_settings()
	var sfx_volume = clamp(float(settings.get("sfx_volume", 1.0)), 0.0, 1.0)
	ui_sfx_player.volume_db = -12.0 + _linear_to_db_safe(sfx_volume)
	ui_sfx_player.pitch_scale = randf_range(0.98, 1.04)
	ui_sfx_player.play()


func _linear_to_db_safe(linear: float) -> float:
	if linear <= 0.001:
		return -80.0
	return linear_to_db(linear)


func _set_slider_label(setting_key: String, pct: int) -> void:
	var text = "%d%%" % pct
	match setting_key:
		"music_volume":
			if music_value_label != null:
				music_value_label.text = text
		"sfx_volume":
			if sfx_value_label != null:
				sfx_value_label.text = text
		"flash_scale":
			if flash_value_label != null:
				flash_value_label.text = text
		"shake_scale":
			if shake_value_label != null:
				shake_value_label.text = text
		"bg_intensity":
			if bg_value_label != null:
				bg_value_label.text = text

func _on_meta_upgrade_pressed(node_id: String) -> void:
	if run_active:
		return

	if meta_progression.upgrade_node(node_id):
		if settings_notice_label != null:
			settings_notice_label.text = "Meta upgrade purchased: %s" % node_id
	else:
		if settings_notice_label != null:
			settings_notice_label.text = "Not enough shards for that node yet."
	_refresh_meta_ui()


func _on_shop_item_pressed(item_id: String) -> void:
	if run_active:
		return

	var item_name = item_id
	for row in meta_progression.get_shop_items_for_ui():
		if String(row.get("id", "")) == item_id:
			item_name = String(row.get("name", item_id))
			break

	if meta_progression.buy_shop_item(item_id):
		if settings_notice_label != null:
			settings_notice_label.text = "Purchased shop skill: %s" % item_name
	else:
		if settings_notice_label != null:
			settings_notice_label.text = "Cannot buy that skill yet (owned or not enough shards)."
	_refresh_meta_ui()


func _on_play_pressed() -> void:
	_play_ui_click()
	_start_run()


func _on_quit_pressed() -> void:
	_play_ui_click()
	get_tree().quit()


func _start_run() -> void:
	if current_game != null:
		current_game.queue_free()

	if result_overlay != null:
		result_overlay.visible = false

	var hero = hero_profiles[selected_hero_index]
	var realm = realm_profiles[selected_realm_index]
	var run_modifiers = meta_progression.get_run_modifiers()
	var settings = meta_progression.get_settings()
	current_game = GameScript.new()
	current_game.setup_run({
		"hero_id": hero.get("id", "warden"),
		"realm_id": realm.get("id", "riftcore"),
		"meta": run_modifiers,
		"settings": settings
	})
	add_child(current_game)
	current_game.run_finished.connect(_on_run_finished)

	menu_layer.hide()
	run_active = true


func _on_run_finished(victory: bool, stats: Dictionary) -> void:
	if current_game != null:
		current_game.queue_free()
		current_game = null

	var aborted = bool(stats.get("aborted", false))
	var seconds = int(stats.get("time_survived", 0.0))
	var mm = int(float(seconds) / 60.0)
	var ss = int(seconds % 60)
	var time_text = "%02d:%02d" % [mm, ss]
	var realm_id = String(stats.get("realm_id", realm_profiles[selected_realm_index].get("id", "frostfields")))
	var is_endless = realm_id == "endless"
	var verdict = "Abandoned" if aborted else ("Victory" if victory else ("Endless Run Over" if is_endless else "Defeat"))

	var mastery_earned = 0
	if not aborted:
		mastery_earned = max(0, int(stats.get("mastery_earned", 0)))
		meta_progression.add_shards(mastery_earned)

	var unlock_info: Dictionary = {}
	if victory and not aborted:
		unlock_info = meta_progression.on_realm_victory(realm_id)
		var unlocked_realm = String(unlock_info.get("unlocked_realm", ""))
		if unlocked_realm != "":
			selected_realm_index = _find_realm_index(unlocked_realm)

	var extra_lines: Array = []
	if aborted:
		extra_lines.append("No shards gained (run abandoned).")

	var boss_bounties = int(stats.get("boss_bounties", 0))
	if (not aborted) and boss_bounties > 0:
		extra_lines.append("Boss bounties: +%d shards" % boss_bounties)

	if victory and not unlock_info.is_empty():
		var bonus = int(unlock_info.get("bonus_shards", 0))
		if bonus > 0:
			extra_lines.append("Realm clear bonus: +%d shards" % bonus)
		var unlocked_id = String(unlock_info.get("unlocked_realm", ""))
		if unlocked_id != "":
			var unlocked_name = DataScript.realm_by_id(unlocked_id).get("name", unlocked_id)
			extra_lines.append("New realm unlocked: %s" % unlocked_name)
		var new_achs: Array = unlock_info.get("new_achievements", [])
		for ach_id in new_achs:
			var ach_name = MetaProgressionScript.ACHIEVEMENTS.get(ach_id, {}).get("name", String(ach_id))
			extra_lines.append("Achievement unlocked: %s" % ach_name)

	if is_endless and (not aborted):
		if meta_progression.submit_endless_record(float(stats.get("time_survived", 0.0)), int(stats.get("level", 1)), int(stats.get("kills", 0))):
			extra_lines.append("New Endless record!")

	var total_shards = meta_progression.get_shards()
	var extra_text = ("\n" + "\n".join(extra_lines)) if not extra_lines.is_empty() else ""
	result_label.text = "%s\nHero: %s\nRealm: %s\nWeapon: %s\nTime: %s  Level: %d  Kills: %d\nMastery gained: +%d (Bank: %d)%s" % [
		verdict,
		stats.get("hero", "Blueth"),
		stats.get("realm", "Riftcore"),
		stats.get("weapon", "Unknown"),
		time_text,
		int(stats.get("level", 1)),
		int(stats.get("kills", 0)),
		mastery_earned,
		total_shards,
		extra_text
	]

	_refresh_meta_ui()
	_refresh_realm_ui()
	_refresh_play_button_text()
	_set_menu_page("home")
	menu_layer.show()
	if result_overlay != null:
		result_overlay.visible = true
	run_active = false
