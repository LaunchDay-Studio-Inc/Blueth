extends Area2D
class_name BluethEnemy

signal died(enemy, drop_position: Vector2, xp_value: float)
signal wants_shot(enemy, origin: Vector2, direction: Vector2, shot_cfg: Dictionary)

const SPRITE_VIEWBOX_SIZE = 128.0
const SHADOW_TEX_SIZE = 64.0
const ARCHETYPE_SPRITES = {
	"grunt": "res://assets/sprites/enemy_grunt.svg",
	"sprinter": "res://assets/sprites/enemy_sprinter.svg",
	"bulwark": "res://assets/sprites/enemy_bulwark.svg",
	"pack": "res://assets/sprites/enemy_pack.svg",
	"shooter": "res://assets/sprites/enemy_shooter.svg",
	"splitter": "res://assets/sprites/enemy_splitter.svg",
	"stalker": "res://assets/sprites/enemy_stalker.svg",
	"splitling": "res://assets/sprites/enemy_splitling.svg",
	"boss_5": "res://assets/sprites/enemy_boss_5.svg",
	"boss_10": "res://assets/sprites/enemy_boss_10.svg",
	"boss_15": "res://assets/sprites/enemy_boss_15.svg"
}

static var _texture_cache: Dictionary = {}
static var _shadow_texture: Texture2D = null

var is_active = false
var target

var speed = 82.0
var hp = 32.0
var max_hp = 32.0
var touch_damage = 8.0
var touch_interval = 0.56
var touch_cooldown = 0.0
var xp_drop = 5.0

var archetype_id = "grunt"
var shoot_interval = 0.0
var shoot_cooldown = 0.0
var projectile_damage = 6.0
var projectile_speed = 380.0
var projectile_radius = 5.0
var projectile_lifetime = 2.2

var dash_interval = 0.0
var dash_duration = 0.0
var dash_multiplier = 1.0
var dash_timer = 0.0
var dash_active_timer = 0.0

var radius = 14.0
var slow_multiplier = 1.0
var slow_timer = 0.0
var flash_timer = 0.0
var is_elite = false
var is_boss = false
var boss_tier = 0
var show_hp_bar = false
var face_variant = 0
var face_seed = 0
var body_color = Color(0.84, 0.35, 0.30)
var eye_color = Color(0.19, 0.08, 0.06)

var collision_shape: CollisionShape2D
var shadow_sprite: Sprite2D
var body_sprite: Sprite2D
var body_sprite_base_scale = Vector2.ONE
var squash_timer = 0.0

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

	shadow_sprite = Sprite2D.new()
	shadow_sprite.texture = _get_shadow_texture()
	shadow_sprite.modulate = Color(0.0, 0.0, 0.0, 0.22)
	shadow_sprite.position = Vector2(1.6, 3.2)
	shadow_sprite.show_behind_parent = true
	shadow_sprite.z_index = 0
	add_child(shadow_sprite)

	body_sprite = Sprite2D.new()
	body_sprite.centered = true
	body_sprite.show_behind_parent = true
	body_sprite.z_index = 0
	add_child(body_sprite)

	set_physics_process(false)
	hide()

func _get_shadow_texture() -> Texture2D:
	if _shadow_texture != null:
		return _shadow_texture

	var size = int(SHADOW_TEX_SIZE)
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		var fy = (float(y) / float(size - 1)) * 2.0 - 1.0
		for x in range(size):
			var fx = (float(x) / float(size - 1)) * 2.0 - 1.0
			var r = sqrt(fx * fx + fy * fy)
			var a = clamp(1.0 - r, 0.0, 1.0)
			a = pow(a, 2.3) * 0.85
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))

	_shadow_texture = ImageTexture.create_from_image(img)
	return _shadow_texture


func _get_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var tex = load(path)
	_texture_cache[path] = tex
	return tex


func _update_visuals() -> void:
	if body_sprite == null or shadow_sprite == null:
		return

	var tex_path = String(ARCHETYPE_SPRITES.get(archetype_id, ""))
	body_sprite.texture = _get_texture(tex_path)

	# Scale sprite to match collision radius (node scale also applies).
	var diameter = max(10.0, radius * 2.15)
	var sprite_scale = diameter / SPRITE_VIEWBOX_SIZE
	body_sprite_base_scale = Vector2.ONE * sprite_scale
	body_sprite.scale = body_sprite_base_scale

	var shadow_diam = max(10.0, radius * 2.10)
	var shadow_scale = shadow_diam / SHADOW_TEX_SIZE
	shadow_sprite.scale = Vector2.ONE * shadow_scale

	_update_modulate()


func _update_modulate() -> void:
	if body_sprite == null:
		return

	var body = body_color
	if slow_timer > 0.0:
		body = body.lerp(Color(0.45, 0.75, 0.96), 0.45)
	if flash_timer > 0.0:
		body = Color(1.0, 0.93, 0.86)
	body_sprite.modulate = body


func activate(spawn_position: Vector2, target_ref, cfg: Dictionary) -> void:
	is_active = true
	target = target_ref
	global_position = spawn_position

	archetype_id = String(cfg.get("archetype", "grunt"))
	speed = float(cfg.get("speed", 82.0))
	hp = float(cfg.get("hp", 32.0))
	max_hp = hp
	touch_damage = float(cfg.get("damage", 8.0))
	xp_drop = float(cfg.get("xp", 5.0))
	radius = float(cfg.get("radius", 14.0))
	is_elite = bool(cfg.get("elite", false))
	is_boss = bool(cfg.get("boss", false))
	boss_tier = int(cfg.get("boss_tier", 0))
	show_hp_bar = bool(cfg.get("show_hp_bar", false))
	face_variant = int(cfg.get("face_variant", 0))
	face_seed = int(cfg.get("face_seed", randi()))
	body_color = cfg.get("body_color", body_color)
	eye_color = cfg.get("eye_color", eye_color)

	shoot_interval = float(cfg.get("shoot_interval", 0.0))
	projectile_damage = float(cfg.get("projectile_damage", projectile_damage))
	projectile_speed = float(cfg.get("projectile_speed", projectile_speed))
	projectile_radius = float(cfg.get("projectile_radius", projectile_radius))
	projectile_lifetime = float(cfg.get("projectile_lifetime", projectile_lifetime))
	shoot_cooldown = randf_range(0.0, max(0.01, shoot_interval))

	dash_interval = float(cfg.get("dash_interval", 0.0))
	dash_duration = float(cfg.get("dash_duration", 0.0))
	dash_multiplier = float(cfg.get("dash_multiplier", 1.0))
	dash_timer = randf_range(0.0, max(0.01, dash_interval)) if dash_interval > 0.0 else 0.0
	dash_active_timer = 0.0

	(collision_shape.shape as CircleShape2D).radius = radius
	scale = Vector2.ONE * float(cfg.get("scale", 1.0))
	collision_shape.disabled = false
	monitorable = true

	touch_cooldown = randf_range(0.0, 0.3)
	slow_multiplier = 1.0
	slow_timer = 0.0
	flash_timer = 0.0
	squash_timer = 0.0

	monitoring = true
	set_physics_process(true)
	show()
	_update_visuals()
	queue_redraw()


func deactivate() -> void:
	is_active = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	hide()


func _physics_process(delta: float) -> void:
	if not is_active or not is_instance_valid(target):
		return

	if touch_cooldown > 0.0:
		touch_cooldown -= delta
	if shoot_interval > 0.0 and shoot_cooldown > 0.0:
		shoot_cooldown -= delta
	if dash_interval > 0.0 and dash_timer > 0.0:
		dash_timer -= delta
	if dash_active_timer > 0.0:
		dash_active_timer = max(0.0, dash_active_timer - delta)
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_multiplier = 1.0
	if flash_timer > 0.0:
		flash_timer -= delta
	if squash_timer > 0.0:
		squash_timer = max(0.0, squash_timer - delta)

	# Visual modulation / squash is cheap and doesn't require redraw.
	_update_modulate()
	if body_sprite != null:
		if squash_timer > 0.0:
			var t = 1.0 - (squash_timer / 0.10)
			t = clamp(t, 0.0, 1.0)
			var ease_out = 1.0 - pow(1.0 - t, 3.0)
			var punch = Vector2(1.22, 0.84)
			body_sprite.scale = body_sprite_base_scale * punch.lerp(Vector2.ONE, ease_out)
		else:
			body_sprite.scale = body_sprite_base_scale

	var to_player = target.global_position - global_position
	var distance = to_player.length()
	if distance > 0.001:
		if dash_interval > 0.0 and dash_timer <= 0.0:
			dash_timer = dash_interval
			dash_active_timer = dash_duration
		var dash_mult = dash_multiplier if dash_active_timer > 0.0 else 1.0
		global_position += (to_player / distance) * speed * slow_multiplier * dash_mult * delta
		# Rotate only the sprite (keeps HP bars horizontal).
		if body_sprite != null and (archetype_id in ["sprinter", "stalker", "shooter"] or is_boss):
			body_sprite.rotation = to_player.angle()
		elif body_sprite != null:
			body_sprite.rotation = 0.0

	if distance <= radius + 15.0 and touch_cooldown <= 0.0:
		target.take_damage(touch_damage)
		touch_cooldown = touch_interval

	if shoot_interval > 0.0 and shoot_cooldown <= 0.0:
		shoot_cooldown = shoot_interval
		if distance >= radius + 38.0:
			var direction = Vector2.RIGHT
			if distance > 0.001:
				direction = to_player / distance
			emit_signal(
				"wants_shot",
				self,
				global_position,
				direction.rotated(randf_range(-0.08, 0.08)),
				{
					"damage": projectile_damage,
					"speed": projectile_speed,
					"radius": projectile_radius,
					"lifetime": projectile_lifetime
				}
			)


func apply_projectile_hit(amount: float) -> void:
	if not is_active:
		return

	hp -= amount
	flash_timer = 0.08
	squash_timer = 0.10
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
	if is_elite:
		draw_arc(Vector2.ZERO, radius + 3.8, -PI * 0.88, PI * 0.88, 26, Color(1.0, 0.80, 0.62, 0.78), 2.0)
	if is_boss:
		draw_arc(Vector2.ZERO, radius + 6.6, -PI * 0.92, PI * 0.92, 38, Color(1.0, 0.92, 0.74, 0.72), 3.0)

	if show_hp_bar or is_boss:
		var denom = max(1.0, max_hp)
		var ratio = clamp(hp / denom, 0.0, 1.0)
		var bar_w = max(40.0, radius * 2.8)
		var bar_h = 6.0 if is_boss else 5.0
		var y = -radius - (24.0 if is_boss else 18.0)
		var bg = Color(0.04, 0.06, 0.10, 0.78)
		var fill = Color(0.24, 0.96, 0.78).lerp(Color(0.96, 0.28, 0.40), 1.0 - ratio)
		fill.a = 0.92
		draw_rect(Rect2(Vector2(-bar_w * 0.5, y), Vector2(bar_w, bar_h)), bg, true)
		draw_rect(Rect2(Vector2(-bar_w * 0.5, y), Vector2(bar_w * ratio, bar_h)), fill, true)
		draw_rect(Rect2(Vector2(-bar_w * 0.5, y), Vector2(bar_w, bar_h)), Color(0.80, 0.92, 1.0, 0.22), false, 1.0)

	# Face expressions are drawn on top of the SVG sprite (sprite draws behind parent).
	# This provides cheap per-level visual variety without new assets.
	if not is_boss:
		_draw_face()


func _draw_face() -> void:
	var r = radius
	if r <= 1.0:
		return

	var seed = float((face_seed % 997) + 1)
	var wiggle = sin(seed * 0.27) * 0.12
	var eye_x = r * (0.28 + wiggle * 0.05)
	var eye_y = r * (0.05 + cos(seed * 0.11) * 0.03)
	var eye_r = max(1.2, r * 0.18)
	var pupil_r = max(0.6, eye_r * 0.35)
	var mouth_y = r * 0.42
	var mouth_w = r * (0.70 + sin(seed * 0.19) * 0.05)

	# Mask out the base SVG face so our expression reads cleanly.
	var mask_col = body_color.lerp(Color(0.0, 0.0, 0.0), 0.10)
	mask_col.a = 0.95
	draw_circle(Vector2(0.0, r * 0.16), r * 0.82, mask_col)

	var ink = Color(0.06, 0.10, 0.16, 0.95)
	var highlight = Color(0.98, 1.0, 1.0, 0.85)

	var variant = posmod(face_variant, 6)
	match variant:
		0:
			# Neutral
			draw_circle(Vector2(-eye_x, eye_y), eye_r, ink)
			draw_circle(Vector2(eye_x, eye_y), eye_r, ink)
			draw_circle(Vector2(-eye_x + eye_r * 0.20, eye_y - eye_r * 0.15), pupil_r, highlight)
			draw_circle(Vector2(eye_x + eye_r * 0.20, eye_y - eye_r * 0.15), pupil_r, highlight)
			draw_arc(Vector2(0.0, mouth_y), mouth_w * 0.35, 0.15, PI - 0.15, 18, ink, 2.2)
		1:
			# Angry
			var brow_y = eye_y - eye_r * 1.05
			draw_line(Vector2(-eye_x - eye_r * 0.55, brow_y), Vector2(-eye_x + eye_r * 0.55, brow_y + eye_r * 0.28), ink, 2.6)
			draw_line(Vector2(eye_x - eye_r * 0.55, brow_y + eye_r * 0.28), Vector2(eye_x + eye_r * 0.55, brow_y), ink, 2.6)
			draw_circle(Vector2(-eye_x, eye_y), eye_r * 0.82, ink)
			draw_circle(Vector2(eye_x, eye_y), eye_r * 0.82, ink)
			draw_arc(Vector2(0.0, mouth_y + r * 0.04), mouth_w * 0.33, PI + 0.2, TAU - 0.2, 18, ink, 2.4)
		2:
			# Scared
			draw_circle(Vector2(-eye_x, eye_y), eye_r * 1.08, ink)
			draw_circle(Vector2(eye_x, eye_y), eye_r * 1.08, ink)
			draw_circle(Vector2(-eye_x, eye_y), pupil_r * 0.60, highlight)
			draw_circle(Vector2(eye_x, eye_y), pupil_r * 0.60, highlight)
			draw_circle(Vector2(0.0, mouth_y + r * 0.02), r * 0.18, ink)
		3:
			# Smug
			draw_circle(Vector2(-eye_x, eye_y), eye_r, ink)
			draw_circle(Vector2(eye_x, eye_y), eye_r, ink)
			draw_rect(Rect2(Vector2(-eye_x - eye_r * 1.05, eye_y - eye_r * 0.35), Vector2(eye_r * 2.1, eye_r * 0.70)), mask_col, true)
			draw_circle(Vector2(eye_x + eye_r * 0.18, eye_y - eye_r * 0.12), pupil_r, highlight)
			draw_arc(Vector2(0.0, mouth_y), mouth_w * 0.40, 0.05, PI - 0.05, 18, ink, 2.6)
		4:
			# Dizzy
			var xh = eye_r * 0.75
			draw_line(Vector2(-eye_x - xh, eye_y - xh), Vector2(-eye_x + xh, eye_y + xh), ink, 2.2)
			draw_line(Vector2(-eye_x - xh, eye_y + xh), Vector2(-eye_x + xh, eye_y - xh), ink, 2.2)
			draw_line(Vector2(eye_x - xh, eye_y - xh), Vector2(eye_x + xh, eye_y + xh), ink, 2.2)
			draw_line(Vector2(eye_x - xh, eye_y + xh), Vector2(eye_x + xh, eye_y - xh), ink, 2.2)
			draw_arc(Vector2(0.0, mouth_y + r * 0.02), mouth_w * 0.32, 0.3, PI - 0.3, 18, ink, 2.2)
		_:
			# Shocked
			draw_circle(Vector2(-eye_x, eye_y), eye_r * 1.10, ink)
			draw_circle(Vector2(eye_x, eye_y), eye_r * 1.10, ink)
			draw_circle(Vector2(-eye_x + eye_r * 0.22, eye_y - eye_r * 0.22), pupil_r * 0.70, highlight)
			draw_circle(Vector2(eye_x + eye_r * 0.22, eye_y - eye_r * 0.22), pupil_r * 0.70, highlight)
			draw_circle(Vector2(0.0, mouth_y + r * 0.02), r * 0.16, ink)
