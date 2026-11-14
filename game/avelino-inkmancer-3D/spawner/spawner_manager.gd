extends Node
class_name SpawnManager
	
	
@export var check_interval: float = 1.0
@export var part1: Array[PackedScene]
@export var part2: Array[PackedScene]
@export var part3: Array[PackedScene]
@export var part4: Array[PackedScene]
@export var enemy_limit: int = 6
## Quanto o teto de inimigos cresce a cada minuto
@export var enemy_limit_growth_per_minute: int = 2
## Vida e dano dos inimigos crescem esta fração por minuto (0.08 = +8%/min)
@export var stat_scaling_per_minute: float = 0.08
	
	
class SpawnStage:
	var start_time: float
	var interval: float
	var pool: Array[PackedScene]
	
	func _init(_start_time: float, _interval: float, _pool: Array[PackedScene]):
		start_time = _start_time
		interval = _interval
		pool = _pool
	
	
var stages: Array[SpawnStage] = []
	
var _match_time: float = 0.0
var _current_stage_index: int = -1
	
var _player: Node3D
var _spawners: Array
	
	
func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_spawners = get_tree().get_nodes_in_group("spawner")
	
	_setup_stages()
	_setup_timer()
	
	
func _setup_timer() -> void:
	var timer := Timer.new()
	timer.wait_time = check_interval
	timer.timeout.connect(_on_tick)
	timer.autostart = true
	add_child(timer)
	
	
func _on_tick() -> void:
	_match_time += check_interval
	_update_stage()

	if _player == null or not is_instance_valid(_player):
		return

	# Durante a luta contra o boss não chegam reforços
	if get_tree().get_first_node_in_group("boss") != null:
		return

	var minutes := _match_time / 60.0
	var current_limit := enemy_limit + int(minutes) * enemy_limit_growth_per_minute
	var enemy_count := 0

	for unit in get_tree().get_nodes_in_group("base_unit"):
		if unit.faction == BaseUnit.Faction.ENEMY:
			enemy_count += 1

	# Orçamento do tick: nunca passa do teto, mesmo com vários spawners ativos
	var budget := current_limit - enemy_count
	if budget <= 0:
		return

	var stat_multiplier := 1.0 + stat_scaling_per_minute * minutes
	_spawners.shuffle()
	for spawner in _spawners:
		if budget <= 0:
			break
		if spawner.try_spawn(_player, _match_time, stat_multiplier):
			budget -= 1
		
		
func _setup_stages() -> void:
	# Run de 5 minutos até o boss
	stages = [
		SpawnStage.new(0.0,   5.0, part1),
		SpawnStage.new(60.0,  4.5, part2),
		SpawnStage.new(120.0, 4.0, part2),
		SpawnStage.new(180.0, 3.5, part3),
		SpawnStage.new(240.0, 3.0, part4)
	]
	
	
func _update_stage() -> void:
	var new_index := _get_stage_index_from_time(_match_time)
	
	if new_index == _current_stage_index:
		return
	
	_current_stage_index = new_index
	_apply_stage(stages[new_index])
	
	
func _get_stage_index_from_time(time: float) -> int:
	var index := 0
	
	for i in range(stages.size()):
		if time >= stages[i].start_time:
			index = i
	
	return index
	
	
func _apply_stage(stage: SpawnStage) -> void:
	for spawner in _spawners:
		spawner.interval = stage.interval
		spawner.unit_pool = stage.pool
