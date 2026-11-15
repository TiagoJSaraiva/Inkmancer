extends RigidBody3D
class_name Projectile

const LAYER_WORLD: int = 1
const LAYER_ALLY_UNITS: int = 1 << 1
const LAYER_ENEMY_UNITS: int = 1 << 2
const LAYER_PROJECTILE_ALLY: int = 1 << 3
const LAYER_PROJECTILE_ENEMY: int = 1 << 4

@export var arc_time: float = 0.4
@export var max_lifetime: float = 4
## Raio do dano em área ao impactar (0 = só acerta o alvo atingido)
@export var splash_radius: float = 0.0
## Fração do dano aplicada na borda da área
@export var splash_edge_multiplier: float = 0.5

var damage: float
var target_position: Vector3
var gravity: float
var lifetime: float = 0.0
var shooter_faction: BaseUnit.Faction
var has_collided: bool = false


func _ready():
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)


func initialize(start_position: Vector3, target_pos: Vector3, dmg: float, faction: BaseUnit.Faction):
	global_position = start_position
	target_position = target_pos
	damage = dmg
	shooter_faction = faction

	if shooter_faction == BaseUnit.Faction.ALLY:
		collision_layer = LAYER_PROJECTILE_ALLY
		collision_mask = LAYER_ENEMY_UNITS | LAYER_WORLD
	else:
		collision_layer = LAYER_PROJECTILE_ENEMY
		collision_mask = LAYER_ALLY_UNITS | LAYER_WORLD

	launch()


func launch():
	var direction = target_position - global_position
	var horizontal = Vector3(direction.x, 0, direction.z)

	var time = max(arc_time, 0.05)

	var velocity_xz = horizontal / time
	var velocity_y = (direction.y / time) + (0.5 * gravity * time)

	linear_velocity = velocity_xz + Vector3.UP * velocity_y


func _physics_process(delta):

	if has_collided:
		return

	lifetime += delta

	if linear_velocity.length() > 0.1:
		look_at(global_position + linear_velocity, Vector3.UP)

	if lifetime >= max_lifetime:
		queue_free()
		
func _on_body_entered(body):

	if has_collided:
		return

	# Mesmo time → ignora completamente
	if body is BaseUnit and body.faction == shooter_faction:
		return

	has_collided = true

	if splash_radius > 0.0:
		# Alvo atingido em cheio leva o dano total; o resto entra na área
		var direct: BaseUnit = body if body is BaseUnit else null
		if direct != null:
			direct.take_damage(damage)
		_explode(global_position, direct)
		queue_free()
		return

	if body is BaseUnit:
		body.take_damage(damage)
		on_hit_unit(body)
		return

	on_hit_environment(body)


func _explode(center: Vector3, skip: BaseUnit = null) -> void:
	for unit in get_tree().get_nodes_in_group("base_unit"):
		if unit == skip or not BaseUnit.is_unit_alive(unit) or unit.faction == shooter_faction:
			continue
		var offset: Vector3 = unit.global_position - center
		offset.y = 0.0
		var dist := offset.length()
		if dist > splash_radius:
			continue
		var mult: float = lerp(1.0, splash_edge_multiplier, dist / splash_radius)
		unit.take_damage(damage * mult)
	
func on_hit_unit(unit: BaseUnit) -> void:
	queue_free()


func on_hit_environment(body: Node) -> void:
	queue_free()
