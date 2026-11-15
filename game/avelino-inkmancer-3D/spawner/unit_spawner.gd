extends Node3D
class_name UnitSpawner

@export var interval: float = 5.0
@export var unit_pool: Array[PackedScene] = []

const MIN_DIST_SQ: float = 128.0 * 128.0
const MAX_DIST_SQ: float = 256.0 * 256.0

var _last_spawn_time: float = 0.0

func _ready():
	add_to_group("spawner")

## Retorna true se spawnou unidades (até `count`).
func try_spawn(player: Node3D, current_time: float, stat_multiplier: float = 1.0, count: int = 1) -> bool:
	if unit_pool.is_empty():
		return false

	# Verifica intervalo
	if current_time - _last_spawn_time < interval:
		return false

	# Verifica distância (usando squared para evitar sqrt)
	var dist_sq := global_position.distance_squared_to(player.global_position)
	if dist_sq < MIN_DIST_SQ or dist_sq > MAX_DIST_SQ:
		return false

	for i in range(count):
		_spawn_unit(stat_multiplier)
	_last_spawn_time = current_time
	return true


func _spawn_unit(stat_multiplier: float) -> void:
	var scene: PackedScene = unit_pool.pick_random()
	var unit: Node3D = scene.instantiate()
	if unit is BaseUnit:
		unit.apply_stat_multiplier(stat_multiplier)

	get_tree().current_scene.add_child(unit)
	unit.global_position = global_position
