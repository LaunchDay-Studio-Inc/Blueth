extends Area2D
class_name BluethProjectile

signal hit_target(target, position: Vector2, amount: float, crit: bool, faction: String)

var is_active = false

var projectile_mode = "bullet"
var faction = "player"
var owner_ref = null
var velocity = Vector2.ZERO
var damage = 10.0
var is_crit = false
var hits_left = 1
var age = 0.0
var lifetime = 1.4
var radius = 4.0
var arena_rect = Rect2(Vector2.ZERO, Vector2.ZERO)

var boomerang_outbound_time = 0.42
var boomerang_return_grace = 0.1

var collision_shape: CollisionShape2D
var hit_registry = {}
var hit_cooldowns = {}

func _ready() -> void:
	collision_layer = 1 << 2
	collision_mask = 1 << 1
	monitoring = false
	monitorable = false

	collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	collision_shape.disabled = true
	add_child(collision_shape)

	area_entered.connect(_on_area_entered)
	set_physics_process(false)
	hide()


func activate(config: Dictionary) -> void:
	is_active = true
	projectile_mode = String(config.get("mode", "bullet"))
	faction = String(config.get("faction", "player"))
	owner_ref = config.get("owner", null)

	global_position = config.get("origin", Vector2.ZERO)
	var direction = (config.get("direction", Vector2.RIGHT) as Vector2).normalized()
	velocity = direction * float(config.get("speed", 560.0))
	damage = float(config.get("damage", 10.0))
	is_crit = bool(config.get("crit", false))
	hits_left = int(config.get("hits", 1))
	age = 0.0
	lifetime = float(config.get("lifetime", 1.55))
	arena_rect = config.get("world_rect", Rect2(Vector2.ZERO, Vector2(2200, 1300)))
	radius = float(config.get("radius", 4.0))
	(collision_shape.shape as CircleShape2D).radius = radius
	boomerang_outbound_time = float(config.get("boomerang_outbound_time", 0.42))
	boomerang_return_grace = float(config.get("boomerang_return_grace", 0.10))

	if faction == "enemy":
		collision_layer = 1 << 3
		collision_mask = 1 << 0
	else:
		collision_layer = 1 << 2
		collision_mask = 1 << 1

	rotation = velocity.angle()
	hit_registry.clear()
	hit_cooldowns.clear()

	monitoring = true
	collision_shape.disabled = false
	set_physics_process(true)
	show()
	queue_redraw()


func deactivate() -> void:
	is_active = false
	faction = "player"
	owner_ref = null
	set_deferred("monitoring", false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	hide()
	is_crit = false
	hit_registry.clear()
	hit_cooldowns.clear()


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	age += delta
	_update_hit_cooldowns(delta)

	if projectile_mode == "boomerang":
		_update_boomerang(delta)
	else:
		global_position += velocity * delta

	if age >= lifetime or not arena_rect.has_point(global_position):
		deactivate()


func _update_boomerang(delta: float) -> void:
	rotation += 12.0 * delta

	if age < boomerang_outbound_time:
		global_position += velocity * delta
		return

	if not is_instance_valid(owner_ref):
		deactivate()
		return

	var to_owner = owner_ref.global_position - global_position
	var distance = to_owner.length()
	if distance <= 20.0 and age > boomerang_outbound_time + boomerang_return_grace:
		deactivate()
		return

	if distance > 0.001:
		var return_speed = max(velocity.length() * 1.10, 420.0)
		global_position += (to_owner / distance) * return_speed * delta


func _update_hit_cooldowns(delta: float) -> void:
	if hit_cooldowns.is_empty():
		return

	var keys = hit_cooldowns.keys()
	for key in keys:
		var remaining = float(hit_cooldowns[key]) - delta
		if remaining <= 0.0:
			hit_cooldowns.erase(key)
		else:
			hit_cooldowns[key] = remaining


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	if area == null or not area.has_method("apply_projectile_hit"):
		return
	# Ignore pooled objects that are currently inactive (prevents "ghost" hits
	# when something has been hidden but hasn't fully disabled monitoring yet).
	var active_prop = area.get("is_active")
	if typeof(active_prop) == TYPE_BOOL and not bool(active_prop):
		return

	var area_id = area.get_instance_id()
	if projectile_mode == "boomerang":
		if hit_cooldowns.has(area_id):
			return
		emit_signal("hit_target", area, global_position, damage, is_crit, faction)
		area.apply_projectile_hit(damage)
		hit_cooldowns[area_id] = 0.22
		hits_left -= 1
		if hits_left <= 0:
			deactivate()
		return

	if hit_registry.has(area_id):
		return

	hit_registry[area_id] = true
	emit_signal("hit_target", area, global_position, damage, is_crit, faction)
	area.apply_projectile_hit(damage)
	hits_left -= 1
	if hits_left <= 0:
		deactivate()


func _draw() -> void:
	if faction == "enemy":
		draw_circle(Vector2.ZERO, radius * 2.1, Color(1.0, 0.52, 0.45, 0.16))
		draw_circle(Vector2.ZERO, radius * 1.15, Color(1.0, 0.30, 0.32))
		draw_circle(Vector2(-radius * 0.18, -radius * 0.22), radius * 0.26, Color(1.0, 0.92, 0.84, 0.72))
		return

	if projectile_mode == "boomerang":
		draw_circle(Vector2.ZERO, radius + 2.6, Color(0.36, 0.92, 0.84, 0.14))
		draw_arc(Vector2.ZERO, radius + 2.0, -2.5, -0.5, 12, Color(0.38, 0.96, 0.88), 3.0)
		draw_arc(Vector2.ZERO, radius + 2.0, 0.6, 2.6, 12, Color(0.20, 0.76, 0.70), 3.0)
		return

	draw_circle(Vector2.ZERO, radius * 1.9, Color(0.70, 0.95, 1.0, 0.16))
	draw_circle(Vector2.ZERO, radius, Color(0.74, 0.97, 1.0))
	draw_circle(Vector2.ZERO, radius * 0.50, Color(0.22, 0.54, 0.72))
	draw_circle(Vector2(-radius * 0.24, -radius * 0.30), radius * 0.20, Color(0.98, 1.0, 1.0, 0.75))
