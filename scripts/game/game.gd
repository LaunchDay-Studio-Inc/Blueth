extends Node2D
class_name BluethGame

signal run_finished(victory: bool, stats: Dictionary)

const PlayerScript = preload("res://scripts/entities/player.gd")
const EnemyScript = preload("res://scripts/entities/enemy.gd")
const ProjectileScript = preload("res://scripts/entities/projectile.gd")
const XpOrbScript = preload("res://scripts/entities/xp_orb.gd")
const DataScript = preload("res://scripts/game/data.gd")
const FxOverlayScript = preload("res://scripts/game/fx_overlay.gd")

const ARENA_SIZE = Vector2(2200, 1300)
const RUN_DURATION = 1020.0
const MAX_REALM_LEVEL = 15
const MAX_UPGRADE_PICKS_PER_RUN = 30
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

const ENDLESS_LEVEL_INTERVAL = 60.0

const FALLBACK_MUSIC_PATH = "res://assets/audio/music_loop.wav"
const MUSIC_PATHS = {
	"frostfields": "res://assets/audio/music_frostfields.wav",
	"riftcore": "res://assets/audio/music_riftcore.wav",
	"umbra_vault": "res://assets/audio/music_umbra_vault.wav",
	"endless": "res://assets/audio/music_endless.wav"
}
const AMBIENT_PATHS = {
	"frostfields": "res://assets/audio/ambient_frostfields.wav",
	"riftcore": "res://assets/audio/ambient_riftcore.wav",
	"umbra_vault": "res://assets/audio/ambient_umbra_vault.wav",
	"endless": "res://assets/audio/ambient_endless.wav"
}
const SFX_PATHS = {
	# Repetitive SFX use small variant pools.
	"shotgun": [
		"res://assets/audio/sfx_shotgun.wav",
		"res://assets/audio/sfx_shotgun_2.wav",
		"res://assets/audio/sfx_shotgun_3.wav"
	],
	"beam": [
		"res://assets/audio/sfx_beam.wav",
		"res://assets/audio/sfx_beam_2.wav",
		"res://assets/audio/sfx_beam_3.wav"
	],
	"boomerang": [
		"res://assets/audio/sfx_boomerang.wav",
		"res://assets/audio/sfx_boomerang_2.wav",
		"res://assets/audio/sfx_boomerang_3.wav"
	],
	"surge": "res://assets/audio/sfx_surge.wav",
	"hurt": [
		"res://assets/audio/sfx_hurt.wav",
		"res://assets/audio/sfx_hurt_2.wav"
	],
	"hit": [
		"res://assets/audio/sfx_hit.wav",
		"res://assets/audio/sfx_hit_2.wav",
		"res://assets/audio/sfx_hit_3.wav"
	],
	"crit": [
		"res://assets/audio/sfx_crit.wav",
		"res://assets/audio/sfx_crit_2.wav"
	],
	"levelup": [
		"res://assets/audio/sfx_levelup.wav",
		"res://assets/audio/sfx_levelup_2.wav",
		"res://assets/audio/sfx_levelup_3.wav"
	],
	"enemy_die": [
		"res://assets/audio/sfx_enemy_die.wav",
		"res://assets/audio/sfx_enemy_die_2.wav",
		"res://assets/audio/sfx_enemy_die_3.wav"
	],
	"boss_roar": "res://assets/audio/sfx_boss_roar.wav",
	"boss_slam": "res://assets/audio/sfx_boss_slam.wav",
	"boss_die": "res://assets/audio/sfx_boss_die.wav",
	"step": [
		"res://assets/audio/sfx_step.wav",
		"res://assets/audio/sfx_step_2.wav",
		"res://assets/audio/sfx_step_3.wav"
	],
	"ui_click": "res://assets/audio/sfx_click.wav",
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
	{"id": "surge_siphon", "title": "Surge Siphon", "desc": "Flow Surge heals 6 HP on trigger"},
	{"id": "regen_field", "title": "Recovery Field", "desc": "+0.6 HP/sec regen"},
	{"id": "leech_gel", "title": "Leech Gel", "desc": "Heal 1.4 HP on every kill"},
	{"id": "armor_mesh", "title": "Armor Mesh", "desc": "Take 8% less incoming damage"},
	{"id": "crit_chip", "title": "Crit Chip", "desc": "+20% crit chance"},
	{"id": "crit_amp", "title": "Crit Amplifier", "desc": "+26% crit multiplier"},
	{"id": "core_hack", "title": "Core Hack", "desc": "Core overload grants stronger overclock"},
	{"id": "core_vacuum", "title": "Vacuum Burst", "desc": "Core overload pulls all shards to you"},
	{"id": "core_pulse", "title": "Overload Pulse", "desc": "Core overload emits a damaging pulse"},
	{"id": "overclock_cascade", "title": "Overclock Cascade", "desc": "Elite kills extend overclock duration"},
	{"id": "core_gain", "title": "Shard Funnel", "desc": "+18% core charge gain"},
	{"id": "mastery_boost", "title": "Shard Speculation", "desc": "+20% mastery shard reward"},
	{"id": "duplicate_shot", "title": "Echo Fire", "desc": "+8% chance to duplicate attacks"},
	{"id": "weapon_overclock", "title": "Weapon Overclock", "desc": "+10% fire rate and +1 pierce"},
	{"id": "laser_pattern", "title": "Prism Sweep", "desc": "Periodic rotating laser that pierces everything.", "heroes": ["warden"]},
	{"id": "beam_width", "title": "Lens Array", "desc": "+10% beam width", "weapons": ["beam"]},
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
	"meta": {},
	"settings": {}
}

var realm_id = "riftcore"
var run_is_endless = false
var run_duration = RUN_DURATION
var run_max_level = MAX_REALM_LEVEL
var max_upgrade_picks_per_run = MAX_UPGRADE_PICKS_PER_RUN
var picks_per_level = 2
var start_picks = 2
var endless_next_level_time = ENDLESS_LEVEL_INTERVAL

var selected_hero: Dictionary = {}
var selected_realm: Dictionary = {}
var realm_mods: Dictionary = {}
var meta_mods: Dictionary = {}
var settings: Dictionary = {}

var access_shake_scale = 1.0
var access_flash_scale = 1.0
var access_bg_intensity = 1.0
var music_volume_linear = 0.85
var sfx_volume_linear = 1.0
var show_enemy_hp_bars = false
var show_boss_hp_bar = true
var show_damage_numbers = true
var reduced_particles = false

var arena_rect = Rect2(Vector2.ZERO, ARENA_SIZE)

var world_root: Node2D
var fx_overlay: Node2D
var player
var camera: Camera2D
var camera_base_offset = Vector2.ZERO
var camera_base_zoom = Vector2.ONE
var cached_light_texture: Texture2D

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

var player_last_pos = Vector2.ZERO
var footstep_accum = 0.0
var footstep_stride = 54.0

var level = 1
var core_charge = 0.0
var core_charge_next = 52.0
var kills = 0

var ended = false
var paused_for_upgrade = false
var paused_by_player = false
var pending_upgrade_queue: Array = []
var current_upgrade_reason = ""
var upgrade_options: Array = []
var upgrade_picks_used = 0
var upgrade_pick_counts: Dictionary = {}
var draft_bonus_bank = 0

var draft_choices = 4
var beam_width_multiplier = 1.0
var bonus_beam_hits = 0
var shotgun_pellet_bonus = 0
var shotgun_damage_multiplier = 1.0
var boomerang_cycles_bonus = 0
var bonus_boomerang_cap = 0

var crit_chance = 0.04
var crit_multiplier = 1.55
var kill_heal_flat = 0.0
var duplicate_shot_chance = 0.0

var laser_enabled = false
var laser_timer = 0.0
var laser_interval = 4.2
var laser_damage_bonus = 0.0
var laser_width_bonus = 0.0
var laser_angle = 0.0

var core_gain_multiplier = 1.0
var mastery_gain_multiplier = 1.0

var overclock_timer = 0.0
var overclock_fire_bonus = 0.0
var overclock_duration_bonus = 0.0

var surge_heal_flat = 0.0
var core_vacuum = false
var overload_pulse_radius = 0.0
var overload_pulse_damage_bonus = 0.0
var elite_overclock_extend = 0.0

var surge_effects: Array = []
var beam_effects: Array = []
var muzzle_effects: Array = []
var impact_effects: Array = []
var particle_effects: Array = []
var floating_texts: Array = []

var twinkle_stars: Array = []
var nebula_clouds: Array = []
var rift_rings: Array = []
var void_cracks: Array = []
var aurora_bands: Array = []
var realm_palette: Dictionary = {}

var hud_layer: CanvasLayer
var hero_label: Label
var realm_label: Label
var weapon_label: Label
var health_label: Label
var level_label: Label
var timer_label: Label
var enemies_label: Label
var fps_label: Label
var stats_label: Label
var core_label: Label
var core_bar: ProgressBar
var core_glow: ColorRect
var hint_label: Label
var screen_flash_rect: ColorRect
var fog_rect: ColorRect
var fog_material: ShaderMaterial
var fog_base_intensity = 0.22
var level_fog_mult = 1.0
var vignette_rect: ColorRect

var boss_panel: PanelContainer
var boss_name_label: Label
var boss_hp_bar: ProgressBar

var upgrade_panel: PanelContainer
var upgrade_title: Label
var upgrade_buttons: Array = []

var pause_button: Button
var pause_overlay: Control
var pause_resume_button: Button
var pause_quit_button: Button

var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var music_base_volume_db = -18.0
var ambient_base_volume_db = -28.0
var music_dynamic_offset_db = 0.0
var ambient_dynamic_offset_db = 0.0
var level_mix_music_db = 0.0
var level_mix_ambient_db = 0.0
var sfx_streams = {}
var sfx_players: Array = []
var sfx_cursor = -1
var hit_sfx_cooldown = 0.0
var crit_sfx_cooldown = 0.0
var enemy_die_sfx_cooldown = 0.0
var step_sfx_cooldown = 0.0

var hitstop_timer = 0.0
var hitstop_active = false

var shake_intensity = 0.0
var shake_seed = 0.0
var zoom_kick = 0.0

var level_spawn_mode = 0
var spawn_distance_min = 470.0
var spawn_distance_max = 760.0
var spawn_split_axis = 0
var featured_archetype = ""
var current_face_variant = 0

var boss_ref = null
var boss_name = ""
var boss_level = 0
var boss_bonus_shards = 0
var boss_spawned_levels: Dictionary = {}
var boss_special_timer = 0.0
var boss_ring_timer = 0.0
var boss_beam_angle = 0.0
var boss_beam_fire_timer = 0.0
var boss_beam_target_angle = 0.0
var boss_beam_damage_cooldown = 0.0
var boss_slam_windup = 0.0
var boss_slam_origin = Vector2.ZERO
var boss_slam_radius = 150.0

var screen_flash_color = Color(1.0, 1.0, 1.0, 1.0)
var screen_flash_strength = 0.0
var core_glow_pulse = 0.0
var upgrade_anim_t = 1.0


func setup_run(config: Dictionary) -> void:
	run_config = config.duplicate(true)


func _ready() -> void:
	randomize()
	shake_seed = randf_range(0.0, TAU)
	selected_hero = DataScript.hero_by_id(String(run_config.get("hero_id", "warden")))
	selected_realm = DataScript.realm_by_id(String(run_config.get("realm_id", "riftcore")))
	realm_mods = selected_realm.get("mods", {}).duplicate(true)
	meta_mods = run_config.get("meta", {}).duplicate(true)
	settings = run_config.get("settings", {}).duplicate(true)
	realm_id = String(selected_realm.get("id", "riftcore"))
	run_is_endless = realm_id == "endless"

	if run_is_endless:
		run_duration = -1.0
		run_max_level = 999999
		max_upgrade_picks_per_run = 999999
		picks_per_level = 1
		start_picks = 1
		endless_next_level_time = ENDLESS_LEVEL_INTERVAL
	else:
		run_duration = RUN_DURATION
		run_max_level = MAX_REALM_LEVEL
		max_upgrade_picks_per_run = MAX_UPGRADE_PICKS_PER_RUN
		picks_per_level = 2
		start_picks = 2

	access_shake_scale = clamp(float(settings.get("shake_scale", 1.0)), 0.0, 1.0)
	access_flash_scale = clamp(float(settings.get("flash_scale", 1.0)), 0.0, 1.0)
	access_bg_intensity = clamp(float(settings.get("bg_intensity", 1.0)), 0.4, 1.0)
	music_volume_linear = clamp(float(settings.get("music_volume", 0.85)), 0.0, 1.0)
	sfx_volume_linear = clamp(float(settings.get("sfx_volume", 1.0)), 0.0, 1.0)
	show_enemy_hp_bars = float(settings.get("show_enemy_hp", 0.0)) >= 0.5
	show_boss_hp_bar = float(settings.get("show_boss_hp", 1.0)) >= 0.5
	show_damage_numbers = float(settings.get("show_damage_numbers", 1.0)) >= 0.5
	reduced_particles = float(settings.get("reduced_particles", 0.0)) >= 0.5

	_build_realm_palette()

	_build_world()
	_seed_background_layers()
	_build_audio()
	_apply_level_style(level)
	_build_hud()
	_spawn_player()
	_apply_meta_modifiers()
	_warm_pools()
	_sync_hud()
	queue_redraw()
	for i in range(start_picks):
		_queue_upgrade("start")


func _build_world() -> void:
	world_root = Node2D.new()
	add_child(world_root)
	fx_overlay = FxOverlayScript.new()
	fx_overlay.game_ref = self
	fx_overlay.z_index = 60
	add_child(fx_overlay)


func _get_cached_light_texture() -> Texture2D:
	if cached_light_texture != null:
		return cached_light_texture

	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		var fy = (float(y) / float(size - 1)) * 2.0 - 1.0
		for x in range(size):
			var fx = (float(x) / float(size - 1)) * 2.0 - 1.0
			var r = sqrt(fx * fx + fy * fy)
			var a = clamp(1.0 - r, 0.0, 1.0)
			a = pow(a, 2.2)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))

	cached_light_texture = ImageTexture.create_from_image(img)
	return cached_light_texture


func _build_realm_palette() -> void:
	var realm_id_local = String(selected_realm.get("id", "riftcore"))
	match realm_id_local:
		"frostfields":
			realm_palette = {
				"bg_a": Color(0.06, 0.16, 0.24),
				"bg_b": Color(0.11, 0.27, 0.37),
				"bg_c": Color(0.07, 0.12, 0.20),
				"bg_d": Color(0.11, 0.19, 0.29),
				"accent": Color(0.52, 0.86, 1.0),
				"accent_soft": Color(0.64, 0.92, 1.0, 0.34),
				"danger": Color(0.86, 0.34, 0.44),
				"enemy": Color(0.77, 0.40, 0.50),
				"enemy_elite": Color(0.92, 0.48, 0.60),
				"grid": Color(0.70, 0.90, 1.0, 0.10),
				"star": Color(0.86, 0.98, 1.0, 0.8),
				"panel_bg": Color(0.04, 0.13, 0.20, 0.84),
				"panel_border": Color(0.45, 0.81, 1.0, 0.95)
			}
		"riftcore":
			realm_palette = {
				"bg_a": Color(0.04, 0.13, 0.22),
				"bg_b": Color(0.07, 0.24, 0.34),
				"bg_c": Color(0.03, 0.09, 0.16),
				"bg_d": Color(0.08, 0.15, 0.25),
				"accent": Color(0.46, 0.94, 0.96),
				"accent_soft": Color(0.62, 0.98, 0.96, 0.30),
				"danger": Color(0.94, 0.35, 0.48),
				"enemy": Color(0.88, 0.36, 0.42),
				"enemy_elite": Color(1.0, 0.56, 0.52),
				"grid": Color(0.60, 0.96, 0.98, 0.11),
				"star": Color(0.90, 1.0, 0.98, 0.82),
				"panel_bg": Color(0.03, 0.11, 0.18, 0.84),
				"panel_border": Color(0.42, 0.84, 0.96, 0.96)
			}
		"umbra_vault":
			realm_palette = {
				"bg_a": Color(0.08, 0.07, 0.14),
				"bg_b": Color(0.15, 0.10, 0.26),
				"bg_c": Color(0.06, 0.05, 0.11),
				"bg_d": Color(0.14, 0.08, 0.19),
				"accent": Color(0.87, 0.72, 1.0),
				"accent_soft": Color(0.91, 0.78, 1.0, 0.36),
				"danger": Color(0.96, 0.33, 0.54),
				"enemy": Color(0.91, 0.37, 0.57),
				"enemy_elite": Color(0.99, 0.58, 0.68),
				"grid": Color(0.83, 0.74, 0.99, 0.11),
				"star": Color(0.96, 0.88, 1.0, 0.85),
				"panel_bg": Color(0.08, 0.06, 0.14, 0.84),
				"panel_border": Color(0.76, 0.63, 0.99, 0.96)
			}
		"endless":
			realm_palette = {
				"bg_a": Color(0.03, 0.11, 0.19),
				"bg_b": Color(0.05, 0.20, 0.29),
				"bg_c": Color(0.02, 0.06, 0.12),
				"bg_d": Color(0.05, 0.12, 0.22),
				"accent": Color(0.38, 1.0, 0.90),
				"accent_soft": Color(0.58, 1.0, 0.90, 0.30),
				"danger": Color(1.0, 0.33, 0.54),
				"enemy": Color(0.86, 0.44, 0.60),
				"enemy_elite": Color(0.99, 0.62, 0.72),
				"grid": Color(0.52, 0.98, 0.90, 0.10),
				"star": Color(0.92, 1.0, 0.98, 0.85),
				"panel_bg": Color(0.03, 0.10, 0.16, 0.84),
				"panel_border": Color(0.44, 0.92, 0.86, 0.96)
			}
		_:
			realm_palette = {
				"bg_a": Color(0.05, 0.14, 0.22),
				"bg_b": Color(0.08, 0.24, 0.34),
				"bg_c": Color(0.05, 0.10, 0.17),
				"bg_d": Color(0.09, 0.16, 0.25),
				"accent": Color(0.49, 0.88, 1.0),
				"accent_soft": Color(0.64, 0.92, 1.0, 0.32),
				"danger": Color(0.90, 0.37, 0.46),
				"enemy": Color(0.88, 0.36, 0.42),
				"enemy_elite": Color(1.0, 0.56, 0.52),
				"grid": Color(0.65, 0.88, 0.99, 0.11),
				"star": Color(0.84, 0.98, 1.0, 0.82),
				"panel_bg": Color(0.03, 0.11, 0.18, 0.84),
				"panel_border": Color(0.42, 0.82, 1.0, 0.95)
			}


func _seed_background_layers() -> void:
	twinkle_stars.clear()
	nebula_clouds.clear()
	rift_rings.clear()
	void_cracks.clear()
	aurora_bands.clear()
	for i in range(88):
		twinkle_stars.append({
			"position": Vector2(
				randf_range(arena_rect.position.x + 24.0, arena_rect.end.x - 24.0),
				randf_range(arena_rect.position.y + 24.0, arena_rect.end.y - 24.0)
			),
			"radius": randf_range(0.8, 2.2),
			"phase": randf_range(0.0, TAU),
			"speed": randf_range(0.4, 1.8),
			"alpha": randf_range(0.16, 0.52)
		})

	for i in range(7):
		nebula_clouds.append({
			"offset": Vector2(
				randf_range(-ARENA_SIZE.x * 0.42, ARENA_SIZE.x * 0.42),
				randf_range(-ARENA_SIZE.y * 0.36, ARENA_SIZE.y * 0.36)
			),
			"radius": randf_range(180.0, 410.0),
			"phase": randf_range(0.0, TAU),
			"speed": randf_range(0.05, 0.16),
			"drift": randf_range(14.0, 44.0),
			"alpha": randf_range(0.08, 0.18)
		})

	match realm_id:
		"riftcore":
			for i in range(4):
				rift_rings.append({
					"offset": Vector2(randf_range(-320.0, 320.0), randf_range(-220.0, 220.0)),
					"radius": randf_range(220.0, 520.0),
					"thickness": randf_range(1.8, 3.4),
					"phase": randf_range(0.0, TAU),
					"speed": randf_range(0.12, 0.30),
					"alpha": randf_range(0.06, 0.14)
				})
		"umbra_vault":
			for i in range(16):
				var start = Vector2(
					randf_range(arena_rect.position.x + 120.0, arena_rect.end.x - 120.0),
					randf_range(arena_rect.position.y + 120.0, arena_rect.end.y - 120.0)
				)
				var dir = Vector2.RIGHT.rotated(randf() * TAU)
				var length = randf_range(180.0, 520.0)
				void_cracks.append({
					"start": start,
					"end": start + dir * length,
					"width": randf_range(1.2, 2.4),
					"phase": randf_range(0.0, TAU),
					"speed": randf_range(0.25, 0.55),
					"alpha": randf_range(0.05, 0.12)
				})
		"endless":
			for i in range(6):
				aurora_bands.append({
					"offset": Vector2(randf_range(-360.0, 360.0), randf_range(-260.0, 260.0)),
					"radius": randf_range(260.0, 620.0),
					"thickness": randf_range(2.0, 4.0),
					"phase": randf_range(0.0, TAU),
					"speed": randf_range(0.08, 0.18),
					"alpha": randf_range(0.06, 0.15)
				})
		_:
			pass


func _build_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return

	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	var music_path = String(MUSIC_PATHS.get(realm_id, ""))
	if music_path == "" or not ResourceLoader.exists(music_path):
		music_path = FALLBACK_MUSIC_PATH
	if ResourceLoader.exists(music_path):
		music_player.stream = load(music_path)
		music_player.volume_db = music_base_volume_db + _linear_to_db_safe(music_volume_linear)
		music_player.play()

	ambient_player = AudioStreamPlayer.new()
	add_child(ambient_player)
	var ambient_path = String(AMBIENT_PATHS.get(realm_id, ""))
	if ambient_path != "" and ResourceLoader.exists(ambient_path):
		ambient_player.stream = load(ambient_path)
		ambient_player.volume_db = ambient_base_volume_db + _linear_to_db_safe(music_volume_linear)
		ambient_player.play()

	sfx_streams.clear()
	for sfx_name in SFX_PATHS.keys():
		var entry = SFX_PATHS[sfx_name]
		var paths: Array = []
		if typeof(entry) == TYPE_ARRAY:
			paths = entry
		else:
			paths = [String(entry)]

		var streams: Array = []
		for p in paths:
			var sfx_path = String(p)
			if sfx_path != "" and ResourceLoader.exists(sfx_path):
				streams.append(load(sfx_path))

		if not streams.is_empty():
			sfx_streams[sfx_name] = streams

	for i in range(16):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "Master"
		add_child(sfx_player)
		sfx_players.append(sfx_player)

func _apply_level_style(new_level: int) -> void:
	var lvl = max(1, new_level)

	# Faces: changing every 2 levels reads better than every level (less visual noise),
	# but still makes each bracket feel like a new "mood" of the same enemy cast.
	current_face_variant = int(floor(float(lvl - 1) / 2.0)) % 6

	# Spawn geometry + audio bias: lightweight variety so levels don't blur together.
	level_spawn_mode = 0
	spawn_split_axis = 0
	spawn_distance_min = 470.0
	spawn_distance_max = 760.0
	level_mix_music_db = 0.0
	level_mix_ambient_db = 0.0
	level_fog_mult = 1.0

	if run_is_endless:
		# Endless: keep it readable and forgiving, but still avoid "samey" feel.
		level_spawn_mode = (lvl - 1) % 4
		spawn_distance_min = 520.0
		spawn_distance_max = 820.0
		level_mix_music_db = sin(float(lvl) * 0.55) * 0.6
		level_mix_ambient_db = cos(float(lvl) * 0.48) * 0.8
		level_fog_mult = 0.95 + 0.08 * sin(float(lvl) * 0.33)
	else:
		# Each realm run level gets a distinct "wave signature" (spawn pattern + mix bias).
		match lvl:
			1:
				level_spawn_mode = 0
				spawn_distance_min = 460.0
				spawn_distance_max = 720.0
				level_mix_music_db = -0.8
				level_mix_ambient_db = 0.2
				level_fog_mult = 0.92
			2:
				level_spawn_mode = 1
				spawn_distance_min = 560.0
				spawn_distance_max = 860.0
				level_mix_music_db = -0.2
				level_mix_ambient_db = 0.7
				level_fog_mult = 0.98
			3:
				level_spawn_mode = 2
				spawn_distance_min = 600.0
				spawn_distance_max = 900.0
				level_mix_music_db = 0.4
				level_mix_ambient_db = 0.3
				level_fog_mult = 1.02
			4:
				level_spawn_mode = 3
				spawn_split_axis = 0
				spawn_distance_min = 520.0
				spawn_distance_max = 820.0
				level_mix_music_db = 0.1
				level_mix_ambient_db = 1.0
				level_fog_mult = 1.06
			5:
				level_spawn_mode = 0
				spawn_distance_min = 520.0
				spawn_distance_max = 780.0
				level_mix_music_db = 1.0
				level_mix_ambient_db = -0.6
				level_fog_mult = 1.08
			6:
				level_spawn_mode = 1
				spawn_distance_min = 560.0
				spawn_distance_max = 860.0
				level_mix_music_db = 0.2
				level_mix_ambient_db = 0.6
				level_fog_mult = 1.00
			7:
				level_spawn_mode = 2
				spawn_distance_min = 620.0
				spawn_distance_max = 920.0
				level_mix_music_db = 0.6
				level_mix_ambient_db = 0.1
				level_fog_mult = 1.04
			8:
				level_spawn_mode = 3
				spawn_split_axis = 1
				spawn_distance_min = 500.0
				spawn_distance_max = 780.0
				level_mix_music_db = -0.1
				level_mix_ambient_db = 1.2
				level_fog_mult = 1.08
			9:
				level_spawn_mode = 1
				spawn_distance_min = 580.0
				spawn_distance_max = 880.0
				level_mix_music_db = 0.4
				level_mix_ambient_db = 0.4
				level_fog_mult = 1.02
			10:
				level_spawn_mode = 0
				spawn_distance_min = 520.0
				spawn_distance_max = 800.0
				level_mix_music_db = 1.2
				level_mix_ambient_db = -0.8
				level_fog_mult = 1.10
			11:
				level_spawn_mode = 2
				spawn_distance_min = 640.0
				spawn_distance_max = 940.0
				level_mix_music_db = 0.5
				level_mix_ambient_db = 0.7
				level_fog_mult = 1.06
			12:
				level_spawn_mode = 3
				spawn_split_axis = 0
				spawn_distance_min = 540.0
				spawn_distance_max = 840.0
				level_mix_music_db = 0.8
				level_mix_ambient_db = 0.2
				level_fog_mult = 1.04
			13:
				level_spawn_mode = 1
				spawn_distance_min = 600.0
				spawn_distance_max = 900.0
				level_mix_music_db = 0.2
				level_mix_ambient_db = 1.1
				level_fog_mult = 1.10
			14:
				level_spawn_mode = 2
				spawn_distance_min = 660.0
				spawn_distance_max = 940.0
				level_mix_music_db = -0.2
				level_mix_ambient_db = 1.4
				level_fog_mult = 1.12
			15:
				level_spawn_mode = 0
				spawn_distance_min = 540.0
				spawn_distance_max = 820.0
				level_mix_music_db = 1.4
				level_mix_ambient_db = -1.0
				level_fog_mult = 1.16
			_:
				level_spawn_mode = 0

	# Featured enemy for subtle pacing variation.
	featured_archetype = ""
	if not run_is_endless:
		if lvl <= 2:
			featured_archetype = "grunt"
		elif lvl <= 4:
			featured_archetype = "sprinter"
		elif lvl <= 7:
			featured_archetype = "bulwark" if lvl >= 6 else "sprinter"
		elif lvl <= 11:
			featured_archetype = "pack" if lvl >= 9 else "bulwark"
		elif lvl <= 14:
			featured_archetype = "shooter"
		else:
			featured_archetype = "splitter"

		if realm_id == "umbra_vault" and lvl >= 6 and lvl <= 14:
			# Umbra is defined by stalker pressure; sprinkle that signature.
			if randf() < 0.45:
				featured_archetype = "stalker"

	# Per-level pitch change keeps loops from feeling identical.
	if music_player != null and music_player.stream != null:
		var realm_hash = float(abs(realm_id.hash() % 997))
		var key = float(lvl) * 1.71 + realm_hash * 0.003
		music_player.pitch_scale = 1.0 + sin(key) * 0.012

	# Update existing enemies so the "mood" shift is visible immediately.
	for enemy in active_enemies:
		if enemy == null or not enemy.is_active:
			continue
		if bool(enemy.is_boss):
			continue
		enemy.face_variant = current_face_variant
		enemy.queue_redraw()


func _play_sfx(sfx_name: String, volume_db: float = -9.0) -> void:
	if not sfx_streams.has(sfx_name) or sfx_players.is_empty():
		return

	var streams: Array = sfx_streams[sfx_name]
	if streams.is_empty():
		return

	sfx_cursor = (sfx_cursor + 1) % sfx_players.size()
	var player_node: AudioStreamPlayer = sfx_players[sfx_cursor]
	player_node.stream = streams[randi() % streams.size()]
	player_node.volume_db = volume_db + _linear_to_db_safe(sfx_volume_linear)
	player_node.pitch_scale = randf_range(0.96, 1.05)
	player_node.play()


func _linear_to_db_safe(linear: float) -> float:
	if linear <= 0.001:
		return -80.0
	return linear_to_db(linear)


func _add_shake(amount: float) -> void:
	# Global dampening: default shake was too strong for readability.
	var scaled = amount * access_shake_scale * 0.55
	if scaled <= 0.0:
		return
	shake_intensity = min(14.0, shake_intensity + scaled)
	zoom_kick = min(0.60, zoom_kick + scaled * 0.012)


func _screen_flash(color: Color, strength: float) -> void:
	screen_flash_color = color
	screen_flash_strength = min(1.0, max(screen_flash_strength, strength * access_flash_scale))


func _pulse_core_glow(strength: float) -> void:
	core_glow_pulse = min(1.0, max(core_glow_pulse, strength * access_flash_scale))


func _start_hitstop(duration: float) -> void:
	if duration <= 0.0 or ended or paused_for_upgrade:
		return
	hitstop_timer = max(hitstop_timer, duration)
	if not hitstop_active:
		hitstop_active = true
		_set_simulation_paused(true)


func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 20
	add_child(hud_layer)

	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(root)

	fog_rect = ColorRect.new()
	fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_rect.color = Color(1.0, 1.0, 1.0, 1.0)
	var fog_shader = Shader.new()
	fog_shader.code = """
shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(0.45, 0.9, 1.0, 1.0);
uniform float intensity = 0.22;
uniform float speed = 0.06;
uniform float scale = 3.4;

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME * speed;
	float n = sin((uv.x + t) * scale * 6.2831) * sin((uv.y - t * 0.9) * (scale * 0.85) * 6.2831);
	n = 0.5 + 0.5 * n;

	// Stronger at edges; keeps the center readable.
	float r = length(uv * 2.0 - 1.0);
	float edge = smoothstep(0.25, 1.05, r);

	float a = intensity * (0.22 + 0.78 * n) * (0.25 + 0.75 * edge);
	COLOR = vec4(fog_color.rgb, a);
}
"""
	fog_material = ShaderMaterial.new()
	fog_material.shader = fog_shader
	var fog_col: Color = realm_palette.get("accent", Color(0.49, 0.88, 1.0))
	fog_col = fog_col.lerp(realm_palette.get("bg_b", Color(0.08, 0.24, 0.34)), 0.35)
	fog_col.a = 1.0
	fog_material.set_shader_parameter("fog_color", fog_col)
	fog_material.set_shader_parameter("intensity", fog_base_intensity * access_bg_intensity)
	fog_material.set_shader_parameter("speed", 0.06)
	fog_material.set_shader_parameter("scale", 3.4)
	fog_rect.material = fog_material
	root.add_child(fog_rect)

	screen_flash_rect = ColorRect.new()
	screen_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_flash_rect.color = Color(1.0, 0.2, 0.3, 0.0)
	root.add_child(screen_flash_rect)

	vignette_rect = ColorRect.new()
	vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_rect.color = Color(1.0, 1.0, 1.0, 1.0)
	var vignette_shader = Shader.new()
	vignette_shader.code = """
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float strength = 0.55;

void fragment() {
	vec2 uv = SCREEN_UV * 2.0 - 1.0;
	float r = length(uv);
	float v = smoothstep(0.55, 1.25, r);
	COLOR = vec4(tint.rgb, tint.a * v * strength);
}
"""
	var vignette_mat = ShaderMaterial.new()
	vignette_mat.shader = vignette_shader
	var vignette_tint: Color = realm_palette.get("bg_c", Color(0.0, 0.0, 0.0)).darkened(0.65)
	vignette_tint.a = 1.0
	vignette_mat.set_shader_parameter("tint", vignette_tint)
	vignette_mat.set_shader_parameter("strength", 0.55)
	vignette_rect.material = vignette_mat
	root.add_child(vignette_rect)

	var top_panel = PanelContainer.new()
	top_panel.anchor_left = 0.0
	top_panel.anchor_top = 0.0
	top_panel.anchor_right = 1.0
	top_panel.anchor_bottom = 0.0
	top_panel.offset_left = 14.0
	top_panel.offset_top = 14.0
	top_panel.offset_right = -14.0
	top_panel.offset_bottom = 146.0
	top_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(realm_palette.get("panel_bg", Color(0.03, 0.11, 0.18, 0.84)), realm_palette.get("panel_border", Color(0.4, 0.8, 1.0)))
	)
	root.add_child(top_panel)

	boss_panel = PanelContainer.new()
	boss_panel.anchor_left = 0.5
	boss_panel.anchor_top = 0.0
	boss_panel.anchor_right = 0.5
	boss_panel.anchor_bottom = 0.0
	boss_panel.offset_left = -360.0
	boss_panel.offset_right = 360.0
	boss_panel.offset_top = 156.0
	boss_panel.offset_bottom = 224.0
	boss_panel.visible = false
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.02, 0.05, 0.10, 0.92), realm_palette.get("danger", Color(1.0, 0.36, 0.50)))
	)
	root.add_child(boss_panel)

	var boss_vb = VBoxContainer.new()
	boss_vb.add_theme_constant_override("separation", 4)
	boss_panel.add_child(boss_vb)

	boss_name_label = Label.new()
	boss_name_label.text = ""
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 22)
	boss_name_label.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0))
	boss_vb.add_child(boss_name_label)

	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.custom_minimum_size = Vector2(0.0, 22.0)
	boss_hp_bar.min_value = 0.0
	boss_hp_bar.show_percentage = false
	var boss_bg = StyleBoxFlat.new()
	boss_bg.bg_color = Color(0.02, 0.03, 0.06, 0.92)
	boss_bg.border_color = Color(0.72, 0.22, 0.34, 0.85)
	boss_bg.corner_radius_top_left = 9
	boss_bg.corner_radius_top_right = 9
	boss_bg.corner_radius_bottom_left = 9
	boss_bg.corner_radius_bottom_right = 9
	boss_bg.border_width_left = 2
	boss_bg.border_width_top = 2
	boss_bg.border_width_right = 2
	boss_bg.border_width_bottom = 2
	boss_hp_bar.add_theme_stylebox_override("background", boss_bg)
	var boss_fill = StyleBoxFlat.new()
	boss_fill.bg_color = Color(1.0, 0.32, 0.46)
	boss_fill.corner_radius_top_left = 9
	boss_fill.corner_radius_top_right = 9
	boss_fill.corner_radius_bottom_left = 9
	boss_fill.corner_radius_bottom_right = 9
	boss_hp_bar.add_theme_stylebox_override("fill", boss_fill)
	boss_vb.add_child(boss_hp_bar)

	var top_vb = VBoxContainer.new()
	top_vb.add_theme_constant_override("separation", 4)
	top_panel.add_child(top_vb)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 16)
	top_vb.add_child(row1)

	hero_label = Label.new()
	hero_label.add_theme_font_size_override("font_size", 21)
	hero_label.add_theme_color_override("font_color", Color(0.95, 0.99, 1.0))
	row1.add_child(hero_label)

	realm_label = Label.new()
	realm_label.add_theme_font_size_override("font_size", 21)
	realm_label.add_theme_color_override("font_color", realm_palette.get("accent", Color(0.50, 0.88, 1.0)))
	row1.add_child(realm_label)

	weapon_label = Label.new()
	weapon_label.add_theme_font_size_override("font_size", 21)
	row1.add_child(weapon_label)

	health_label = Label.new()
	health_label.add_theme_font_size_override("font_size", 21)
	health_label.add_theme_color_override("font_color", Color(0.95, 0.99, 1.0))
	row1.add_child(health_label)

	var row1_spacer = Control.new()
	row1_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(row1_spacer)

	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.custom_minimum_size = Vector2(112.0, 40.0)
	pause_button.add_theme_font_size_override("font_size", 18)
	_style_upgrade_button(pause_button)
	pause_button.pressed.connect(_on_pause_pressed)
	row1.add_child(pause_button)

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
	core_label.add_theme_color_override("font_color", realm_palette.get("accent", Color(0.50, 0.88, 1.0)))
	row2.add_child(core_label)

	fps_label = Label.new()
	fps_label.add_theme_font_size_override("font_size", 19)
	# Keep FPS visible in editor/debug builds only; it distracts in shipped builds.
	fps_label.visible = OS.is_debug_build()
	row2.add_child(fps_label)

	var row3 = HBoxContainer.new()
	row3.add_theme_constant_override("separation", 16)
	top_vb.add_child(row3)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color(0.89, 0.98, 1.0))
	row3.add_child(stats_label)

	core_bar = ProgressBar.new()
	core_bar.anchor_left = 0.16
	core_bar.anchor_right = 0.84
	core_bar.anchor_top = 1.0
	core_bar.anchor_bottom = 1.0
	core_bar.offset_top = -34.0
	core_bar.offset_bottom = -14.0
	core_bar.min_value = 0.0
	core_bar.show_percentage = false

	core_glow = ColorRect.new()
	core_glow.anchor_left = core_bar.anchor_left
	core_glow.anchor_right = core_bar.anchor_right
	core_glow.anchor_top = core_bar.anchor_top
	core_glow.anchor_bottom = core_bar.anchor_bottom
	core_glow.offset_top = core_bar.offset_top - 5.0
	core_glow.offset_bottom = core_bar.offset_bottom + 5.0
	core_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_col: Color = realm_palette.get("accent", Color(0.50, 0.88, 1.0))
	glow_col.a = 0.0
	core_glow.color = glow_col
	root.add_child(core_glow)

	var core_bg = StyleBoxFlat.new()
	core_bg.bg_color = Color(0.04, 0.08, 0.14, 0.82)
	core_bg.border_color = Color(0.28, 0.49, 0.67, 0.88)
	core_bg.corner_radius_top_left = 9
	core_bg.corner_radius_top_right = 9
	core_bg.corner_radius_bottom_left = 9
	core_bg.corner_radius_bottom_right = 9
	core_bg.border_width_left = 2
	core_bg.border_width_top = 2
	core_bg.border_width_right = 2
	core_bg.border_width_bottom = 2
	core_bar.add_theme_stylebox_override("background", core_bg)

	var core_fill = StyleBoxFlat.new()
	core_fill.bg_color = realm_palette.get("accent", Color(0.50, 0.88, 1.0))
	core_fill.corner_radius_top_left = 9
	core_fill.corner_radius_top_right = 9
	core_fill.corner_radius_bottom_left = 9
	core_fill.corner_radius_bottom_right = 9
	core_bar.add_theme_stylebox_override("fill", core_fill)
	root.add_child(core_bar)

	hint_label = Label.new()
	hint_label.anchor_left = 0.0
	hint_label.anchor_top = 1.0
	hint_label.anchor_right = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_top = -74.0
	hint_label.offset_bottom = -46.0
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.text = "Realm levels are time-gated. Core overloads grant overclock spikes and bank extra upgrade options."
	hint_label.add_theme_color_override("font_color", realm_palette.get("accent_soft", Color(0.60, 0.92, 1.0, 0.9)))
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
	upgrade_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.03, 0.07, 0.13, 0.94), realm_palette.get("panel_border", Color(0.4, 0.8, 1.0)))
	)
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
		_style_upgrade_button(button)
		button.pressed.connect(_on_upgrade_selected.bind(i))
		upgrade_vb.add_child(button)
		upgrade_buttons.append(button)

	# Player-controlled pause overlay (lets Endless runs run for hours without requiring focus).
	pause_overlay = Control.new()
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(pause_overlay)

	var pause_shade = ColorRect.new()
	pause_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_shade.color = Color(0.0, 0.0, 0.0, 0.60)
	pause_overlay.add_child(pause_shade)

	var pause_center = CenterContainer.new()
	pause_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(pause_center)

	var pause_panel = PanelContainer.new()
	pause_panel.custom_minimum_size = Vector2(560.0, 260.0)
	pause_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.03, 0.07, 0.13, 0.94), realm_palette.get("panel_border", Color(0.4, 0.8, 1.0)))
	)
	pause_center.add_child(pause_panel)

	var pause_vb = VBoxContainer.new()
	pause_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_vb.add_theme_constant_override("separation", 12)
	pause_panel.add_child(pause_vb)

	var pause_title = Label.new()
	pause_title.text = "Paused"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_size_override("font_size", 30)
	pause_vb.add_child(pause_title)

	pause_resume_button = Button.new()
	pause_resume_button.text = "Resume"
	pause_resume_button.custom_minimum_size = Vector2(0.0, 56.0)
	pause_resume_button.add_theme_font_size_override("font_size", 20)
	_style_upgrade_button(pause_resume_button)
	pause_resume_button.pressed.connect(_on_pause_resume_pressed)
	pause_vb.add_child(pause_resume_button)

	pause_quit_button = Button.new()
	pause_quit_button.text = "Quit Run (Lose Progress)"
	pause_quit_button.custom_minimum_size = Vector2(0.0, 56.0)
	pause_quit_button.add_theme_font_size_override("font_size", 18)
	_style_upgrade_button(pause_quit_button)
	pause_quit_button.pressed.connect(_on_pause_quit_pressed)
	pause_vb.add_child(pause_quit_button)


func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	style.shadow_size = 5
	return style


func _style_upgrade_button(button: Button) -> void:
	var base = StyleBoxFlat.new()
	base.bg_color = Color(0.07, 0.14, 0.22, 0.96)
	base.border_color = realm_palette.get("panel_border", Color(0.44, 0.82, 1.0))
	base.corner_radius_top_left = 10
	base.corner_radius_top_right = 10
	base.corner_radius_bottom_left = 10
	base.corner_radius_bottom_right = 10
	base.border_width_left = 2
	base.border_width_top = 2
	base.border_width_right = 2
	base.border_width_bottom = 2

	var hover = base.duplicate()
	hover.bg_color = Color(0.11, 0.22, 0.33, 0.98)

	var pressed = base.duplicate()
	pressed.bg_color = Color(0.13, 0.26, 0.39, 0.98)

	var disabled = base.duplicate()
	disabled.bg_color = Color(0.07, 0.09, 0.13, 0.86)
	disabled.border_color = Color(0.23, 0.32, 0.42, 0.74)

	button.add_theme_stylebox_override("normal", base)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.93, 0.99, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.63, 0.70, 0.79))


func _spawn_player() -> void:
	player = PlayerScript.new()
	player.apply_hero(selected_hero)
	world_root.add_child(player)
	player.global_position = arena_rect.get_center()
	player.set_arena_rect(arena_rect)
	player.died.connect(_on_player_died)
	player.hp_changed.connect(_on_player_hp_changed)
	player.damaged.connect(_on_player_damaged)
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
	camera_base_offset = camera.offset
	camera_base_zoom = camera.zoom
	player_last_pos = player.global_position

	if DisplayServer.get_name() != "headless":
		var light = PointLight2D.new()
		light.texture = _get_cached_light_texture()
		light.color = realm_palette.get("accent", Color(0.49, 0.88, 1.0))
		light.energy = 0.85
		light.texture_scale = 4.2
		light.z_index = -5
		player.add_child(light)


func _apply_meta_modifiers() -> void:
	player.max_hp *= float(meta_mods.get("max_hp_mult", 1.0))
	player.current_hp = player.max_hp
	player.damage *= float(meta_mods.get("damage_mult", 1.0))
	player.fire_rate *= float(meta_mods.get("fire_rate_mult", 1.0))
	player.move_speed *= float(meta_mods.get("move_speed_mult", 1.0))
	player.damage_taken_multiplier *= float(meta_mods.get("damage_taken_mult", 1.0))
	player.regen_per_second += float(meta_mods.get("regen_per_sec", 0.0))
	player.surge_damage *= float(meta_mods.get("surge_damage_mult", 1.0))

	crit_chance = clamp(crit_chance + float(meta_mods.get("crit_bonus", 0.0)), 0.0, 1.0)
	player.pickup_magnet_radius += float(meta_mods.get("magnet_bonus", 0.0))
	player.regen_per_second += float(meta_mods.get("regen_bonus", 0.0))
	player.projectile_pierce = clamp(int(player.projectile_pierce) + int(meta_mods.get("pierce_bonus", 0)), 0, 10)

	core_gain_multiplier *= float(meta_mods.get("core_gain_mult", 1.0))
	mastery_gain_multiplier *= float(meta_mods.get("mastery_gain_mult", 1.0))
	duplicate_shot_chance += float(meta_mods.get("duplicate_attack_chance", 0.0))
	draft_choices += int(meta_mods.get("extra_draft_choices", 0))
	draft_choices = clamp(draft_choices, 3, 6)


func _warm_pools() -> void:
	for i in range(ENEMY_POOL_SIZE):
		var enemy = EnemyScript.new()
		enemy.died.connect(_on_enemy_died)
		enemy.wants_shot.connect(_on_enemy_wants_shot)
		world_root.add_child(enemy)
		enemy_pool.append(enemy)

	for i in range(PROJECTILE_POOL_SIZE):
		var projectile = ProjectileScript.new()
		projectile.hit_target.connect(_on_projectile_hit_target)
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

	if paused_for_upgrade or paused_by_player:
		_sync_hud()
		return

	if hitstop_active:
		hitstop_timer = max(0.0, hitstop_timer - delta)
		if hitstop_timer <= 0.0:
			hitstop_active = false
			_set_simulation_paused(false)
		_sync_hud()
		return

	hit_sfx_cooldown = max(0.0, hit_sfx_cooldown - delta)
	crit_sfx_cooldown = max(0.0, crit_sfx_cooldown - delta)
	enemy_die_sfx_cooldown = max(0.0, enemy_die_sfx_cooldown - delta)
	step_sfx_cooldown = max(0.0, step_sfx_cooldown - delta)
	overclock_timer = max(0.0, overclock_timer - delta)

	elapsed_time += delta
	if run_duration > 0.0 and elapsed_time >= run_duration:
		elapsed_time = run_duration
		_finish_run(true)
		return

	_update_level_progression()
	_update_spawning(delta)
	_update_auto_fire(delta)
	_update_laser(delta)
	_update_boss(delta)
	_update_footsteps(delta)

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

	if paused_by_player:
		queue_redraw()
		if fps_label != null and fps_label.visible:
			fps_label.text = "FPS %d" % Engine.get_frames_per_second()
		return

	if not paused_for_upgrade and not hitstop_active:
		_tick_effects(surge_effects, delta)
		_tick_effects(beam_effects, delta)
		_tick_effects(muzzle_effects, delta)
		_tick_effects(impact_effects, delta)
		_tick_particles(delta)
		_tick_floating_texts(delta)

	shake_intensity = max(0.0, shake_intensity - delta * 18.0)
	zoom_kick = max(0.0, zoom_kick - delta * 3.4)
	if camera != null:
		var t = elapsed_time * 46.0 + shake_seed
		var shake_vec = Vector2(
			sin(t) + sin(t * 1.77 + 1.3),
			cos(t * 1.12) + sin(t * 2.11 + 2.1)
		) * 0.5
		camera.offset = camera_base_offset + shake_vec * shake_intensity
		var zoom_amount = 1.0 + 0.016 * zoom_kick
		camera.zoom = camera_base_zoom * zoom_amount

	screen_flash_strength = max(0.0, screen_flash_strength - delta * 3.8)
	if screen_flash_rect != null:
		var col = screen_flash_color
		col.a = screen_flash_strength * 0.32
		screen_flash_rect.color = col

	core_glow_pulse = max(0.0, core_glow_pulse - delta * 4.4)
	if core_glow != null:
		var glow_col = core_glow.color
		glow_col.a = core_glow_pulse * 0.36
		core_glow.color = glow_col

	if upgrade_panel != null and upgrade_panel.visible:
		upgrade_anim_t = min(1.0, upgrade_anim_t + delta * 9.0)
		var e = 1.0 - pow(1.0 - upgrade_anim_t, 3.0)
		upgrade_panel.scale = Vector2.ONE * lerp(0.94, 1.0, e)
		var m = upgrade_panel.modulate
		m.a = e
		upgrade_panel.modulate = m

	if music_player != null and music_player.stream != null and not music_player.playing:
		music_player.play()
	if ambient_player != null and ambient_player.stream != null and not ambient_player.playing:
		ambient_player.play()

	# Reactive mix: bosses + overclock intensify music and tuck ambience slightly.
	var boss_active = boss_ref != null and is_instance_valid(boss_ref) and bool(boss_ref.is_active)
	var hp_ratio = 1.0
	if player != null and is_instance_valid(player):
		hp_ratio = float(player.current_hp) / max(1.0, float(player.max_hp))

	var target_music = 0.0
	var target_ambient = 0.0
	# Level style can bias the mix to avoid repetitive soundscapes.
	target_music += level_mix_music_db
	target_ambient += level_mix_ambient_db
	if boss_active:
		target_music += 3.0
		target_ambient -= 5.0
	if overclock_timer > 0.0:
		target_music += 1.6
		target_ambient += 0.8
	if hp_ratio <= 0.30:
		target_music -= 1.2
		target_ambient -= 2.4

	var k = 1.0 - exp(-delta * 4.0)
	music_dynamic_offset_db = lerp(music_dynamic_offset_db, target_music, k)
	ambient_dynamic_offset_db = lerp(ambient_dynamic_offset_db, target_ambient, k)

	if music_player != null and music_player.stream != null:
		music_player.volume_db = music_base_volume_db + music_dynamic_offset_db + _linear_to_db_safe(music_volume_linear)
	if ambient_player != null and ambient_player.stream != null:
		ambient_player.volume_db = ambient_base_volume_db + ambient_dynamic_offset_db + _linear_to_db_safe(music_volume_linear)

	if fog_material != null:
		var fog_boost = 1.28 if boss_active else 1.0
		fog_material.set_shader_parameter("intensity", fog_base_intensity * access_bg_intensity * fog_boost * level_fog_mult)

	queue_redraw()
	if fps_label != null and fps_label.visible:
		fps_label.text = "FPS %d" % Engine.get_frames_per_second()


func _tick_effects(effects: Array, delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		var fx: Dictionary = effects[i]
		fx["time"] = float(fx["time"]) + delta
		effects[i] = fx
		if float(fx["time"]) >= float(fx["duration"]):
			effects.remove_at(i)


func _tick_particles(delta: float) -> void:
	for i in range(particle_effects.size() - 1, -1, -1):
		var p: Dictionary = particle_effects[i]
		p["time"] = float(p.get("time", 0.0)) + delta
		var ratio = float(p["time"]) / max(0.001, float(p.get("duration", 0.2)))
		if ratio >= 1.0:
			particle_effects.remove_at(i)
			continue

		var vel = p.get("vel", Vector2.ZERO) as Vector2
		p["pos"] = (p.get("pos", Vector2.ZERO) as Vector2) + vel * delta
		var drag = float(p.get("drag", 6.0))
		p["vel"] = vel * max(0.0, 1.0 - drag * delta)
		particle_effects[i] = p


func _tick_floating_texts(delta: float) -> void:
	for i in range(floating_texts.size() - 1, -1, -1):
		var fx: Dictionary = floating_texts[i]
		fx["time"] = float(fx.get("time", 0.0)) + delta
		var ratio = float(fx["time"]) / max(0.001, float(fx.get("duration", 0.6)))
		if ratio >= 1.0:
			floating_texts.remove_at(i)
			continue

		var vel = fx.get("vel", Vector2.ZERO) as Vector2
		fx["pos"] = (fx.get("pos", Vector2.ZERO) as Vector2) + vel * delta
		fx["vel"] = vel * (1.0 - min(0.9, 3.5 * delta))
		floating_texts[i] = fx


func _spawn_particles(
	origin: Vector2,
	color: Color,
	count: int,
	speed_min: float,
	speed_max: float,
	size_min: float,
	size_max: float,
	duration: float
) -> void:
	if count <= 0:
		return
	if reduced_particles:
		count = max(1, int(ceil(float(count) * 0.45)))
		duration *= 0.85

	var max_particles = 160 if reduced_particles else 280
	while particle_effects.size() > max_particles:
		particle_effects.remove_at(0)

	for i in range(count):
		var dir = Vector2.RIGHT.rotated(randf() * TAU)
		var speed = randf_range(speed_min, speed_max)
		var vel = dir * speed
		var c = color
		c.a *= randf_range(0.55, 0.95)
		particle_effects.append({
			"pos": origin + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)),
			"vel": vel,
			"drag": randf_range(4.0, 9.0),
			"size": randf_range(size_min, size_max),
			"color": c,
			"time": 0.0,
			"duration": duration * randf_range(0.85, 1.15)
		})


func _spawn_floating_text(origin: Vector2, text: String, color: Color, font_size: int, duration: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if text == "":
		return
	if reduced_particles:
		font_size = int(round(float(font_size) * 0.9))

	var cap = 36 if reduced_particles else 72
	while floating_texts.size() > cap:
		floating_texts.remove_at(0)

	var size = clamp(font_size, 12, 38)
	var font = ThemeDB.fallback_font
	var width = 0.0
	if font != null:
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		width = text_size.x * 0.5

	floating_texts.append({
		"pos": origin,
		"vel": Vector2(randf_range(-10.0, 10.0), randf_range(-44.0, -72.0)),
		"text": text,
		"color": color,
		"size": size,
		"half_w": width,
		"time": 0.0,
		"duration": max(0.18, duration)
	})

func _draw() -> void:
	var bg_a: Color = realm_palette.get("bg_a", Color(0.05, 0.14, 0.22))
	var bg_b: Color = realm_palette.get("bg_b", Color(0.08, 0.24, 0.34))
	var bg_c: Color = realm_palette.get("bg_c", Color(0.05, 0.10, 0.17))
	var bg_d: Color = realm_palette.get("bg_d", Color(0.09, 0.16, 0.25))
	var accent: Color = realm_palette.get("accent", Color(0.49, 0.88, 1.0))
	var star_color: Color = realm_palette.get("star", Color(0.84, 0.98, 1.0, 0.82))
	var grid_base: Color = realm_palette.get("grid", Color(0.65, 0.88, 0.99, 0.11))
	var pulse = 0.5 + 0.5 * sin(elapsed_time * 0.46)

	var bg_dim = clamp(1.0 - access_bg_intensity, 0.0, 0.75)
	var bg_a_dim = bg_a.darkened(bg_dim)
	var bg_b_dim = bg_b.darkened(bg_dim)
	var bg_c_dim = bg_c.darkened(bg_dim)
	var bg_d_dim = bg_d.darkened(bg_dim)
	var bg_accent = accent.darkened(bg_dim * 0.45)

	_draw_gradient_rect(arena_rect, bg_a_dim, bg_b_dim, bg_c_dim, bg_d_dim)

	var center = arena_rect.get_center()
	for cloud in nebula_clouds:
		var cloud_phase = float(cloud["phase"])
		var cloud_speed = float(cloud["speed"])
		var drift = float(cloud["drift"])
		var wobble = Vector2(
			cos(elapsed_time * cloud_speed + cloud_phase),
			sin(elapsed_time * (cloud_speed * 1.33) + cloud_phase * 0.7)
		) * drift
		var pos = center + (cloud["offset"] as Vector2) + wobble
		var radius = float(cloud["radius"]) * (0.95 + 0.12 * sin(elapsed_time * (cloud_speed * 3.0) + cloud_phase))
		var alpha = float(cloud["alpha"]) * (0.72 + pulse * 0.28) * access_bg_intensity
		var cloud_color = bg_accent
		cloud_color.a = alpha
		draw_circle(pos, radius, cloud_color)

	# Realm-specific background motifs.
	if not rift_rings.is_empty():
		for ring in rift_rings:
			var phase_r = float(ring["phase"])
			var speed_r = float(ring["speed"])
			var t_r = elapsed_time * speed_r + phase_r
			var arc_radius = float(ring["radius"]) * (0.96 + 0.05 * sin(t_r * 1.7))
			var pos_r = center + (ring["offset"] as Vector2)
			var col_r = bg_accent
			col_r.a = float(ring["alpha"]) * (0.65 + pulse * 0.35) * access_bg_intensity
			draw_arc(pos_r, arc_radius, t_r, t_r + PI * 1.35, 48, col_r, float(ring["thickness"]))

	if not void_cracks.is_empty():
		for crack in void_cracks:
			var phase_c = float(crack["phase"])
			var speed_c = float(crack["speed"])
			var wobble_c = sin(elapsed_time * speed_c + phase_c) * 10.0
			var start_c: Vector2 = crack["start"]
			var end_c: Vector2 = crack["end"]
			var dir_c = (end_c - start_c).normalized()
			var perp_c = Vector2(-dir_c.y, dir_c.x)
			var offset_c = perp_c * wobble_c
			var col_c = bg_accent
			col_c.a = float(crack["alpha"]) * (0.55 + pulse * 0.45) * access_bg_intensity
			draw_line(start_c + offset_c, end_c + offset_c, col_c, float(crack["width"]))

	if not aurora_bands.is_empty():
		for band in aurora_bands:
			var phase_a = float(band["phase"])
			var speed_a = float(band["speed"])
			var t_a = elapsed_time * speed_a + phase_a
			var arc_radius_a = float(band["radius"]) * (0.95 + 0.06 * sin(t_a * 1.3))
			var pos_a = center + (band["offset"] as Vector2)
			var col_a: Color = accent
			col_a.a = float(band["alpha"]) * (0.60 + pulse * 0.40) * access_bg_intensity
			draw_arc(pos_a, arc_radius_a, -PI * 0.80 + sin(t_a) * 0.18, PI * 0.80 + sin(t_a + 1.2) * 0.18, 44, col_a, float(band["thickness"]))

	for star in twinkle_stars:
		var twinkle = 0.45 + 0.55 * sin(elapsed_time * float(star["speed"]) + float(star["phase"]))
		var col = star_color
		col.a = float(star["alpha"]) * twinkle * access_bg_intensity
		draw_circle(star["position"], float(star["radius"]), col)

	for x in range(0, int(ARENA_SIZE.x) + 1, 48):
		var major_x = x % 96 == 0
		var col_x = grid_base
		col_x.a = (0.08 if major_x else 0.04) * (0.70 + pulse * 0.30) * access_bg_intensity
		draw_line(Vector2(x, 0), Vector2(x, ARENA_SIZE.y), col_x, 1.0 if major_x else 0.6)

	for y in range(0, int(ARENA_SIZE.y) + 1, 48):
		var major_y = y % 96 == 0
		var col_y = grid_base
		col_y.a = (0.08 if major_y else 0.04) * (0.70 + pulse * 0.30) * access_bg_intensity
		draw_line(Vector2(0, y), Vector2(ARENA_SIZE.x, y), col_y, 1.0 if major_y else 0.6)

	var border_col = bg_accent
	border_col.a = 0.66 * access_bg_intensity
	draw_rect(arena_rect, border_col, false, 7.0)
	var outer = border_col
	outer.a = 0.22 * access_bg_intensity
	draw_rect(arena_rect.grow(7.0), outer, false, 2.0)

	for fx in beam_effects:
		var ratio = clamp(float(fx["time"]) / float(fx["duration"]), 0.0, 1.0)
		var alpha = 1.0 - ratio
		var width = float(fx["width"]) * (1.0 - ratio * 0.28)
		var beam_base: Color = accent
		if fx.has("color"):
			beam_base = fx["color"]
		var beam_outer = beam_base
		beam_outer.a = alpha * 0.58
		var beam_inner_base = Color(0.94, 0.99, 1.0)
		if fx.has("inner_color"):
			beam_inner_base = fx["inner_color"]
		var beam_inner = beam_inner_base
		beam_inner.a = alpha * 0.94
		draw_line(fx["from"], fx["to"], beam_outer, width + 8.0)
		draw_line(fx["from"], fx["to"], beam_inner, width * 0.52)

	for fx in surge_effects:
		var duration = float(fx["duration"])
		var time = float(fx["time"])
		var ratio = clamp(time / duration, 0.0, 1.0)
		var max_radius = float(fx["radius"])
		var radius = lerp(max_radius * 0.22, max_radius, ratio)
		var alpha = 1.0 - ratio
		var surge_outer = accent
		surge_outer.a = alpha * 0.58
		var surge_inner = Color(0.98, 1.0, 1.0, alpha * 0.85)
		draw_arc(fx["origin"], radius, 0.0, TAU, 54, surge_outer, 5.0)
		draw_arc(fx["origin"], radius * 0.72, 0.0, TAU, 40, surge_inner, 2.0)

	for fx in muzzle_effects:
		var ratio_m = clamp(float(fx["time"]) / float(fx["duration"]), 0.0, 1.0)
		var alpha_m = 0.72 * (1.0 - ratio_m)
		var radius_m = lerp(20.0, 42.0, ratio_m)
		var muzzle_col = Color(0.95, 0.98, 1.0, alpha_m)
		draw_arc(fx["origin"], radius_m, fx["angle"] - 0.25, fx["angle"] + 0.25, 10, muzzle_col, 4.0)

	for fx in impact_effects:
		var ratio_i = clamp(float(fx["time"]) / float(fx["duration"]), 0.0, 1.0)
		var radius_i = lerp(float(fx["radius"]) * 0.24, float(fx["radius"]), ratio_i)
		var alpha_i = 1.0 - ratio_i
		var col_i = fx["color"]
		col_i.a = alpha_i * 0.70
		draw_arc(fx["origin"], radius_i, 0.0, TAU, 20, col_i, 2.4)
		col_i.a = alpha_i * 0.24
		draw_circle(fx["origin"], radius_i * 0.32, col_i)


func _draw_gradient_rect(rect: Rect2, top_left: Color, top_right: Color, bottom_right: Color, bottom_left: Color) -> void:
	var points = PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	])
	var colors = PackedColorArray([top_left, top_right, bottom_right, bottom_left])
	draw_polygon(points, colors)


func _update_level_progression() -> void:
	if run_is_endless:
		while elapsed_time >= endless_next_level_time:
			level += 1
			_apply_level_style(level)
			for i in range(picks_per_level):
				_queue_upgrade("level")
			endless_next_level_time += ENDLESS_LEVEL_INTERVAL
			_play_sfx("levelup", -10.0)
		return

	while level < run_max_level:
		var next_level = level + 1
		var gate_time = float(LEVEL_TIME_GATES[next_level - 1])
		if elapsed_time < gate_time:
			break
		level = next_level
		_apply_level_style(level)
		for i in range(picks_per_level):
			_queue_upgrade("level")
		_maybe_spawn_boss(level)
		_play_sfx("levelup", -8.0)


func _maybe_spawn_boss(level_reached: int) -> void:
	if run_is_endless:
		return
	if level_reached != 5 and level_reached != 10 and level_reached != 15:
		return
	if boss_spawned_levels.has(level_reached):
		return
	boss_spawned_levels[level_reached] = true

	# Keep encounters readable: only one boss at a time.
	if boss_ref != null and is_instance_valid(boss_ref) and boss_ref.is_active:
		return

	var enemy = _acquire_enemy()
	if enemy == null:
		return

	var cfg = _boss_config(level_reached)
	var spawn_pos = _random_spawn_position()
	enemy.activate(spawn_pos, player, cfg)
	active_enemies.append(enemy)
	boss_ref = enemy
	boss_level = level_reached
	boss_name = String(cfg.get("boss_name", "Boss"))
	boss_special_timer = 1.6
	boss_ring_timer = 2.8
	boss_beam_fire_timer = 0.0
	boss_beam_target_angle = 0.0
	boss_beam_damage_cooldown = 0.0
	boss_slam_windup = 0.0
	boss_slam_origin = spawn_pos
	boss_slam_radius = 150.0

	_spawn_impact(spawn_pos, realm_palette.get("accent", Color(0.49, 0.88, 1.0)), 130.0, 0.30)
	_spawn_particles(spawn_pos, realm_palette.get("accent", Color(0.49, 0.88, 1.0)), 18, 70.0, 240.0, 1.6, 3.0, 0.50)
	_play_sfx("boss_roar", -10.0)

	if boss_panel != null:
		boss_panel.visible = show_boss_hp_bar


func _boss_config(level_reached: int) -> Dictionary:
	var tier = 1
	var archetype = "boss_5"
	var boss_display_name = "Core Brute"
	match level_reached:
		5:
			tier = 1
			archetype = "boss_5"
			boss_display_name = "Shiver Hulk"
		10:
			tier = 2
			archetype = "boss_10"
			boss_display_name = "Rift Arcanist"
		15:
			tier = 3
			archetype = "boss_15"
			boss_display_name = "Vault Sovereign"
		_:
			tier = 1

	var progression = float(level_reached - 1) / float(MAX_REALM_LEVEL - 1)
	var hp = 950.0 + 1800.0 * progression + float(tier) * 420.0
	var speed = 74.0 + 22.0 * progression
	var damage = 12.0 + 8.0 * progression + float(tier) * 1.6
	var xp = 95.0 + float(tier) * 35.0
	var radius = 38.0 if tier >= 3 else (34.0 if tier == 2 else 30.0)

	hp *= float(realm_mods.get("enemy_hp", 1.0))
	speed *= float(realm_mods.get("enemy_speed", 1.0))
	damage *= float(realm_mods.get("enemy_damage", 1.0))

	var shoot_interval = 0.0
	var projectile_damage = 0.0
	var projectile_speed = 420.0
	var projectile_radius = 6.0
	var projectile_lifetime = 2.5
	var dash_interval = 0.0
	var dash_duration = 0.0
	var dash_multiplier = 1.0

	match archetype:
		"boss_5":
			shoot_interval = 1.15
			projectile_damage = damage * 0.80
			projectile_speed = 410.0
			projectile_radius = 6.0
			dash_interval = 1.65
			dash_duration = 0.36
			dash_multiplier = 2.8
		"boss_10":
			shoot_interval = 0.85
			projectile_damage = damage * 0.75
			projectile_speed = 390.0
			projectile_radius = 6.4
			projectile_lifetime = 2.7
		"boss_15":
			shoot_interval = 1.05
			projectile_damage = damage * 0.72
			projectile_speed = 410.0
			projectile_radius = 6.6
			projectile_lifetime = 2.8
			dash_interval = 2.25
			dash_duration = 0.30
			dash_multiplier = 2.2
		_:
			pass

	var body_color: Color = realm_palette.get("enemy_elite", Color(1.0, 0.58, 0.64))
	var eye_color = Color(0.06, 0.02, 0.04)
	if archetype == "boss_15":
		body_color = body_color.lerp(realm_palette.get("accent", Color(0.49, 0.88, 1.0)), 0.22)

	return {
		"archetype": archetype,
		"boss": true,
		"boss_tier": tier,
		"boss_name": boss_display_name,
		"hp": hp,
		"speed": speed,
		"damage": damage,
		"xp": xp,
		"radius": radius,
		"elite": false,
		"scale": 1.0,
		"body_color": body_color,
		"eye_color": eye_color,
		"face_variant": current_face_variant,
		"face_seed": randi(),
		"shoot_interval": shoot_interval,
		"projectile_damage": projectile_damage,
		"projectile_speed": projectile_speed,
		"projectile_radius": projectile_radius,
		"projectile_lifetime": projectile_lifetime,
		"dash_interval": dash_interval,
		"dash_duration": dash_duration,
		"dash_multiplier": dash_multiplier
	}


func _queue_upgrade(reason: String) -> void:
	if upgrade_picks_used >= max_upgrade_picks_per_run:
		return
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
	var interval = 1.0
	if run_is_endless:
		var p = clamp(float(level - 1) / 90.0, 0.0, 1.0)
		interval = lerp(1.55, 0.95, p)
		interval *= float(realm_mods.get("spawn_interval", 1.0))
		return clamp(interval, 0.70, 2.2)

	interval = 1.42 - float(level - 1) * 0.07
	interval -= elapsed_time * 0.00022
	interval *= float(realm_mods.get("spawn_interval", 1.0))
	# Levels 11-15 should feel far more dense; 1-10 only slightly.
	interval *= 0.98 if level <= 10 else 0.85
	return clamp(interval, 0.18, 2.0)


func _enemy_cap() -> int:
	var cap = 0
	if run_is_endless:
		cap = 60 + int(min(level, 80))  # gently rises, but stays playable for hours.
		return min(MAX_ACTIVE_ENEMIES, cap)

	cap = 50 + level * 10 + int(elapsed_time * 0.03)
	return min(MAX_ACTIVE_ENEMIES, cap)


func _spawn_enemy_batch() -> void:
	if active_enemies.size() >= _enemy_cap():
		return

	var batch_size = 1
	if run_is_endless:
		if randf() < 0.22:
			batch_size += 1
		if level >= 40 and randf() < 0.10:
			batch_size += 1
	else:
		batch_size = 1 + int(float(level - 1) / 4.0)
		if level >= 11:
			batch_size += 1
		if randf() < (0.20 + float(level - 1) * 0.015):
			batch_size += 1
		if level >= 11 and randf() < 0.24:
			batch_size += 1

	for i in range(batch_size):
		if active_enemies.size() >= _enemy_cap():
			return

		var archetype = _pick_enemy_archetype()
		var spawn_pos = _random_spawn_position()

		if archetype == "pack":
			var pack_count = 3
			if run_is_endless:
				pack_count = 2
				if level >= 40 and randf() < 0.18:
					pack_count = 3
			elif level >= 12 and randf() < 0.35:
				pack_count = 4
			for j in range(pack_count):
				if active_enemies.size() >= _enemy_cap():
					return
				var offset = Vector2(randf_range(-44.0, 44.0), randf_range(-44.0, 44.0))
				var pos = spawn_pos + offset
				pos.x = clamp(pos.x, arena_rect.position.x + 22.0, arena_rect.end.x - 22.0)
				pos.y = clamp(pos.y, arena_rect.position.y + 22.0, arena_rect.end.y - 22.0)
				_spawn_enemy_instance("pack", false, pos)
			continue

		var elite_chance = (0.02 + float(level - 1) * 0.014) * float(realm_mods.get("elite_rate", 1.0))
		if archetype == "sprinter" or archetype == "shooter" or archetype == "splitter":
			elite_chance *= 0.55
		var elite = randf() < min(0.34, elite_chance)
		if archetype == "shooter" or archetype == "splitter":
			elite = false

		_spawn_enemy_instance(archetype, elite, spawn_pos)


func _pick_enemy_archetype() -> String:
	var r = randf()
	if run_is_endless:
		# Endless mixes enemies with no level-gated pattern and stays forgiving.
		if r < 0.55:
			return "grunt"
		if r < 0.70:
			return "sprinter"
		if r < 0.84:
			return "pack"
		if r < 0.92:
			return "bulwark"
		if r < 0.96:
			return "shooter"
		if r < 0.985:
			return "stalker"
		return "splitter"

	# Level-to-level variety: bias one "featured" archetype when it is unlocked.
	if featured_archetype != "" and _is_archetype_unlocked(featured_archetype) and randf() < 0.22:
		return featured_archetype

	if realm_id == "umbra_vault":
		# Umbra adds a new archetype: stalkers that dash in bursts.
		if level >= 15:
			if r < 0.38:
				return "grunt"
			if r < 0.52:
				return "sprinter"
			if r < 0.64:
				return "stalker"
			if r < 0.78:
				return "bulwark"
			if r < 0.88:
				return "pack"
			if r < 0.95:
				return "shooter"
			return "splitter"

		if level >= 12:
			if r < 0.44:
				return "grunt"
			if r < 0.60:
				return "sprinter"
			if r < 0.72:
				return "stalker"
			if r < 0.84:
				return "bulwark"
			if r < 0.93:
				return "pack"
			return "shooter"

		if level >= 9:
			if r < 0.50:
				return "grunt"
			if r < 0.68:
				return "sprinter"
			if r < 0.80:
				return "stalker"
			if r < 0.90:
				return "bulwark"
			return "pack"

		if level >= 6:
			if r < 0.64:
				return "grunt"
			if r < 0.84:
				return "sprinter"
			return "stalker"

		if level >= 3:
			return "grunt" if r < 0.75 else "sprinter"

		return "grunt"

	if level >= 15:
		if r < 0.42:
			return "grunt"
		if r < 0.58:
			return "sprinter"
		if r < 0.72:
			return "bulwark"
		if r < 0.84:
			return "pack"
		if r < 0.94:
			return "shooter"
		return "splitter"

	if level >= 12:
		if r < 0.48:
			return "grunt"
		if r < 0.64:
			return "sprinter"
		if r < 0.78:
			return "bulwark"
		if r < 0.90:
			return "pack"
		return "shooter"

	if level >= 9:
		if r < 0.55:
			return "grunt"
		if r < 0.72:
			return "sprinter"
		if r < 0.88:
			return "bulwark"
		return "pack"

	if level >= 6:
		if r < 0.65:
			return "grunt"
		if r < 0.83:
			return "sprinter"
		return "bulwark"

	if level >= 3:
		return "grunt" if r < 0.80 else "sprinter"

	return "grunt"


func _is_archetype_unlocked(archetype: String) -> bool:
	match archetype:
		"grunt":
			return true
		"sprinter":
			return level >= 3
		"bulwark":
			return level >= 6
		"pack":
			return level >= 9
		"shooter":
			return level >= 12
		"stalker":
			return realm_id == "umbra_vault" and level >= 6
		"splitter":
			return level >= 15
		_:
			return false


func _spawn_enemy_instance(archetype: String, elite: bool, spawn_pos: Vector2) -> void:
	var enemy = _acquire_enemy()
	if enemy == null:
		return

	var cfg = _enemy_config(elite, archetype)
	enemy.activate(spawn_pos, player, cfg)
	active_enemies.append(enemy)


func _enemy_config(elite: bool, archetype: String = "grunt") -> Dictionary:
	var progression = float(level - 1) / float(MAX_REALM_LEVEL - 1)
	if run_is_endless:
		# Endless should stay easy for very long sessions.
		progression = min(0.35, float(level - 1) / 220.0)

	var hp = lerp(22.0, 165.0, progression)
	if not run_is_endless:
		hp += elapsed_time * 0.06
	var speed = lerp(64.0, 138.0, progression)
	var damage = lerp(3.2, 18.5, progression)
	var xp = lerp(4.0, 14.0, progression)
	var radius = 14.0
	var scale_factor = 1.0
	var body_color: Color = realm_palette.get("enemy", Color(0.88, 0.36, 0.42))
	var elite_color: Color = realm_palette.get("enemy_elite", Color(1.0, 0.56, 0.52))
	var eye_color = Color(0.10, 0.05, 0.08)
	var shoot_interval = 0.0
	var projectile_damage = 0.0
	var projectile_speed = 380.0
	var projectile_radius = 5.0
	var projectile_lifetime = 2.2
	var dash_interval = 0.0
	var dash_duration = 0.0
	var dash_multiplier = 1.0

	hp *= float(realm_mods.get("enemy_hp", 1.0))
	speed *= float(realm_mods.get("enemy_speed", 1.0))
	damage *= float(realm_mods.get("enemy_damage", 1.0))

	match archetype:
		"sprinter":
			hp *= 0.80
			speed *= 1.55
			damage *= 0.90
			xp *= 1.05
			radius = 12.5
			scale_factor *= 0.95
			body_color = body_color.lerp(Color(0.98, 1.0, 0.86), 0.22)
		"bulwark":
			hp *= 2.25
			speed *= 0.78
			damage *= 1.25
			xp *= 1.35
			radius = 20.0
			scale_factor *= 1.25
			body_color = body_color.lerp(Color(0.62, 0.92, 1.0), 0.25)
		"pack":
			hp *= 0.62
			speed *= 1.18
			damage *= 0.82
			xp *= 0.78
			radius = 12.0
			scale_factor *= 0.92
			body_color = body_color.lerp(Color(0.86, 0.54, 0.92), 0.22)
		"shooter":
			hp *= 1.25
			speed *= 0.85
			damage *= 0.72
			xp *= 1.30
			radius = 15.5
			scale_factor *= 1.05
			body_color = body_color.lerp(Color(1.0, 0.63, 0.56), 0.16)
			shoot_interval = lerp(2.55, 1.30, progression)
			projectile_damage = damage * 0.92
			projectile_speed = 360.0 + progression * 80.0
			projectile_radius = 5.2
			projectile_lifetime = 2.35
		"splitter":
			hp *= 1.50
			speed *= 0.92
			damage *= 1.05
			xp *= 1.55
			radius = 16.2
			scale_factor *= 1.10
			body_color = body_color.lerp(Color(0.74, 0.98, 0.92), 0.22)
		"stalker":
			hp *= 1.05
			speed *= 1.20
			damage *= 1.15
			xp *= 1.45
			radius = 13.8
			scale_factor *= 1.02
			body_color = body_color.lerp(Color(0.78, 0.86, 1.0), 0.28)
			dash_interval = lerp(2.25, 1.35, progression)
			dash_duration = 0.26
			dash_multiplier = 2.35
		"splitling":
			hp *= 0.45
			speed *= 1.35
			damage *= 0.75
			xp *= 0.25
			radius = 11.0
			scale_factor *= 0.82
			body_color = body_color.lerp(Color(0.82, 1.0, 0.90), 0.25)

	if elite:
		hp *= 2.9
		speed *= 1.13
		damage *= 1.60
		xp *= 2.4
		radius = 18.0
		scale_factor = 1.2
		body_color = elite_color

	if run_is_endless:
		hp *= 0.85
		damage *= 0.75
	else:
		# Requested run balance: levels 1-10 are tougher (+50% HP),
		# and levels 11-15 are much tougher (double HP).
		hp *= 1.5 if level <= 10 else 2.0

	body_color = body_color.lerp(Color(1.0, 1.0, 1.0), randf_range(0.0, 0.08))

	return {
		"archetype": archetype,
		"hp": hp,
		"speed": speed,
		"damage": damage,
		"xp": xp,
		"radius": radius,
		"elite": elite,
		"scale": scale_factor,
		"body_color": body_color,
		"eye_color": eye_color,
		"face_variant": current_face_variant,
		"face_seed": randi(),
		"show_hp_bar": show_enemy_hp_bars,
		"shoot_interval": shoot_interval,
		"projectile_damage": projectile_damage,
		"projectile_speed": projectile_speed,
		"projectile_radius": projectile_radius,
		"projectile_lifetime": projectile_lifetime,
		"dash_interval": dash_interval,
		"dash_duration": dash_duration,
		"dash_multiplier": dash_multiplier
	}


func _random_spawn_position() -> Vector2:
	var angle = randf() * TAU
	var distance = randf_range(spawn_distance_min, spawn_distance_max)

	match level_spawn_mode:
		1:
			# Sides: comes in like lanes, pushes lateral dodging.
			var base = float(randi() % 4) * (PI * 0.5)
			angle = base + randf_range(-0.28, 0.28)
		2:
			# Corners: diagonal pressure.
			var base = (PI * 0.25) + float(randi() % 4) * (PI * 0.5)
			angle = base + randf_range(-0.24, 0.24)
		3:
			# Split axis: alternating crossfire (east-west vs north-south).
			if spawn_split_axis == 0:
				angle = (0.0 if randf() < 0.5 else PI) + randf_range(-0.30, 0.30)
			else:
				angle = (PI * 0.5 if randf() < 0.5 else -PI * 0.5) + randf_range(-0.30, 0.30)
		_:
			pass

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


func _update_laser(delta: float) -> void:
	if not laser_enabled:
		return

	laser_timer -= delta
	var safety = 0
	while laser_timer <= 0.0 and safety < 2:
		safety += 1
		laser_timer += laser_interval
		_fire_prism_laser()


func _update_boss(delta: float) -> void:
	if run_is_endless:
		return

	if boss_beam_damage_cooldown > 0.0:
		boss_beam_damage_cooldown = max(0.0, boss_beam_damage_cooldown - delta)
	if boss_beam_fire_timer > 0.0:
		boss_beam_fire_timer = max(0.0, boss_beam_fire_timer - delta)

	if boss_ref == null or (not is_instance_valid(boss_ref)) or (not boss_ref.is_active):
		return

	boss_special_timer = max(0.0, boss_special_timer - delta)
	boss_ring_timer = max(0.0, boss_ring_timer - delta)

	var origin = boss_ref.global_position
	var danger: Color = realm_palette.get("danger", Color(1.0, 0.36, 0.50))
	var accent: Color = realm_palette.get("accent", Color(0.49, 0.88, 1.0))

	if boss_level == 5:
		# Windup makes the slam readable and fair.
		if boss_slam_windup > 0.0:
			boss_slam_windup = max(0.0, boss_slam_windup - delta)
			boss_slam_origin = origin
			if boss_slam_windup <= 0.0:
				_spawn_impact(origin, danger, 170.0, 0.30)
				_spawn_particles(origin, danger, 18, 80.0, 260.0, 1.8, 3.4, 0.50)
				_play_sfx("boss_slam", -11.0)
				_add_shake(14.0)
				_start_hitstop(0.045)

				if player != null and is_instance_valid(player) and origin.distance_to(player.global_position) <= boss_slam_radius:
					player.take_damage(10.0 + float(level) * 0.35)
		elif boss_special_timer <= 0.0:
			boss_special_timer = 4.9
			boss_slam_windup = 0.55
			boss_slam_origin = origin
			boss_slam_radius = 150.0
			_play_sfx("boss_roar", -14.0)
			_spawn_particles(origin, danger, 10, 30.0, 120.0, 1.2, 2.6, 0.38)
			_screen_flash(danger, 0.10)

	elif boss_level == 10:
		if boss_ring_timer <= 0.0:
			boss_ring_timer = 6.6
			_spawn_impact(origin, accent, 210.0, 0.34)
			_spawn_particles(origin, accent, 26, 90.0, 260.0, 1.8, 3.6, 0.58)
			_play_sfx("boss_roar", -13.5)
			_add_shake(10.0)

			var count = 14
			var base_angle = randf() * TAU
			for i in range(count):
				var angle = base_angle + TAU * float(i) / float(count)
				var dir = Vector2.RIGHT.rotated(angle)
				_spawn_projectile({
					"faction": "enemy",
					"mode": "bullet",
					"origin": origin + dir * (float(boss_ref.radius) + 14.0),
					"direction": dir,
					"speed": 300.0 + float(level) * 2.0,
					"damage": 6.0 + float(level) * 0.38,
					"hits": 1,
					"radius": 5.8,
					"lifetime": 3.1,
					"world_rect": arena_rect
				})

	elif boss_level == 15:
		if boss_special_timer <= 0.0:
			boss_special_timer = 3.3
			boss_beam_fire_timer = 0.52
			var to_player = Vector2.RIGHT
			if player != null and is_instance_valid(player):
				var d = player.global_position - origin
				if d.length_squared() > 0.001:
					to_player = d.normalized()
			boss_beam_target_angle = to_player.angle() + randf_range(-0.26, 0.26)
			_play_sfx("boss_roar", -14.0)
			_spawn_particles(origin, danger, 20, 80.0, 240.0, 1.8, 3.4, 0.45)
			_screen_flash(danger, 0.22)

		if boss_beam_fire_timer > 0.0 and boss_beam_damage_cooldown <= 0.0 and player != null and is_instance_valid(player):
			var direction = Vector2.RIGHT.rotated(boss_beam_target_angle)
			var length = 860.0
			var width = 26.0
			var to_player = player.global_position - origin
			var along = to_player.dot(direction)
			if along >= 0.0 and along <= length:
				var closest = origin + direction * along
				var allowance = width + 18.0
				if player.global_position.distance_squared_to(closest) <= allowance * allowance:
					boss_beam_damage_cooldown = 0.26
					player.take_damage(8.0 + float(level) * 0.45)


func _update_footsteps(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if player == null or not is_instance_valid(player):
		return

	if player_last_pos == Vector2.ZERO:
		player_last_pos = player.global_position
		return

	var dist = player.global_position.distance_to(player_last_pos)
	player_last_pos = player.global_position
	if dist <= 0.001:
		return

	footstep_accum += dist
	var stride = clamp(footstep_stride * (240.0 / max(120.0, player.move_speed)), 36.0, 62.0)
	while footstep_accum >= stride:
		footstep_accum -= stride
		if step_sfx_cooldown <= 0.0:
			step_sfx_cooldown = 0.11
			_play_sfx("step", -25.0)
		var dust_col = Color(0.86, 0.96, 1.0, 0.26)
		var offset = Vector2(randf_range(-10.0, 10.0), 20.0)
		_spawn_particles(player.global_position + offset, dust_col, 4, 18.0, 70.0, 1.0, 2.2, 0.40)


func _fire_prism_laser() -> void:
	var origin = player.global_position
	laser_angle = wrapf(laser_angle + 1.08 + randf_range(-0.08, 0.08), -PI, PI)
	var direction = Vector2.RIGHT.rotated(laser_angle)

	var laser_range = 520.0 + float(level) * 20.0 + player.projectile_speed * 0.05
	var laser_width = 16.0 + laser_width_bonus
	var multiplier = clamp(0.58 + laser_damage_bonus, 0.58, 2.2)
	var base_damage = player.damage * multiplier

	for enemy in active_enemies:
		if not enemy.is_active:
			continue
		var to_enemy = enemy.global_position - origin
		var along = to_enemy.dot(direction)
		if along < 0.0 or along > laser_range:
			continue
		var closest = origin + direction * along
		var allowance = laser_width + enemy.radius
		if enemy.global_position.distance_squared_to(closest) <= allowance * allowance:
			var falloff = lerp(1.0, 0.78, clamp(along / laser_range, 0.0, 1.0))
			enemy.apply_projectile_hit(_rolled_damage(base_damage * falloff))

	var laser_col = Color(0.90, 1.0, 0.84)
	beam_effects.append({
		"from": origin + direction * 20.0,
		"to": origin + direction * laser_range,
		"width": laser_width,
		"color": laser_col,
		"inner_color": Color(0.99, 1.0, 0.94),
		"time": 0.0,
		"duration": 0.14
	})
	_add_shake(3.2)
	_play_sfx("beam", -14.0)


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


func _roll_damage_packet(base_damage: float) -> Dictionary:
	var crit = randf() < crit_chance
	return {
		"amount": base_damage * (crit_multiplier if crit else 1.0),
		"crit": crit
	}


func _fire_single(target_position: Vector2) -> void:
	var direction = (target_position - player.global_position).normalized()
	var roll = _roll_damage_packet(player.damage)
	_spawn_projectile({
		"mode": "bullet",
		"origin": player.global_position + direction * 26.0,
		"direction": direction,
		"speed": player.projectile_speed,
		"damage": float(roll["amount"]),
		"crit": bool(roll["crit"]),
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
			var roll = _roll_damage_packet(player.damage * 0.43 * shotgun_damage_multiplier)
			_spawn_projectile({
				"mode": "bullet",
				"origin": player.global_position + dir * 24.0,
				"direction": dir,
				"speed": player.projectile_speed * randf_range(0.95, 1.06),
				"damage": float(roll["amount"]),
				"crit": bool(roll["crit"]),
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
	var beam_width = 18.0 * beam_width_multiplier
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
	var max_boomerangs = 1 + int(float(player.projectile_pierce) / 3.0) + bonus_boomerang_cap
	if existing >= max_boomerangs:
		return

	var spawn_count = min(max_boomerangs - existing, 2)
	var base_direction = (target_position - player.global_position).normalized()
	for i in range(spawn_count):
		var offset = 0.0
		if spawn_count == 2:
			offset = -0.14 if i == 0 else 0.14
		var dir = base_direction.rotated(offset)
		var roll = _roll_damage_packet(player.damage * 0.92)
		_spawn_projectile({
			"mode": "boomerang",
			"origin": player.global_position + dir * 22.0,
			"direction": dir,
			"speed": max(390.0, player.projectile_speed * 0.84),
			"damage": float(roll["amount"]),
			"crit": bool(roll["crit"]),
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


func _on_enemy_died(enemy, drop_position: Vector2, xp_value: float) -> void:
	if ended:
		return

	kills += 1
	if kill_heal_flat > 0.0:
		player.heal(kill_heal_flat)

	var is_boss = enemy != null and bool(enemy.is_boss)
	if is_boss:
		_play_sfx("boss_die", -8.0)
	elif enemy_die_sfx_cooldown <= 0.0:
		enemy_die_sfx_cooldown = 0.05
		_play_sfx("enemy_die", -18.0)

	var impact_color: Color = realm_palette.get("danger", Color(0.90, 0.37, 0.46))
	var impact_radius = 32.0
	if enemy != null and enemy.is_elite:
		impact_color = realm_palette.get("accent", Color(0.49, 0.88, 1.0))
		impact_radius = 54.0
		_add_shake(10.0)
		_start_hitstop(0.045)
		_screen_flash(impact_color, 0.35)
		if elite_overclock_extend > 0.0:
			overclock_timer = max(overclock_timer, 2.0)
			overclock_timer += elite_overclock_extend

	if is_boss:
		impact_color = realm_palette.get("accent", Color(0.49, 0.88, 1.0))
		impact_radius = 130.0
		_add_shake(18.0)
		_start_hitstop(0.06)
		_screen_flash(impact_color, 0.42)
		var tier = max(1, int(enemy.boss_tier))
		var bounty = 20 + tier * 12
		boss_bonus_shards += bounty
		if show_damage_numbers:
			_spawn_floating_text(drop_position + Vector2(0.0, -48.0), "BOSS DOWN  +%d" % bounty, Color(1.0, 0.96, 0.84), 22, 1.05)
		if boss_ref != null and is_instance_valid(boss_ref) and boss_ref.get_instance_id() == enemy.get_instance_id():
			boss_ref = null
			boss_level = 0
			boss_name = ""
			boss_slam_windup = 0.0
			if boss_panel != null:
				boss_panel.visible = false

	_spawn_impact(drop_position, impact_color, impact_radius, 0.22)
	_spawn_particles(drop_position, impact_color, 14 if is_boss else (8 if (enemy != null and enemy.is_elite) else 5), 80.0, 260.0, 1.6, 3.2, 0.42)

	if enemy != null and String(enemy.archetype_id) == "splitter":
		_spawn_splitlings(drop_position)

	var orb_count = 3 if is_boss else 1
	for i in range(orb_count):
		var orb = _acquire_orb()
		if orb == null:
			break
		var share = xp_value
		if orb_count > 1:
			share = xp_value * (0.42 + float(i) * 0.06)
		orb.activate(drop_position + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)), player, share)
		active_orbs.append(orb)


func _spawn_splitlings(origin: Vector2) -> void:
	var count = 2
	for i in range(count):
		if active_enemies.size() >= _enemy_cap():
			return
		var enemy = _acquire_enemy()
		if enemy == null:
			return
		var offset = Vector2(randf_range(-28.0, 28.0), randf_range(-28.0, 28.0))
		var pos = origin + offset
		pos.x = clamp(pos.x, arena_rect.position.x + 22.0, arena_rect.end.x - 22.0)
		pos.y = clamp(pos.y, arena_rect.position.y + 22.0, arena_rect.end.y - 22.0)
		var cfg = _enemy_config(false, "splitling")
		enemy.activate(pos, player, cfg)
		active_enemies.append(enemy)


func _on_enemy_wants_shot(enemy, origin: Vector2, direction: Vector2, shot_cfg: Dictionary) -> void:
	if ended:
		return
	if enemy == null or not is_instance_valid(enemy) or not enemy.is_active:
		return

	var dir = (direction as Vector2).normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT

	_spawn_projectile({
		"faction": "enemy",
		"mode": "bullet",
		"origin": origin + dir * (float(enemy.radius) + 10.0),
		"direction": dir,
		"speed": float(shot_cfg.get("speed", 380.0)),
		"damage": float(shot_cfg.get("damage", 6.0)),
		"hits": 1,
		"radius": float(shot_cfg.get("radius", 5.0)),
		"lifetime": float(shot_cfg.get("lifetime", 2.2)),
		"world_rect": arena_rect
	})


func _on_projectile_hit_target(target, hit_position: Vector2, amount: float, crit: bool, faction: String) -> void:
	if ended:
		return

	# Enemy projectiles hitting the player already drive their own feedback via player.damaged.
	if faction != "player":
		return

	if target == null or not is_instance_valid(target):
		return

	if hit_sfx_cooldown <= 0.0:
		hit_sfx_cooldown = 0.04
		_play_sfx("hit", -16.0)
	if crit and crit_sfx_cooldown <= 0.0:
		crit_sfx_cooldown = 0.10
		_play_sfx("crit", -14.0)

	var spark_col: Color = realm_palette.get("accent", Color(0.49, 0.88, 1.0))
	if crit:
		spark_col = Color(1.0, 0.92, 0.62)
	_spawn_particles(hit_position, spark_col, 6 if crit else 3, 90.0, 220.0, 1.4, 2.4, 0.26)

	if show_damage_numbers:
		var is_boss_hit = false
		if target is EnemyScript:
			is_boss_hit = bool(target.is_boss)

		# Avoid flooding the screen (shotgun pellets). Always show crits; show non-crits for bosses.
		if crit or is_boss_hit:
			var text_col = Color(1.0, 0.96, 0.84) if crit else Color(0.76, 0.92, 1.0)
			var text_size = 22 if crit else 18
			_spawn_floating_text(hit_position + Vector2(randf_range(-8.0, 8.0), randf_range(-18.0, -10.0)), "%d" % int(round(amount)), text_col, text_size, 0.65)


func _on_orb_collected(orb, value: float) -> void:
	if ended:
		return

	var gain = value * core_gain_multiplier
	if overclock_timer > 0.0:
		gain *= 1.20
	core_charge += gain
	_pulse_core_glow(0.22)
	_spawn_impact(orb.global_position, realm_palette.get("accent", Color(0.49, 0.88, 1.0)), 24.0, 0.18)

	var overload_count = 0
	while core_charge >= core_charge_next:
		core_charge -= core_charge_next
		var progression = float(level - 1) / float(MAX_REALM_LEVEL - 1)
		var growth = 1.14 + progression * 0.10
		var add = 10.0 + float(level) * 3.0
		core_charge_next = min(1800.0, core_charge_next * growth + add)
		overclock_timer = max(overclock_timer, 8.0 + overclock_duration_bonus)
		if upgrade_buttons.size() > 0:
			var base_choices = clamp(draft_choices, 3, upgrade_buttons.size())
			var max_bonus = max(0, upgrade_buttons.size() - base_choices)
			draft_bonus_bank = min(max_bonus, draft_bonus_bank + 1)
		overload_count += 1
		_handle_core_overload()
		_spawn_impact(player.global_position, realm_palette.get("accent", Color(0.49, 0.88, 1.0)), 120.0, 0.34)

	if overload_count > 0:
		_pulse_core_glow(0.95)
		_play_sfx("levelup", -10.0)

	_sync_hud()


func _handle_core_overload() -> void:
	_add_shake(12.0)
	_screen_flash(realm_palette.get("accent", Color(0.49, 0.88, 1.0)), 0.42)

	if core_vacuum:
		for o in active_orbs:
			if o.is_active:
				o.forced_attract = true

	if overload_pulse_radius > 0.0 and overload_pulse_damage_bonus > 0.0:
		var radius = overload_pulse_radius
		var radius_sq = radius * radius
		var damage = player.damage * (0.55 + overload_pulse_damage_bonus)
		_spawn_impact(player.global_position, realm_palette.get("accent", Color(0.49, 0.88, 1.0)), radius * 0.65, 0.30)
		for enemy in active_enemies:
			if not enemy.is_active:
				continue
			if player.global_position.distance_squared_to(enemy.global_position) <= radius_sq:
				enemy.apply_projectile_hit(_rolled_damage(damage))


func _on_player_hp_changed(_current_hp: float, _max_hp: float) -> void:
	_sync_hud()


func _on_player_damaged(amount: float) -> void:
	if ended:
		return

	var danger = realm_palette.get("danger", Color(0.90, 0.37, 0.46))
	_add_shake(8.0 + amount * 0.12)
	_screen_flash(danger, 0.55)
	_pulse_core_glow(0.28)
	_start_hitstop(0.055)
	_play_sfx("hurt", -10.0)
	_spawn_particles(player.global_position, danger, 12, 70.0, 230.0, 1.6, 3.2, 0.42)
	if show_damage_numbers:
		_spawn_floating_text(player.global_position + Vector2(0.0, -42.0), "OUCH!", Color(1.0, 0.32, 0.42), 24, 0.85)
		_spawn_floating_text(player.global_position + Vector2(randf_range(-6.0, 6.0), -22.0), "-%d" % int(round(amount)), Color(1.0, 0.86, 0.90), 18, 0.70)


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
	_spawn_impact(origin, realm_palette.get("accent", Color(0.49, 0.88, 1.0)), radius * 0.58, 0.28)
	queue_redraw()

	if surge_heal_flat > 0.0:
		player.heal(surge_heal_flat)
		_pulse_core_glow(0.26)
		_screen_flash(realm_palette.get("accent", Color(0.49, 0.88, 1.0)), 0.22)

	_add_shake(5.5)

	var radius_sq = radius * radius
	for enemy in active_enemies:
		if not enemy.is_active:
			continue
		if origin.distance_squared_to(enemy.global_position) <= radius_sq:
			enemy.apply_projectile_hit(_rolled_damage(damage))
			enemy.apply_slow(slow_multiplier, slow_duration)


func _spawn_impact(origin: Vector2, color: Color, radius: float, duration: float) -> void:
	impact_effects.append({
		"origin": origin,
		"color": color,
		"radius": radius,
		"time": 0.0,
		"duration": duration
	})


func _open_next_upgrade_panel() -> void:
	if pending_upgrade_queue.is_empty():
		return
	if upgrade_picks_used >= max_upgrade_picks_per_run:
		pending_upgrade_queue.clear()
		return

	paused_for_upgrade = true
	_set_simulation_paused(true)
	upgrade_anim_t = 0.0
	upgrade_panel.scale = Vector2.ONE * 0.94
	upgrade_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)

	current_upgrade_reason = String(pending_upgrade_queue[0])
	var base_choices = clamp(draft_choices, 3, upgrade_buttons.size())
	var max_bonus = max(0, upgrade_buttons.size() - base_choices)
	var bonus_choices = clamp(draft_bonus_bank, 0, max_bonus)
	draft_bonus_bank = 0
	var choice_count = base_choices + bonus_choices
	upgrade_options = _pick_upgrade_options(choice_count)

	if upgrade_options.is_empty():
		pending_upgrade_queue.pop_front()
		paused_for_upgrade = false
		_set_simulation_paused(hitstop_active)
		return

	var pick_label = ""
	if run_is_endless:
		pick_label = "Pick %d" % (upgrade_picks_used + 1)
	else:
		pick_label = "Pick %d/%d" % [min(max_upgrade_picks_per_run, upgrade_picks_used + 1), max_upgrade_picks_per_run]
	if current_upgrade_reason == "level":
		upgrade_title.text = "Realm Level %d Upgrade - Choose (%s)" % [level, pick_label]
	elif current_upgrade_reason == "start":
		upgrade_title.text = "Run Start Upgrade - Choose (%s)" % pick_label
	else:
		upgrade_title.text = "Core Overload Upgrade - Choose (%s)" % pick_label

	for i in range(upgrade_buttons.size()):
		var button: Button = upgrade_buttons[i]
		if i < upgrade_options.size():
			var option: Dictionary = upgrade_options[i]
			var pick_count = int(upgrade_pick_counts.get(String(option.get("id", "")), 0))
			button.text = "%s\n%s\nPicked %d" % [option["title"], option["desc"], pick_count]
			button.visible = true
		else:
			button.visible = false

	upgrade_panel.visible = true
	if DisplayServer.get_name() == "headless":
		call_deferred("_auto_pick_upgrade_headless")


func _auto_pick_upgrade_headless() -> void:
	# Make smoke tests actually simulate gameplay instead of stalling on upgrade prompts.
	if ended or not paused_for_upgrade or upgrade_options.is_empty():
		return
	_on_upgrade_selected(0)


func _on_upgrade_selected(index: int) -> void:
	if index < 0 or index >= upgrade_options.size():
		return

	var selected: Dictionary = upgrade_options[index]
	var selected_id = String(selected["id"])
	upgrade_picks_used += 1
	upgrade_pick_counts[selected_id] = int(upgrade_pick_counts.get(selected_id, 0)) + 1
	_apply_upgrade(selected_id)

	if not pending_upgrade_queue.is_empty():
		pending_upgrade_queue.pop_front()

	upgrade_panel.visible = false
	upgrade_panel.scale = Vector2.ONE
	upgrade_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	upgrade_anim_t = 1.0
	paused_for_upgrade = false
	_set_simulation_paused(hitstop_active)

	if not pending_upgrade_queue.is_empty():
		_open_next_upgrade_panel()

	_sync_hud()


func _unhandled_input(event: InputEvent) -> void:
	if ended:
		return

	if event.is_action_pressed("ui_cancel"):
		if paused_for_upgrade:
			return
		_set_pause_active(not paused_by_player)
		get_viewport().set_input_as_handled()


func _on_pause_pressed() -> void:
	_set_pause_active(not paused_by_player)


func _on_pause_resume_pressed() -> void:
	_set_pause_active(false)


func _on_pause_quit_pressed() -> void:
	if ended:
		return
	_finish_run(false, true)


func _set_pause_active(active: bool) -> void:
	if ended:
		return
	if paused_for_upgrade:
		return
	paused_by_player = active
	if pause_overlay != null:
		pause_overlay.visible = active
	_set_simulation_paused(active or hitstop_active)
	_sync_hud()


func _pick_upgrade_options(count: int) -> Array:
	var pool: Array = []
	for upgrade in UPGRADES:
		var upgrade_id = String(upgrade.get("id", ""))
		# Prevent a single upgrade from dominating the whole run.
		if not run_is_endless and int(upgrade_pick_counts.get(upgrade_id, 0)) >= 15:
			continue
		if upgrade.has("weapons"):
			if not (upgrade["weapons"] as Array).has(player.weapon_type):
				continue
		if upgrade.has("heroes"):
			var heroes: Array = upgrade["heroes"]
			if not heroes.has(player.hero_id):
				# Shop unlock can make Prism Sweep draftable on all heroes.
				if upgrade_id == "laser_pattern" and bool(meta_mods.get("unlock_laser_all", false)):
					pass
				else:
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
		"surge_siphon":
			surge_heal_flat += 6.0
		"regen_field":
			player.regen_per_second += 0.6
		"leech_gel":
			kill_heal_flat += 1.4
		"armor_mesh":
			player.damage_taken_multiplier = max(0.54, player.damage_taken_multiplier * 0.92)
		"crit_chip":
			crit_chance = min(1.0, crit_chance + 0.20)
		"crit_amp":
			crit_multiplier += 0.26
		"core_hack":
			overclock_fire_bonus += 0.12
			overclock_duration_bonus += 1.6
		"core_vacuum":
			core_vacuum = true
		"core_pulse":
			overload_pulse_radius = max(overload_pulse_radius, 165.0)
			overload_pulse_damage_bonus += 0.45
		"overclock_cascade":
			elite_overclock_extend += 1.4
		"core_gain":
			core_gain_multiplier *= 1.18
		"mastery_boost":
			mastery_gain_multiplier *= 1.20
		"duplicate_shot":
			duplicate_shot_chance = min(0.45, duplicate_shot_chance + 0.08)
		"weapon_overclock":
			player.fire_rate *= 1.10
			player.projectile_pierce = min(player.projectile_pierce + 1, 10)
		"laser_pattern":
			laser_enabled = true
			laser_damage_bonus += 0.22
			laser_width_bonus += 2.0
			laser_interval = max(1.65, laser_interval * 0.90)
			laser_timer = min(laser_timer, 0.35)
		"beam_width":
			beam_width_multiplier *= 1.10
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
		_:
			pass


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
	var hp_ratio = player.current_hp / max(1.0, player.max_hp)
	if hp_ratio <= 0.30:
		health_label.add_theme_color_override("font_color", realm_palette.get("danger", Color(0.90, 0.37, 0.46)))
	elif hp_ratio <= 0.60:
		health_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.48))
	else:
		health_label.add_theme_color_override("font_color", Color(0.95, 0.99, 1.0))
	if run_is_endless:
		level_label.text = "Realm Lv %d (ENDLESS)" % level
		timer_label.text = "%s (ENDLESS)" % _format_time(elapsed_time)
	else:
		level_label.text = "Realm Lv %d / %d" % [level, run_max_level]
		timer_label.text = "%s / %s" % [_format_time(elapsed_time), _format_time(run_duration)]
	enemies_label.text = "Enemies %d" % active_enemies.size()
	core_label.text = "Core %.0f / %.0f" % [core_charge, core_charge_next]
	core_bar.max_value = core_charge_next
	core_bar.value = core_charge
	if stats_label != null:
		stats_label.text = "DMG %.0f  SPD %.0f  Crit %d%%  CritD x%.2f" % [
			player.damage,
			player.move_speed,
			int(round(crit_chance * 100.0)),
			crit_multiplier
		]

	if boss_panel != null:
		var boss_active = show_boss_hp_bar and boss_ref != null and is_instance_valid(boss_ref) and boss_ref.is_active
		boss_panel.visible = boss_active
		if boss_active and boss_hp_bar != null and boss_name_label != null:
			boss_name_label.text = "%s (Lv %d)" % [boss_name, boss_level]
			boss_hp_bar.max_value = max(1.0, float(boss_ref.max_hp))
			boss_hp_bar.value = clamp(float(boss_ref.hp), 0.0, float(boss_hp_bar.max_value))

	if overclock_timer > 0.0:
		hint_label.text = "OVERCLOCK %.1fs: boosted fire rate and core gain." % overclock_timer
		hint_label.add_theme_color_override("font_color", realm_palette.get("accent", Color(0.50, 0.88, 1.0)))
	else:
		hint_label.text = "Realm levels are time-gated. Core overloads grant overclock spikes and bank extra upgrade options."
		hint_label.add_theme_color_override("font_color", realm_palette.get("accent_soft", Color(0.60, 0.92, 1.0, 0.9)))


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


func _finish_run(victory: bool, aborted: bool = false) -> void:
	if ended:
		return

	ended = true
	paused_by_player = false
	if pause_overlay != null:
		pause_overlay.visible = false
	upgrade_panel.visible = false
	_set_simulation_paused(true)

	var mastery = 0
	if not aborted:
		mastery = _calculate_mastery_earned(victory) + boss_bonus_shards

	var stats = {
		"time_survived": elapsed_time,
		"level": level,
		"kills": kills,
		"hero_id": selected_hero.get("id", "warden"),
		"hero": selected_hero.get("name", "Blueth"),
		"weapon": DataScript.WEAPONS[player.weapon_type]["name"],
		"realm_id": selected_realm.get("id", "riftcore"),
		"realm": selected_realm.get("name", "Riftcore"),
		"mastery_earned": mastery,
		"boss_bounties": boss_bonus_shards,
		"aborted": aborted,
		"endless": run_is_endless
	}
	emit_signal("run_finished", victory, stats)
