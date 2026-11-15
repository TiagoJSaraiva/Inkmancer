extends BaseUnit
class_name RangedUnit

@export var projectile_scene: PackedScene
@export var projectile_arc_time: float = 0.8
@export var projectile_offset_distance: float = 5.0
## Altura (m) acima dos pés do alvo que o projétil mira (~1.5 = centro do corpo)
@export var aim_height_offset: float = 0.0
## Fração do deslocamento do alvo durante o voo que é antecipada (0 = sem antecipação)
@export var aim_lead_factor: float = 0.0

@onready var attack_origin: Node3D = $AttackOrigin
@onready var detection_area: Area3D = $DetectionArea

var detected_units: Array[BaseUnit] = []

func _ready():
	super._ready()
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is BaseUnit and body != self:
		detected_units.append(body)

func _on_body_exited(body):
	if body is BaseUnit:
		detected_units.erase(body)

func get_valid_enemies() -> Array[BaseUnit]:
	var result: Array[BaseUnit] = []

	for unit in detected_units:
		if is_unit_alive(unit) and unit.faction != faction:
			result.append(unit)

	return result
	
func attack(enemy: BaseUnit) -> void:
	if projectile_scene == null or not is_unit_alive(enemy):
		return

	var projectile = projectile_scene.instantiate()

	get_tree().current_scene.add_child(projectile)

	var start_pos = attack_origin.global_position

	# DIREÇÃO atacante → alvo
	var aim_pos := _get_aim_position(enemy)
	var dir = (aim_pos - global_position)
	dir.y = 0.0
	dir = dir.normalized()

	# PONTO FINAL = 5m atrás do alvo
	var target_point = aim_pos + dir * projectile_offset_distance

	projectile.arc_time = projectile_arc_time
	projectile.initialize(start_pos, target_point, damage, faction)


## Ponto de mira: centro do corpo do alvo, antecipando o movimento durante o voo
func _get_aim_position(enemy: BaseUnit) -> Vector3:
	var pos := enemy.global_position + Vector3.UP * aim_height_offset
	var vel := Vector3(enemy.velocity.x, 0.0, enemy.velocity.z)
	return pos + vel * projectile_arc_time * aim_lead_factor
