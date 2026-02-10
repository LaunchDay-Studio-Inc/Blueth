extends Area2D
class_name BluethEnemy

signal died(enemy, drop_position: Vector2, xp_value: float)

var is_active = false
var target

var speed = 82.0
var hp = 32.0
var touch_damage = 8.0
var touch_interval = 0.56
var touch_cooldown = 0.0
var xp_drop = 5.0

var radius = 14.0
var slow_multiplier = 1.0
var slow_timer = 0.0
var flash_timer = 0.0
var is_elite = false
var body_color = Color(0.84, 0.35, 0.30)
var eye_color = Color(0.19, 0.08, 0.06)

var collision_shape: CollisionShape2D

func _ready() -> void:
	collision_layer = 1 << 1
	collision_mask = 0
	monitoring = false
	monitorable = true

	collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	add_child(collision_shape)

	set_physics_process(false)
	hide()


func activate(spawn_position: Vector2, target_ref, cfg: Dictionary) -> void:
	is_active = true
	target = target_ref
	global_position = spawn_position

	speed = float(cfg.get("speed", 82.0))
	hp = float(cfg.get("hp", 32.0))
	touch_damage = float(cfg.get("damage", 8.0))
	xp_drop = float(cfg.get("xp", 5.0))
	radius = float(cfg.get("radius", 14.0))
	is_elite = bool(cfg.get("elite", false))
	body_color = cfg.get("body_color", body_color)
	eye_color = cfg.get("eye_color", eye_color)

	(collision_shape.shape as CircleShape2D).radius = radius
	scale = Vector2.ONE * float(cfg.get("scale", 1.0))

	touch_cooldown = randf_range(0.0, 0.3)
	slow_multiplier = 1.0
	slow_timer = 0.0
	flash_timer = 0.0

	monitoring = true
	set_physics_process(true)
	show()
	queue_redraw()


func deactivate() -> void:
	is_active = false
	set_deferred("monitoring", false)
	set_physics_process(false)
	hide()


func _physics_process(delta: float) -> void:
	if not is_active or not is_instance_valid(target):
		return

	if touch_cooldown > 0.0:
		touch_cooldown -= delta
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_multiplier = 1.0
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			queue_redraw()

	var to_player = target.global_position - global_position
	var distance = to_player.length()
	if distance > 0.001:
		global_position += (to_player / distance) * speed * slow_multiplier * delta

	if distance <= radius + 15.0 and touch_cooldown <= 0.0:
		target.take_damage(touch_damage)
		touch_cooldown = touch_interval


func apply_projectile_hit(amount: float) -> void:
	if not is_active:
		return

	hp -= amount
	flash_timer = 0.08
	queue_redraw()

	if hp <= 0.0:
		var drop_position = global_position
		var xp_value = xp_drop
		deactivate()
		emit_signal("died", self, drop_position, xp_value)


func apply_slow(multiplier: float, duration: float) -> void:
	if not is_active:
		return

	slow_multiplier = min(slow_multiplier, clamp(multiplier, 0.25, 1.0))
	slow_timer = max(slow_timer, duration)
	queue_redraw()


func _draw() -> void:
	var body = body_color
	if slow_timer > 0.0:
		body = body.lerp(Color(0.45, 0.75, 0.96), 0.45)
	if flash_timer > 0.0:
		body = Color(1.0, 0.93, 0.86)

	var shadow = Color(0.0, 0.0, 0.0, 0.22)
	draw_circle(Vector2(1.6, 3.2), radius * 1.04, shadow)
	draw_circle(Vector2.ZERO, radius * 1.08, Color(body.r, body.g, body.b, 0.18))
	draw_circle(Vector2.ZERO, radius, body)
	draw_circle(Vector2(-radius * 0.32, -radius * 0.34), radius * 0.28, Color(1.0, 1.0, 1.0, 0.18))
	draw_circle(Vector2(-radius * 0.33, -radius * 0.10), radius * 0.19, eye_color)
	draw_circle(Vector2(radius * 0.33, -radius * 0.10), radius * 0.19, eye_color)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.15), radius * 0.06, Color(0.96, 0.98, 1.0))
	draw_circle(Vector2(radius * 0.30, -radius * 0.15), radius * 0.06, Color(0.96, 0.98, 1.0))
	if is_elite:
		draw_arc(Vector2.ZERO, radius + 3.8, -PI * 0.88, PI * 0.88, 26, Color(1.0, 0.80, 0.62, 0.78), 2.0)
