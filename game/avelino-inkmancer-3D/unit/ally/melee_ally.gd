extends MeleeUnit
class_name MeleeAlly
	
@export var wander_interval: float = 4.0
	
var wander_timer: float = 0.0
var player: Node3D
	
func _ready():
	super._ready()
	attack_animation = &"stamp_attack"
	player = get_tree().get_first_node_in_group("player")
	
func _get_anim_player() -> AnimationPlayer:
	return get_node("minion/AnimationPlayer") as AnimationPlayer


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	match state:
		UnitState.MOVING:
			get_node("minion/AnimationPlayer").play("walk")
		UnitState.CHASING:
			get_node("minion/AnimationPlayer").play("walk")
		UnitState.DEAD:
			get_node("minion/AnimationPlayer").play("morte")
			queue_free()
		UnitState.ATTACKING:
			# A animação de ataque é tocada por _start_attack(); entre golpes, idle
			if not is_attack_committed():
				get_node("minion/AnimationPlayer").play("idle")
		UnitState.IDLE:
			get_node("minion/AnimationPlayer").play("idle")
	
func behavior_ai(delta):

	if state == UnitState.DEAD:
		return

	# Golpe em andamento: não retarget nem muda de estado até terminar
	if is_attack_committed():
		return

	var enemies = get_valid_enemies()

	# PRIORIDADE 1 — Inimigos na área
	if enemies.size() > 0:
		target = get_enemy_closest_to_player(enemies)
		if state != UnitState.ATTACKING:
			chase(target)
		return

	# PRIORIDADE 2 — Player fora da área
	if player != null and not is_player_in_detection():
		move_to(player.global_position)
		return

	# PRIORIDADE 3 — Wander (não interrompe uma caminhada em andamento)
	if state == UnitState.CHASING or state == UnitState.ATTACKING:
		state = UnitState.IDLE
	handle_wander(delta)
	
func is_player_in_detection() -> bool:
	return detection_area.get_overlapping_bodies().has(player)
	
func get_enemy_closest_to_player(enemies: Array[BaseUnit]) -> BaseUnit:
	var closest: BaseUnit = null
	var min_distance := INF
	
	for unit in enemies:
		var dist = unit.global_position.distance_to(player.global_position)
		if dist < min_distance:
			min_distance = dist
			closest = unit
	
	return closest
	
func handle_wander(delta):
	wander_timer -= delta
	
	if wander_timer <= 0:
		wander_timer = wander_interval
		
		var random_dir = Vector3(
			randf_range(-1, 1),
			0,
			randf_range(-1, 1)
		).normalized()
		
		var random_distance = randf_range(2, 5)
		
		move_to(global_position + random_dir * random_distance)
