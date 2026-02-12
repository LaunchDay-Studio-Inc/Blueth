extends Area2D
class_name BluethPlayerHitbox

var is_active := true
var player_ref: Node = null
var radius := 18.0

var collision_shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 1 << 0
	collision_mask = 0
	monitoring = false
	monitorable = true

	collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	add_child(collision_shape)


func setup(owner_ref: Node, new_radius: float) -> void:
	player_ref = owner_ref
	radius = max(6.0, new_radius)
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius


func apply_projectile_hit(amount: float) -> void:
	if not is_active:
		return
	if player_ref == null or not is_instance_valid(player_ref):
		return
	if player_ref.has_method("take_damage"):
		player_ref.take_damage(amount)

