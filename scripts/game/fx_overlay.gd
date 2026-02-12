extends Node2D
class_name BluethFxOverlay

var game_ref: Node = null


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	# The overlay is purely visual and should keep drawing even during hitstop.
	queue_redraw()


func _draw() -> void:
	if game_ref == null or not is_instance_valid(game_ref):
		return
	if bool(game_ref.ended):
		return

	_draw_particles()
	_draw_floating_texts()
	_draw_boss_slam()
	_draw_boss_beams()


func _draw_particles() -> void:
	for p in game_ref.particle_effects:
		var ratio_p = clamp(float(p.get("time", 0.0)) / max(0.001, float(p.get("duration", 0.25))), 0.0, 1.0)
		var alpha_p = 1.0 - ratio_p
		var col_p: Color = p.get("color", Color(1.0, 1.0, 1.0))
		col_p.a *= alpha_p
		draw_circle(p.get("pos", Vector2.ZERO), float(p.get("size", 2.0)) * (0.85 + 0.55 * ratio_p), col_p)


func _draw_floating_texts() -> void:
	if (game_ref.floating_texts as Array).is_empty():
		return
	var font = ThemeDB.fallback_font
	if font == null:
		return

	for fx in game_ref.floating_texts:
		var ratio_t = clamp(float(fx.get("time", 0.0)) / max(0.001, float(fx.get("duration", 0.6))), 0.0, 1.0)
		var alpha_t = 1.0 - ratio_t
		var pos = fx.get("pos", Vector2.ZERO) as Vector2
		pos.y += -14.0 * ratio_t
		var text = String(fx.get("text", ""))
		var size = int(fx.get("size", 18))
		var col_t: Color = fx.get("color", Color(1.0, 1.0, 1.0))
		col_t.a *= alpha_t
		var half_w = float(fx.get("half_w", 0.0))
		var base = pos - Vector2(half_w, 0.0)

		# Quick outline for readability.
		var outline = Color(0.0, 0.0, 0.0, col_t.a * 0.8)
		draw_string(font, base + Vector2(1.0, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline)
		draw_string(font, base + Vector2(-1.0, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline)
		draw_string(font, base + Vector2(1.0, -1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline)
		draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col_t)


func _draw_boss_beams() -> void:
	# Level 15 boss gets a telegraphed beam burst.
	if game_ref.boss_ref == null or not is_instance_valid(game_ref.boss_ref):
		return
	if not game_ref.boss_ref.is_active:
		return
	if int(game_ref.boss_level) != 15:
		return
	if float(game_ref.boss_beam_fire_timer) <= 0.0:
		return

	var origin = game_ref.boss_ref.global_position
	var direction = Vector2.RIGHT.rotated(float(game_ref.boss_beam_target_angle))
	var length = 860.0
	var width = 26.0
	var col_outer: Color = game_ref.realm_palette.get("danger", Color(1.0, 0.36, 0.50))
	col_outer.a = 0.45 * game_ref.access_flash_scale
	var col_inner = Color(0.98, 0.98, 1.0, 0.70 * game_ref.access_flash_scale)
	draw_line(origin, origin + direction * length, col_outer, width + 10.0)
	draw_line(origin, origin + direction * length, col_inner, width)


func _draw_boss_slam() -> void:
	# Level 5 boss gets a telegraphed slam ring.
	if game_ref.boss_ref == null or not is_instance_valid(game_ref.boss_ref):
		return
	if not game_ref.boss_ref.is_active:
		return
	if int(game_ref.boss_level) != 5:
		return
	if float(game_ref.boss_slam_windup) <= 0.0:
		return

	var duration = 0.55
	var ratio = 1.0 - clamp(float(game_ref.boss_slam_windup) / duration, 0.0, 1.0)
	var origin = game_ref.boss_slam_origin
	var radius = float(game_ref.boss_slam_radius)

	var danger: Color = game_ref.realm_palette.get("danger", Color(1.0, 0.36, 0.50))
	var outer = danger
	outer.a = (0.10 + 0.26 * ratio) * float(game_ref.access_flash_scale)
	var inner = Color(0.98, 0.98, 1.0, (0.14 + 0.30 * ratio) * float(game_ref.access_flash_scale))

	draw_circle(origin, radius, Color(danger.r, danger.g, danger.b, outer.a * 0.10))
	draw_arc(origin, radius, 0.0, TAU, 60, outer, 5.0 + ratio * 3.0)
	draw_arc(origin, radius * 0.72, 0.0, TAU, 48, inner, 2.0 + ratio * 2.0)
