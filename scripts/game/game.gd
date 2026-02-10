extends Node2D
class_name BluethGame

signal run_finished(victory: bool, stats: Dictionary)

const PlayerScript = preload("res://scripts/entities/player.gd")
const EnemyScript = preload("res://scripts/entities/enemy.gd")
const ProjectileScript = preload("res://scripts/entities/projectile.gd")
const XpOrbScript = preload("res://scripts/entities/xp_orb.gd")
const DataScript = preload("res://scripts/game/data.gd")

const ARENA_SIZE = Vector2(2200, 1300)
const RUN_DURATION = 1020.0
const MAX_REALM_LEVEL = 15
const LEVEL_TIME_GATES = [
	0.0,
	45.0,
	95.0,
	150.0,
	210.0,
	275.0,
	345.0,
	420.0,
	500.0,
	585.0,
	675.0,
	770.0,
	860.0,
	940.0,
	990.0
]

const ENEMY_POOL_SIZE = 280
const PROJECTILE_POOL_SIZE = 420
const ORB_POOL_SIZE = 380
const MAX_ACTIVE_ENEMIES = 220

const MUSIC_PATH = "res://assets/audio/music_loop.wav"
const SFX_PATHS = {
	"shotgun": "res://assets/audio/sfx_shotgun.wav",
	"beam": "res://assets/audio/sfx_beam.wav",
	"boomerang": "res://assets/audio/sfx_boomerang.wav",
	"surge": "res://assets/audio/sfx_surge.wav",
	"hit": "res://assets/audio/sfx_hit.wav",
	"levelup": "res://assets/audio/sfx_levelup.wav",
	"death": "res://assets/audio/sfx_death.wav"
}

const UPGRADES = [
	{"id": "damage", "title": "Kinetic Core", "desc": "+16% base damage"},
	{"id": "fire_rate", "title": "Pulse Trigger", "desc": "+15% fire rate"},
	{"id": "move_speed", "title": "Skate Pads", "desc": "+11% move speed"},
	{"id": "max_hp", "title": "Reinforced Gel", "desc": "+24 max HP and heal"},
	{"id": "magnet", "title": "Flux Magnet", "desc": "+36 pickup magnet radius"},
	{"id": "projectile_speed", "title": "Compressed Air", "desc": "+14% projectile speed"},
	{"id": "pierce", "title": "Phase Tips", "desc": "+1 piercing power"},
	{"id": "surge_damage", "title": "Overcharge", "desc": "+24% Flow Surge damage"},
	{"id": "surge_cycle", "title": "Drift Battery", "desc": "Flow Surge triggers 16% sooner"},
	{"id": "surge_radius", "title": "Expanding Ring", "desc": "+14% surge radius"},
	{"id": "surge_frost", "title": "Cryo Pattern", "desc": "Stronger and longer surge slow"},
	{"id": "regen_field", "title": "Recovery Field", "desc": "+0.6 HP/sec regen"},
	{"id": "leech_gel", "title": "Leech Gel", "desc": "Heal 1.4 HP on every kill"},
	{"id": "armor_mesh", "title": "Armor Mesh", "desc": "Take 8% less incoming damage"},
	{"id": "crit_chip", "title": "Crit Chip", "desc": "+7% crit chance"},
	{"id": "crit_amp", "title": "Crit Amplifier", "desc": "+26% crit multiplier"},
	{"id": "lucky_draft", "title": "Draft Overflow", "desc": "+1 upgrade option per draft"},
	{"id": "core_hack", "title": "Core Hack", "desc": "Core overload grants stronger overclock"},
	{"id": "core_gain", "title": "Shard Funnel", "desc": "+18% core charge gain"},
	{"id": "mastery_boost", "title": "Shard Speculation", "desc": "+20% mastery shard reward"},
	{"id": "duplicate_shot", "title": "Echo Fire", "desc": "+8% chance to duplicate attacks"},
	{"id": "weapon_overclock", "title": "Weapon Overclock", "desc": "+10% fire rate and +1 pierce"},
	{"id": "beam_width", "title": "Lens Array", "desc": "+8 beam width", "weapons": ["beam"]},
	{"id": "beam_chain", "title": "Line Fracture", "desc": "Beam hits +1 additional enemy", "weapons": ["beam"]},
	{"id": "shotgun_pellets", "title": "Extra Shell", "desc": "+1 shotgun pellet", "weapons": ["shotgun"]},
	{"id": "shotgun_blast", "title": "Blast Choke", "desc": "+15% shotgun pellet damage", "weapons": ["shotgun"]},
	{"id": "boomerang_cycles", "title": "Echo Edge", "desc": "+1 boomerang hit cycle", "weapons": ["boomerang"]},
	{"id": "boomerang_cap", "title": "Twin Arc", "desc": "+1 max active boomerang", "weapons": ["boomerang"]},
	{"id": "frost_bulwark", "title": "Frost Bulwark", "desc": "+40 HP and +0.5 regen", "realms": ["frostfields"]},
	{"id": "rift_greed", "title": "Rift Greed", "desc": "+35% core gain, -6% HP", "realms": ["riftcore"]},
	{"id": "void_pact", "title": "Void Pact", "desc": "+38% damage, +14% incoming damage", "realms": ["umbra_vault"]},
	{"id": "void_frenzy", "title": "Void Frenzy", "desc": "+22% fire rate, +10% incoming damage", "realms": ["umbra_vault"]}
]

var run_config = {
	"hero_id": "warden",
	"realm_id": "riftcore",
	"meta": {}
}

var selected_hero: Dictionary = {}
var selected_realm: Dictionary = {}
var realm_mods: Dictionary = {}
var meta_mods: Dictionary = {}

var arena_rect = Rect2(Vector2.ZERO, ARENA_SIZE)

var world_root: Node2D
var player
var camera: Camera2D

var enemy_pool: Array = []
var projectile_pool: Array = []
var orb_pool: Array = []

var active_enemies: Array = []
var active_projectiles: Array = []
var active_orbs: Array = []

var enemy_pool_cursor = -1
var projectile_pool_cursor = -1
var orb_pool_cursor = -1

var elapsed_time = 0.0
var spawn_timer = 1.20
var fire_timer = 0.0
var cleanup_timer = 0.35

var level = 1
var core_charge = 0.0
var core_charge_next = 52.0
var kills = 0

var ended = false
var paused_for_upgrade = false
var pending_upgrade_queue: Array = []
var current_upgrade_reason = ""
var upgrade_options: Array = []

var draft_choices = 4
var beam_width_bonus = 0.0
var bonus_beam_hits = 0
var shotgun_pellet_bonus = 0
var shotgun_damage_multiplier = 1.0
var boomerang_cycles_bonus = 0
var bonus_boomerang_cap = 0

var crit_chance = 0.04
var crit_multiplier = 1.55
var kill_heal_flat = 0.0
var duplicate_shot_chance = 0.0

var core_gain_multiplier = 1.0
var mastery_gain_multiplier = 1.0

var overclock_timer = 0.0
var overclock_fire_bonus = 0.0
var overclock_duration_bonus = 0.0

var surge_effects: Array = []
var beam_effects: Array = []
var muzzle_effects: Array = []

var hud_layer: CanvasLayer
var hero_label: Label
var realm_label: Label
var weapon_label: Label
var health_label: Label
var level_label: Label
var timer_label: Label
var enemies_label: Label
var fps_label: Label
var core_label: Label
var core_bar: ProgressBar
var hint_label: Label

var upgrade_panel: PanelContainer
var upgrade_title: Label
var upgrade_buttons: Array = []

var music_player: AudioStreamPlayer
var sfx_streams = {}
var sfx_players: Array = []
var sfx_cursor = -1
var hit_sfx_cooldown = 0.0


func setup_run(config: Dictionary) -> void:
	run_config = config.duplicate(true)


func _ready() -> void:
	randomize()
	selected_hero = DataScript.hero_by_id(String(run_config.get("hero_id", "warden")))
	selected_realm = DataScript.realm_by_id(String(run_config.get("realm_id", "riftcore")))
	realm_mods = selected_realm.get("mods", {}).duplicate(true)
	meta_mods = run_config.get("meta", {}).duplicate(true)

	_build_world()
	_build_audio()
	_build_hud()
	_spawn_player()
	_apply_meta_modifiers()
	_warm_pools()
	_sync_hud()
	queue_redraw()


func _build_world() -> void:
	world_root = Node2D.new()
	add_child(world_root)


func _build_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return

	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	if ResourceLoader.exists(MUSIC_PATH):
		music_player.stream = load(MUSIC_PATH)
		music_player.volume_db = -20.0
		music_player.play()

	sfx_streams.clear()
	for sfx_name in SFX_PATHS.keys():
		var sfx_path = SFX_PATHS[sfx_name]
		if ResourceLoader.exists(sfx_path):
			sfx_streams[sfx_name] = load(sfx_path)

	for i in range(16):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "Master"
		add_child(sfx_player)
		sfx_players.append(sfx_player)


func _play_sfx(sfx_name: String, volume_db: float = -9.0) -> void:
	if not sfx_streams.has(sfx_name) or sfx_players.is_empty():
		return

	sfx_cursor = (sfx_cursor + 1) % sfx_players.size()
	var player_node: AudioStreamPlayer = sfx_players[sfx_cursor]
	player_node.stream = sfx_streams[sfx_name]
	player_node.volume_db = volume_db
	player_node.pitch_scale = randf_range(0.96, 1.05)
	player_node.play()


func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 20
	add_child(hud_layer)

	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(root)

	var top_panel = PanelContainer.new()
	top_panel.anchor_left = 0.0
	top_panel.anchor_top = 0.0
	top_panel.anchor_right = 1.0
	top_panel.anchor_bottom = 0.0
	top_panel.offset_left = 14.0
	top_panel.offset_top = 14.0
	top_panel.offset_right = -14.0
	top_panel.offset_bottom = 118.0
	root.add_child(top_panel)

	var top_vb = VBoxContainer.new()
	top_vb.add_theme_constant_override("separation", 4)
	top_panel.add_child(top_vb)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 16)
	top_vb.add_child(row1)

	hero_label = Label.new()
	hero_label.add_theme_font_size_override("font_size", 21)
	row1.add_child(hero_label)

	realm_label = Label.new()
	realm_label.add_theme_font_size_override("font_size", 21)
	row1.add_child(realm_label)

	weapon_label = Label.new()
	weapon_label.add_theme_font_size_override("font_size", 21)
	row1.add_child(weapon_label)

	health_label = Label.new()
	health_label.add_theme_font_size_override("font_size", 21)
	row1.add_child(health_label)

	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 16)
	top_vb.add_child(row2)

	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 19)
	row2.add_child(level_label)

	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 19)
	row2.add_child(timer_label)

	enemies_label = Label.new()
	enemies_label.add_theme_font_size_override("font_size", 19)
	row2.add_child(enemies_label)

	core_label = Label.new()
	core_label.add_theme_font_size_override("font_size", 19)
	row2.add_child(core_label)

	fps_label = Label.new()
	fps_label.add_theme_font_size_override("font_size", 19)
	row2.add_child(fps_label)

	core_bar = ProgressBar.new()
	core_bar.anchor_left = 0.16
	core_bar.anchor_right = 0.84
	core_bar.anchor_top = 1.0
	core_bar.anchor_bottom = 1.0
	core_bar.offset_top = -34.0
	core_bar.offset_bottom = -14.0
	core_bar.min_value = 0.0
	core_bar.show_percentage = false
	root.add_child(core_bar)

	hint_label = Label.new()
	hint_label.anchor_left = 0.0
	hint_label.anchor_top = 1.0
	hint_label.anchor_right = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_top = -74.0
	hint_label.offset_bottom = -46.0
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.text = "Realm levels are time-gated. Core charge from kills grants bonus drafts and overclock spikes."
	hint_label.add_theme_color_override("font_color", Color(0.60, 0.92, 1.0))
	root.add_child(hint_label)

	upgrade_panel = PanelContainer.new()
	upgrade_panel.anchor_left = 0.5
	upgrade_panel.anchor_top = 0.5
	upgrade_panel.anchor_right = 0.5
	upgrade_panel.anchor_bottom = 0.5
	upgrade_panel.offset_left = -380.0
	upgrade_panel.offset_top = -250.0
	upgrade_panel.offset_right = 380.0
	upgrade_panel.offset_bottom = 250.0
	upgrade_panel.visible = false
	upgrade_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(upgrade_panel)

	var upgrade_vb = VBoxContainer.new()
	upgrade_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upgrade_vb.add_theme_constant_override("separation", 10)
	upgrade_panel.add_child(upgrade_vb)

	upgrade_title = Label.new()
	upgrade_title.text = "Choose Upgrade"
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_title.add_theme_font_size_override("font_size", 30)
	upgrade_vb.add_child(upgrade_title)

	for i in range(6):
		var button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 70.0)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_on_upgrade_selected.bind(i))
		upgrade_vb.add_child(button)
		upgrade_buttons.append(button)


func _spawn_player() -> void:
	player = PlayerScript.new()
	player.apply_hero(selected_hero)
	world_root.add_child(player)
	player.global_position = arena_rect.get_center()
	player.set_arena_rect(arena_rect)
	player.died.connect(_on_player_died)
	player.hp_changed.connect(_on_player_hp_changed)
	player.surge_triggered.connect(_on_player_surge_triggered)

	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = int(arena_rect.position.x)
	camera.limit_top = int(arena_rect.position.y)
	camera.limit_right = int(arena_rect.end.x)
	camera.limit_bottom = int(arena_rect.end.y)
	player.add_child(camera)


func _apply_meta_modifiers() -> void:
	player.max_hp *= float(meta_mods.get("max_hp_mult", 1.0))
	player.current_hp = player.max_hp
	player.damage *= float(meta_mods.get("damage_mult", 1.0))
	player.fire_rate *= float(meta_mods.get("fire_rate_mult", 1.0))
	player.move_speed *= float(meta_mods.get("move_speed_mult", 1.0))
	player.damage_taken_multiplier *= float(meta_mods.get("damage_taken_mult", 1.0))
	player.regen_per_second += float(meta_mods.get("regen_per_sec", 0.0))
	player.surge_damage *= float(meta_mods.get("surge_damage_mult", 1.0))

	core_gain_multiplier *= float(meta_mods.get("core_gain_mult", 1.0))
	mastery_gain_multiplier *= float(meta_mods.get("mastery_gain_mult", 1.0))
	duplicate_shot_chance += float(meta_mods.get("duplicate_attack_chance", 0.0))
	draft_choices += int(meta_mods.get("extra_draft_choices", 0))
	draft_choices = clamp(draft_choices, 3, 6)


func _warm_pools() -> void:
	for i in range(ENEMY_POOL_SIZE):
		var enemy = EnemyScript.new()
		enemy.died.connect(_on_enemy_died)
		world_root.add_child(enemy)
		enemy_pool.append(enemy)

	for i in range(PROJECTILE_POOL_SIZE):
		var projectile = ProjectileScript.new()
		world_root.add_child(projectile)
		projectile_pool.append(projectile)

	for i in range(ORB_POOL_SIZE):
		var orb = XpOrbScript.new()
		orb.collected.connect(_on_orb_collected)
		world_root.add_child(orb)
		orb_pool.append(orb)


func _physics_process(delta: float) -> void:
	if ended:
		return

	if paused_for_upgrade:
		_sync_hud()
		return

	hit_sfx_cooldown = max(0.0, hit_sfx_cooldown - delta)
	overclock_timer = max(0.0, overclock_timer - delta)

	elapsed_time += delta
	if elapsed_time >= RUN_DURATION:
		elapsed_time = RUN_DURATION
		_finish_run(true)
		return

	_update_level_progression()
	_update_spawning(delta)
	_update_auto_fire(delta)

	cleanup_timer -= delta
	if cleanup_timer <= 0.0:
		cleanup_timer = 0.35
		_prune_inactive(active_enemies)
		_prune_inactive(active_projectiles)
		_prune_inactive(active_orbs)

	_sync_hud()


func _process(delta: float) -> void:
	if ended:
		return

	if not paused_for_upgrade:
		_tick_effects(surge_effects, delta)
		_tick_effects(beam_effects, delta)
		_tick_effects(muzzle_effects, delta)
		if not surge_effects.is_empty() or not beam_effects.is_empty() or not muzzle_effects.is_empty():
			queue_redraw()

	if music_player != null and music_player.stream != null and not music_player.playing:
		music_player.play()

	fps_label.text = "FPS %d" % Engine.get_frames_per_second()


func _tick_effects(effects: Array, delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		var fx: Dictionary = effects[i]
		fx["time"] = float(fx["time"]) + delta
		effects[i] = fx
		if float(fx["time"]) >= float(fx["duration"]):
			effects.remove_at(i)


func _draw() -> void:
	var bg_color = realm_mods.get("bg_color", Color(0.08, 0.17, 0.22))
	var grid_color = realm_mods.get("grid_color", Color(1, 1, 1, 0.035))

	draw_rect(arena_rect, bg_color, true)
	draw_rect(arena_rect, Color(0.14, 0.34, 0.44), false, 8.0)

	var spacing = 96
	for x in range(spacing, int(ARENA_SIZE.x), spacing):
		draw_line(Vector2(x, 0), Vector2(x, ARENA_SIZE.y), grid_color, 1.0)
	for y in range(spacing, int(ARENA_SIZE.y), spacing):
		draw_line(Vector2(0, y), Vector2(ARENA_SIZE.x, y), grid_color, 1.0)

	for fx in beam_effects:
		var ratio = clamp(float(fx["time"]) / float(fx["duration"]), 0.0, 1.0)
		var alpha = 1.0 - ratio
		var width = float(fx["width"]) * (1.0 - ratio * 0.3)
		draw_line(fx["from"], fx["to"], Color(0.72, 0.97, 1.0, alpha), width)

	for fx in surge_effects:
		var duration = float(fx["duration"])
		var time = float(fx["time"])
		var ratio = clamp(time / duration, 0.0, 1.0)
		var max_radius = float(fx["radius"])
		var radius = lerp(max_radius * 0.22, max_radius, ratio)
		var alpha = 1.0 - ratio
		draw_arc(fx["origin"], radius, 0.0, TAU, 52, Color(0.50, 0.90, 1.0, alpha), 4.0)

	for fx in muzzle_effects:
		var ratio = clamp(float(fx["time"]) / float(fx["duration"]), 0.0, 1.0)
		var alpha = 0.6 * (1.0 - ratio)
		var radius = lerp(20.0, 40.0, ratio)
		draw_arc(fx["origin"], radius, fx["angle"] - 0.25, fx["angle"] + 0.25, 10, Color(0.90, 0.96, 1.0, alpha), 4.0)


func _update_level_progression() -> void:
	while level < MAX_REALM_LEVEL:
		var next_level = level + 1
		var gate_time = float(LEVEL_TIME_GATES[next_level - 1])
		if elapsed_time < gate_time:
			break
		level = next_level
		_queue_upgrade("level")
		_play_sfx("levelup", -8.0)


func _queue_upgrade(reason: String) -> void:
	pending_upgrade_queue.append(reason)
	if not paused_for_upgrade:
		_open_next_upgrade_panel()


func _update_spawning(delta: float) -> void:
	spawn_timer -= delta
	var safety = 0
	while spawn_timer <= 0.0 and safety < 4:
		safety += 1
		spawn_timer += _current_spawn_interval()
		_spawn_enemy_batch()


func _current_spawn_interval() -> float:
	var base = 1.45 - float(level - 1) * 0.07
	base -= elapsed_time * 0.00022
	base *= float(realm_mods.get("spawn_interval", 1.0))
	return clamp(base, 0.20, 2.0)


func _enemy_cap() -> int:
	var base_cap = 50 + level * 10 + int(elapsed_time * 0.03)
	return min(MAX_ACTIVE_ENEMIES, base_cap)


func _spawn_enemy_batch() -> void:
	if active_enemies.size() >= _enemy_cap():
		return

	var batch_size = 1 + int(float(level - 1) / 4.0)
	if randf() < (0.20 + float(level - 1) * 0.015):
		batch_size += 1
	if level >= 11 and randf() < 0.16:
		batch_size += 1

	for i in range(batch_size):
		if active_enemies.size() >= _enemy_cap():
			return

		var enemy = _acquire_enemy()
		if enemy == null:
			return

		var elite_chance = (0.02 + float(level - 1) * 0.014) * float(realm_mods.get("elite_rate", 1.0))
		var elite = randf() < min(0.34, elite_chance)
		var cfg = _enemy_config(elite)
		enemy.activate(_random_spawn_position(), player, cfg)
		active_enemies.append(enemy)


func _enemy_config(elite: bool) -> Dictionary:
	var progression = float(level - 1) / float(MAX_REALM_LEVEL - 1)
	var hp = lerp(20.0, 150.0, progression) + elapsed_time * 0.055
	var speed = lerp(62.0, 132.0, progression)
	var damage = lerp(3.0, 17.0, progression)
	var xp = lerp(4.5, 22.0, progression)
	var radius = 14.0
	var scale_factor = 1.0

	hp *= float(realm_mods.get("enemy_hp", 1.0))
	speed *= float(realm_mods.get("enemy_speed", 1.0))
	damage *= float(realm_mods.get("enemy_damage", 1.0))

	if elite:
		hp *= 2.9
		speed *= 1.13
		damage *= 1.60
		xp *= 2.8
		radius = 18.0
		scale_factor = 1.2

	return {
		"hp": hp,
		"speed": speed,
		"damage": damage,
		"xp": xp,
		"radius": radius,
		"elite": elite,
		"scale": scale_factor
	}


func _random_spawn_position() -> Vector2:
	var angle = randf() * TAU
	var distance = randf_range(470.0, 760.0)
	var pos = player.global_position + Vector2.RIGHT.rotated(angle) * distance
	pos.x = clamp(pos.x, arena_rect.position.x + 22.0, arena_rect.end.x - 22.0)
	pos.y = clamp(pos.y, arena_rect.position.y + 22.0, arena_rect.end.y - 22.0)
	return pos


func _effective_fire_rate() -> float:
	var bonus = 1.0
	if overclock_timer > 0.0:
		bonus += 0.34 + overclock_fire_bonus
	return player.fire_rate * bonus


func _update_auto_fire(delta: float) -> void:
	fire_timer -= delta
	var safety = 0
	while fire_timer <= 0.0 and safety < 6:
		safety += 1
		fire_timer += 1.0 / max(0.2, _effective_fire_rate())
		var target = _find_nearest_enemy(player.global_position)
		if target == null:
			continue

		_fire_weapon(target.global_position)
		if randf() < duplicate_shot_chance:
			_fire_weapon(target.global_position)


func _fire_weapon(target_position: Vector2) -> void:
	match player.weapon_type:
		"shotgun":
			_fire_shotgun(target_position)
		"beam":
			_fire_beam(target_position)
		"boomerang":
			_fire_boomerang(target_position)
		_:
			_fire_single(target_position)


func _rolled_damage(base_damage: float) -> float:
	var out = base_damage
	if randf() < crit_chance:
		out *= crit_multiplier
	return out


func _fire_single(target_position: Vector2) -> void:
	var direction = (target_position - player.global_position).normalized()
	_spawn_projectile({
		"mode": "bullet",
		"origin": player.global_position + direction * 26.0,
		"direction": direction,
		"speed": player.projectile_speed,
		"damage": _rolled_damage(player.damage),
		"hits": max(1, player.projectile_pierce + 1),
		"radius": 4.0 * player.projectile_scale,
		"lifetime": 1.55,
		"world_rect": arena_rect
	})


func _fire_shotgun(target_position: Vector2) -> void:
	var base_direction = (target_position - player.global_position).normalized()
	var pellet_count = 5 + shotgun_pellet_bonus
	var spread = 0.46
	for i in range(pellet_count):
		var t = 0.5
		if pellet_count > 1:
			t = float(i) / float(pellet_count - 1)
		var angle_offset = lerp(-spread * 0.5, spread * 0.5, t) + randf_range(-0.045, 0.045)
		var dir = base_direction.rotated(angle_offset)
		_spawn_projectile({
			"mode": "bullet",
			"origin": player.global_position + dir * 24.0,
			"direction": dir,
			"speed": player.projectile_speed * randf_range(0.95, 1.06),
			"damage": _rolled_damage(player.damage * 0.43 * shotgun_damage_multiplier),
			"hits": max(1, player.projectile_pierce + 1),
			"radius": 3.3 * player.projectile_scale,
			"lifetime": 1.06,
			"world_rect": arena_rect
		})

	muzzle_effects.append({
		"origin": player.global_position + base_direction * 22.0,
		"angle": base_direction.angle(),
		"time": 0.0,
		"duration": 0.10
	})
	_play_sfx("shotgun", -10.0)


func _fire_beam(target_position: Vector2) -> void:
	var origin = player.global_position
	var direction = (target_position - origin).normalized()
	var beam_range = 420.0 + player.projectile_speed * 0.08
	var beam_width = 18.0 + beam_width_bonus
	var max_hits = 2 + player.projectile_pierce + bonus_beam_hits

	var hits: Array = []
	for enemy in active_enemies:
		if not enemy.is_active:
			continue
		var to_enemy = enemy.global_position - origin
		var along = to_enemy.dot(direction)
		if along < 0.0 or along > beam_range:
			continue
		var closest = origin + direction * along
		var allowance = beam_width + enemy.radius
		if enemy.global_position.distance_squared_to(closest) <= allowance * allowance:
			hits.append({"enemy": enemy, "along": along})

	if not hits.is_empty():
		hits.sort_custom(Callable(self, "_sort_hit_entries"))
		var hit_count = min(max_hits, hits.size())
		for i in range(hit_count):
			var hit = hits[i]
			var enemy = hit["enemy"]
			var along = float(hit["along"])
			var falloff = lerp(1.0, 0.74, clamp(along / beam_range, 0.0, 1.0))
			enemy.apply_projectile_hit(_rolled_damage(player.damage * 1.12 * falloff))

	beam_effects.append({
		"from": origin + direction * 20.0,
		"to": origin + direction * beam_range,
		"width": beam_width,
		"time": 0.0,
		"duration": 0.12
	})
	_play_sfx("beam", -8.5)


func _sort_hit_entries(a: Dictionary, b: Dictionary) -> bool:
	return float(a["along"]) < float(b["along"])


func _fire_boomerang(target_position: Vector2) -> void:
	var existing = _count_active_projectiles_mode("boomerang")
	var max_boomerangs = 1 + int(player.projectile_pierce / 3) + bonus_boomerang_cap
	if existing >= max_boomerangs:
		return

	var spawn_count = min(max_boomerangs - existing, 2)
	var base_direction = (target_position - player.global_position).normalized()
	for i in range(spawn_count):
		var offset = 0.0
		if spawn_count == 2:
			offset = -0.14 if i == 0 else 0.14
		var dir = base_direction.rotated(offset)
		_spawn_projectile({
			"mode": "boomerang",
			"origin": player.global_position + dir * 22.0,
			"direction": dir,
			"speed": max(390.0, player.projectile_speed * 0.84),
			"damage": _rolled_damage(player.damage * 0.92),
			"hits": 7 + player.projectile_pierce * 2 + boomerang_cycles_bonus * 3,
			"radius": 8.0,
			"lifetime": 1.80,
			"owner": player,
			"boomerang_outbound_time": 0.44,
			"world_rect": arena_rect
		})

	_play_sfx("boomerang", -8.0)


func _spawn_projectile(config: Dictionary) -> void:
	var projectile = _acquire_projectile()
	if projectile == null:
		return
	projectile.activate(config)
	active_projectiles.append(projectile)


func _count_active_projectiles_mode(mode: String) -> int:
	var count = 0
	for projectile in active_projectiles:
		if projectile.is_active and String(projectile.projectile_mode) == mode:
			count += 1
	return count


func _find_nearest_enemy(origin: Vector2):
	var nearest = null
	var best_distance_sq = INF
	for enemy in active_enemies:
		if not enemy.is_active:
			continue
		var distance_sq = origin.distance_squared_to(enemy.global_position)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			nearest = enemy
	return nearest


func _acquire_enemy():
	var size = enemy_pool.size()
	for i in range(size):
		enemy_pool_cursor = (enemy_pool_cursor + 1) % size
		var candidate = enemy_pool[enemy_pool_cursor]
		if not candidate.is_active:
			return candidate
	return null


func _acquire_projectile():
	var size = projectile_pool.size()
	for i in range(size):
		projectile_pool_cursor = (projectile_pool_cursor + 1) % size
		var candidate = projectile_pool[projectile_pool_cursor]
		if not candidate.is_active:
			return candidate
	return null


func _acquire_orb():
	var size = orb_pool.size()
	for i in range(size):
		orb_pool_cursor = (orb_pool_cursor + 1) % size
		var candidate = orb_pool[orb_pool_cursor]
		if not candidate.is_active:
			return candidate
	return null


func _on_enemy_died(_enemy, drop_position: Vector2, xp_value: float) -> void:
	if ended:
		return

	kills += 1
	if kill_heal_flat > 0.0:
		player.heal(kill_heal_flat)

	if hit_sfx_cooldown <= 0.0:
		hit_sfx_cooldown = 0.06
		_play_sfx("hit", -15.0)

	var orb = _acquire_orb()
	if orb != null:
		orb.activate(drop_position, player, xp_value)
		active_orbs.append(orb)


func _on_orb_collected(_orb, value: float) -> void:
	if ended:
		return

	var gain = value * core_gain_multiplier
	if overclock_timer > 0.0:
		gain *= 1.20
	core_charge += gain

	var overload_count = 0
	while core_charge >= core_charge_next:
		core_charge -= core_charge_next
		core_charge_next = min(260.0, core_charge_next * 1.14 + 8.0)
		overclock_timer = max(overclock_timer, 8.0 + overclock_duration_bonus)
		overload_count += 1
		_queue_upgrade("core")

	if overload_count > 0:
		_play_sfx("levelup", -10.0)

	_sync_hud()


func _on_player_hp_changed(_current_hp: float, _max_hp: float) -> void:
	_sync_hud()


func _on_player_died() -> void:
	_play_sfx("death", -7.0)
	_finish_run(false)


func _on_player_surge_triggered(
	origin: Vector2,
	radius: float,
	damage: float,
	slow_multiplier: float,
	slow_duration: float
) -> void:
	if ended:
		return

	_play_sfx("surge", -9.0)
	surge_effects.append({"origin": origin, "radius": radius, "time": 0.0, "duration": 0.24})
	queue_redraw()

	var radius_sq = radius * radius
	for enemy in active_enemies:
		if not enemy.is_active:
			continue
		if origin.distance_squared_to(enemy.global_position) <= radius_sq:
			enemy.apply_projectile_hit(_rolled_damage(damage))
			enemy.apply_slow(slow_multiplier, slow_duration)


func _open_next_upgrade_panel() -> void:
	if pending_upgrade_queue.is_empty():
		return

	paused_for_upgrade = true
	_set_simulation_paused(true)

	current_upgrade_reason = String(pending_upgrade_queue[0])
	var choice_count = clamp(draft_choices, 3, upgrade_buttons.size())
	upgrade_options = _pick_upgrade_options(choice_count)

	if upgrade_options.is_empty():
		pending_upgrade_queue.pop_front()
		paused_for_upgrade = false
		_set_simulation_paused(false)
		return

	if current_upgrade_reason == "level":
		upgrade_title.text = "Realm Level %d Upgrade - Choose" % level
	else:
		upgrade_title.text = "Core Overload Upgrade - Choose"

	for i in range(upgrade_buttons.size()):
		var button: Button = upgrade_buttons[i]
		if i < upgrade_options.size():
			var option: Dictionary = upgrade_options[i]
			button.text = "%s\n%s" % [option["title"], option["desc"]]
			button.visible = true
		else:
			button.visible = false

	upgrade_panel.visible = true


func _on_upgrade_selected(index: int) -> void:
	if index < 0 or index >= upgrade_options.size():
		return

	var selected: Dictionary = upgrade_options[index]
	_apply_upgrade(String(selected["id"]))

	if not pending_upgrade_queue.is_empty():
		pending_upgrade_queue.pop_front()

	upgrade_panel.visible = false
	paused_for_upgrade = false
	_set_simulation_paused(false)

	if not pending_upgrade_queue.is_empty():
		_open_next_upgrade_panel()

	_sync_hud()


func _pick_upgrade_options(count: int) -> Array:
	var pool: Array = []
	for upgrade in UPGRADES:
		if upgrade.has("weapons"):
			if not (upgrade["weapons"] as Array).has(player.weapon_type):
				continue
		if upgrade.has("realms"):
			if not (upgrade["realms"] as Array).has(String(selected_realm.get("id", "riftcore"))):
				continue
		pool.append(upgrade.duplicate(true))

	pool.shuffle()
	var result: Array = []
	for i in range(min(count, pool.size())):
		result.append(pool[i])
	return result


func _apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"damage":
			player.damage *= 1.16
		"fire_rate":
			player.fire_rate *= 1.15
		"move_speed":
			player.move_speed *= 1.11
		"max_hp":
			player.add_max_hp(24.0)
		"magnet":
			player.pickup_magnet_radius += 36.0
		"projectile_speed":
			player.projectile_speed *= 1.14
		"pierce":
			player.projectile_pierce = min(player.projectile_pierce + 1, 10)
		"surge_damage":
			player.surge_damage *= 1.24
		"surge_cycle":
			player.surge_distance = max(95.0, player.surge_distance * 0.84)
		"surge_radius":
			player.surge_radius *= 1.14
		"surge_frost":
			player.surge_slow_multiplier = max(0.28, player.surge_slow_multiplier - 0.08)
			player.surge_slow_duration += 0.35
		"regen_field":
			player.regen_per_second += 0.6
		"leech_gel":
			kill_heal_flat += 1.4
		"armor_mesh":
			player.damage_taken_multiplier = max(0.54, player.damage_taken_multiplier * 0.92)
		"crit_chip":
			crit_chance = min(0.72, crit_chance + 0.07)
		"crit_amp":
			crit_multiplier += 0.26
		"lucky_draft":
			draft_choices = min(6, draft_choices + 1)
		"core_hack":
			overclock_fire_bonus += 0.12
			overclock_duration_bonus += 1.6
		"core_gain":
			core_gain_multiplier *= 1.18
		"mastery_boost":
			mastery_gain_multiplier *= 1.20
		"duplicate_shot":
			duplicate_shot_chance = min(0.45, duplicate_shot_chance + 0.08)
		"weapon_overclock":
			player.fire_rate *= 1.10
			player.projectile_pierce = min(player.projectile_pierce + 1, 10)
		"beam_width":
			beam_width_bonus += 8.0
		"beam_chain":
			bonus_beam_hits += 1
		"shotgun_pellets":
			shotgun_pellet_bonus = min(shotgun_pellet_bonus + 1, 7)
		"shotgun_blast":
			shotgun_damage_multiplier *= 1.15
		"boomerang_cycles":
			boomerang_cycles_bonus = min(boomerang_cycles_bonus + 1, 7)
		"boomerang_cap":
			bonus_boomerang_cap = min(bonus_boomerang_cap + 1, 3)
		"frost_bulwark":
			player.add_max_hp(40.0)
			player.regen_per_second += 0.5
		"rift_greed":
			core_gain_multiplier *= 1.35
			player.max_hp *= 0.94
			player.current_hp = min(player.current_hp, player.max_hp)
		"void_pact":
			player.damage *= 1.38
			player.damage_taken_multiplier *= 1.14
		"void_frenzy":
			player.fire_rate *= 1.22
			player.damage_taken_multiplier *= 1.10


func _set_simulation_paused(should_pause: bool) -> void:
	player.set_physics_process(not should_pause)

	for enemy in active_enemies:
		if enemy.is_active:
			enemy.set_physics_process(not should_pause)

	for projectile in active_projectiles:
		if projectile.is_active:
			projectile.set_physics_process(not should_pause)

	for orb in active_orbs:
		if orb.is_active:
			orb.set_physics_process(not should_pause)


func _prune_inactive(entries: Array) -> void:
	for i in range(entries.size() - 1, -1, -1):
		var entry = entries[i]
		if not is_instance_valid(entry) or not entry.is_active:
			entries.remove_at(i)


func _sync_hud() -> void:
	hero_label.text = "Hero %s" % selected_hero.get("name", "Blueth")
	realm_label.text = "Realm %s" % selected_realm.get("name", "Riftcore")
	weapon_label.text = "Weapon %s" % DataScript.WEAPONS[player.weapon_type]["name"]
	health_label.text = "HP %.0f / %.0f" % [player.current_hp, player.max_hp]
	level_label.text = "Realm Lv %d / %d" % [level, MAX_REALM_LEVEL]
	timer_label.text = "%s / %s" % [_format_time(elapsed_time), _format_time(RUN_DURATION)]
	enemies_label.text = "Enemies %d" % active_enemies.size()
	core_label.text = "Core %.0f / %.0f" % [core_charge, core_charge_next]
	core_bar.max_value = core_charge_next
	core_bar.value = core_charge

	if overclock_timer > 0.0:
		hint_label.text = "OVERCLOCK %.1fs: boosted fire rate and core gain." % overclock_timer
	else:
		hint_label.text = "Realm levels are time-gated. Core charge from kills grants bonus drafts and overclock spikes."


func _format_time(seconds: float) -> String:
	var total = int(seconds)
	var mm = int(total / 60.0)
	var ss = int(total % 60)
	return "%02d:%02d" % [mm, ss]


func _calculate_mastery_earned(victory: bool) -> int:
	var base = float(kills) * 0.22 + elapsed_time / 45.0 + float(level) * 2.2
	if victory:
		base += 20.0 + float(level) * 1.6
	base *= float(realm_mods.get("mastery_reward", 1.0))
	base *= mastery_gain_multiplier
	return max(1, int(round(base)))


func _finish_run(victory: bool) -> void:
	if ended:
		return

	ended = true
	upgrade_panel.visible = false
	_set_simulation_paused(true)

	var stats = {
		"time_survived": elapsed_time,
		"level": level,
		"kills": kills,
		"hero": selected_hero.get("name", "Blueth"),
		"weapon": DataScript.WEAPONS[player.weapon_type]["name"],
		"realm": selected_realm.get("name", "Riftcore"),
		"mastery_earned": _calculate_mastery_earned(victory)
	}
	emit_signal("run_finished", victory, stats)
