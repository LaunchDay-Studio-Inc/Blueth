extends Node2D
class_name BluethPlayer

signal died
signal hp_changed(current_hp: float, max_hp: float)
signal damaged(amount: float)
signal surge_triggered(origin: Vector2, radius: float, damage: float, slow_multiplier: float, slow_duration: float)

const PlayerHitboxScript = preload("res://scripts/entities/player_hitbox.gd")

@export var move_speed = 250.0
@export var max_hp = 100.0
@export var surge_distance = 340.0
@export var surge_radius = 128.0
@export var surge_damage = 24.0
@export var surge_slow_multiplier = 0.58
@export var surge_slow_duration = 1.5

var fire_rate = 2.8
var damage = 14.0
var projectile_speed = 560.0
var projectile_scale = 1.0
var projectile_pierce = 0
var pickup_magnet_radius = 140.0

var hero_id = "warden"
var hero_name = "Blueth"
var weapon_type = "shotgun"
var base_color = Color(0.34, 0.80, 0.94)

var damage_taken_multiplier = 1.0
var regen_per_second = 0.0

var current_hp = 100.0
var invuln_timer = 0.0
var distance_since_surge = 0.0
var arena_rect = Rect2(Vector2.ZERO, Vector2(2200, 1300))
var hitbox: Area2D

func _ready() -> void:
	current_hp = max_hp
	if hitbox == null:
		hitbox = PlayerHitboxScript.new()
		add_child(hitbox)
		hitbox.setup(self, 18.0)
	set_physics_process(true)
	queue_redraw()


func apply_hero(hero: Dictionary) -> void:
	hero_id = String(hero.get("id", "warden"))
	hero_name = String(hero.get("name", "Blueth"))
	weapon_type = String(hero.get("weapon", "shotgun"))
	var stats = hero.get("stats", {})

	max_hp = float(stats.get("max_hp", max_hp))
	move_speed = float(stats.get("move_speed", move_speed))
	fire_rate = float(stats.get("fire_rate", fire_rate))
	damage = float(stats.get("damage", damage))
	projectile_speed = float(stats.get("projectile_speed", projectile_speed))
	projectile_pierce = int(stats.get("projectile_pierce", projectile_pierce))
	pickup_magnet_radius = float(stats.get("pickup_magnet_radius", pickup_magnet_radius))

	surge_distance = float(stats.get("surge_distance", surge_distance))
	surge_radius = float(stats.get("surge_radius", surge_radius))
	surge_damage = float(stats.get("surge_damage", surge_damage))
	surge_slow_multiplier = float(stats.get("surge_slow_multiplier", surge_slow_multiplier))
	surge_slow_duration = float(stats.get("surge_slow_duration", surge_slow_duration))

	base_color = stats.get("base_color", base_color)

	damage_taken_multiplier = 1.0
	regen_per_second = 0.0

	current_hp = max_hp
	distance_since_surge = 0.0
	emit_signal("hp_changed", current_hp, max_hp)
	queue_redraw()


func set_arena_rect(new_rect: Rect2) -> void:
	arena_rect = new_rect


func _physics_process(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer = max(0.0, invuln_timer - delta)

	if regen_per_second > 0.0 and current_hp > 0.0 and current_hp < max_hp:
		heal(regen_per_second * delta)

	var input_vector = _get_input_vector()
	var velocity = input_vector * move_speed
	global_position += velocity * delta
	global_position.x = clamp(global_position.x, arena_rect.position.x + 24.0, arena_rect.end.x - 24.0)
	global_position.y = clamp(global_position.y, arena_rect.position.y + 24.0, arena_rect.end.y - 24.0)

	var moved_distance = velocity.length() * delta
	if moved_distance > 0.0:
		distance_since_surge += moved_distance
		if distance_since_surge >= surge_distance:
			distance_since_surge -= surge_distance
			emit_signal(
				"surge_triggered",
				global_position,
				surge_radius,
				surge_damage,
				surge_slow_multiplier,
				surge_slow_duration
			)

	queue_redraw()


func _get_input_vector() -> Vector2:
	var x = 0.0
	var y = 0.0

	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		y += 1.0

	return Vector2(x, y).normalized()


func take_damage(amount: float) -> void:
	if amount <= 0.0 or invuln_timer > 0.0:
		return

	var final_amount: float = amount * damage_taken_multiplier
	current_hp = max(0.0, current_hp - final_amount)
	invuln_timer = 0.24
	emit_signal("damaged", final_amount)
	emit_signal("hp_changed", current_hp, max_hp)
	queue_redraw()

	if current_hp <= 0.0:
		emit_signal("died")


func add_max_hp(amount: float) -> void:
	max_hp += amount
	current_hp = min(max_hp, current_hp + amount)
	emit_signal("hp_changed", current_hp, max_hp)


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	current_hp = min(max_hp, current_hp + amount)
	emit_signal("hp_changed", current_hp, max_hp)


func _draw() -> void:
	var body_color = base_color
	if invuln_timer > 0.0:
		body_color = body_color.lightened(0.28)

	var glow = body_color
	glow.a = 0.22
	draw_circle(Vector2.ZERO, 26.0, glow)
	draw_circle(Vector2.ZERO, 22.0, Color(glow.r, glow.g, glow.b, 0.12))

	draw_circle(Vector2.ZERO, 18.0, body_color)
	draw_circle(Vector2(-5.2, -7.0), 5.6, Color(1.0, 1.0, 1.0, 0.22))
	draw_circle(Vector2(-6.2, -3.8), 3.7, Color(0.08, 0.14, 0.2))
	draw_circle(Vector2(6.2, -3.8), 3.7, Color(0.08, 0.14, 0.2))
	draw_circle(Vector2(-5.3, -4.3), 1.1, Color(0.96, 0.99, 1.0))
	draw_circle(Vector2(5.1, -4.3), 1.1, Color(0.96, 0.99, 1.0))
	draw_arc(Vector2.ZERO, 10.2, 0.2, PI - 0.2, 22, Color(0.07, 0.12, 0.18), 2.5)

	var charge_ratio = clamp(distance_since_surge / surge_distance, 0.0, 1.0)
	var ring_outer = Color(0.48, 0.92, 1.0, 0.33)
	draw_arc(Vector2.ZERO, 24.5, 0.0, TAU, 48, ring_outer, 1.2)
	draw_arc(
		Vector2.ZERO,
		24.5,
		-PI * 0.5,
		-PI * 0.5 + (TAU * charge_ratio),
		42,
		Color(0.60, 0.96, 1.0, 0.96),
		3.3
	)
	if charge_ratio > 0.98:
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 56, Color(0.76, 0.99, 1.0, 0.55), 2.0)

	if weapon_type == "beam":
		draw_rect(Rect2(Vector2(-5.0, -23.0), Vector2(10.0, 10.0)), Color(0.80, 0.97, 1.0), true)
		draw_rect(Rect2(Vector2(-1.4, -20.0), Vector2(2.8, 8.0)), Color(0.47, 0.84, 1.0), true)
	elif weapon_type == "boomerang":
		draw_arc(Vector2.ZERO, 22.0, -1.15, -0.35, 10, Color(0.42, 0.98, 0.90), 3.1)
		draw_arc(Vector2.ZERO, 22.0, -2.8, -2.0, 10, Color(0.32, 0.90, 0.80), 3.1)
	else:
		draw_rect(Rect2(Vector2(-10.0, -21.0), Vector2(20.0, 6.0)), Color(0.94, 0.98, 1.0), true)
		draw_rect(Rect2(Vector2(-4.0, -19.0), Vector2(8.0, 2.8)), Color(0.44, 0.82, 0.99), true)
