extends Node2D
class_name BluethXpOrb

signal collected(orb, value: float)

var is_active = false
var value = 1.0
var player
var forced_attract = false

func _ready() -> void:
	set_physics_process(false)
	hide()


func activate(spawn_position: Vector2, player_ref, xp_value: float) -> void:
	is_active = true
	global_position = spawn_position
	player = player_ref
	value = xp_value
	forced_attract = false
	set_physics_process(true)
	show()


func deactivate() -> void:
	is_active = false
	set_physics_process(false)
	hide()


func _physics_process(delta: float) -> void:
	if not is_active or not is_instance_valid(player):
		deactivate()
		return

	rotation += delta * 2.8
	var pulse = 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.006)
	scale = Vector2.ONE * pulse

	var to_player = player.global_position - global_position
	var distance_sq = to_player.length_squared()
	var magnet_radius = player.pickup_magnet_radius

	if distance_sq <= magnet_radius * magnet_radius:
		forced_attract = true

	if forced_attract:
		var distance = max(0.001, sqrt(distance_sq))
		var speed = lerp(120.0, 520.0, clamp(1.0 - (distance / 460.0), 0.0, 1.0))
		global_position += (to_player / distance) * speed * delta

	if distance_sq <= 20.0 * 20.0:
		var gain = value
		deactivate()
		emit_signal("collected", self, gain)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.5, Color(0.28, 0.97, 0.88, 0.16))
	draw_circle(Vector2.ZERO, 5.9, Color(0.32, 0.98, 0.89, 0.22))
	var shape = PackedVector2Array([
		Vector2(0, -5.2),
		Vector2(5.2, 0),
		Vector2(0, 5.2),
		Vector2(-5.2, 0)
	])
	var colors = PackedColorArray([
		Color(0.39, 1.0, 0.92),
		Color(0.39, 1.0, 0.92),
		Color(0.22, 0.80, 0.72),
		Color(0.22, 0.80, 0.72)
	])
	draw_polygon(shape, colors)
	draw_circle(Vector2(-1.2, -1.8), 1.1, Color(0.97, 1.0, 0.98, 0.86))
