extends MeleeUnit
class_name MeleeEnemy

var player: Node3D

func _ready():
	super._ready()
	attack_animation = &"sword_attack"
	player = get_tree().get_first_node_in_group("player")

func _get_anim_player() -> AnimationPlayer:
	return get_node("guerreiro/AnimationPlayer") as AnimationPlayer


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	match state:
		UnitState.MOVING:
			get_node("guerreiro/AnimationPlayer").play("walk")
		UnitState.CHASING:
			get_node("guerreiro/AnimationPlayer").play("walk")
		UnitState.DEAD:
			get_node("guerreiro/AnimationPlayer").play("morte")
			queue_free()
		UnitState.ATTACKING:
			# A animação de ataque é tocada por _start_attack(); entre golpes, idle
			if not is_attack_committed():
				get_node("guerreiro/AnimationPlayer").play("idle")
		UnitState.IDLE:
			get_node("guerreiro/AnimationPlayer").play("idle")

func behavior_ai(delta):

	if state == UnitState.DEAD:
		return

	# Golpe em andamento: não retarget nem muda de estado até terminar
	if is_attack_committed():
		return

	var enemies = get_valid_enemies()

	# PRIORIDADE 1 — Ally detectado (sempre sobrepõe player)
	if enemies.size() > 0:
		target = _get_closest(enemies)
		if state != UnitState.ATTACKING:
			chase(target)
		return

	# PRIORIDADE 2 — Player
	if is_unit_alive(player):
		target = player
		chase(player)


func _get_closest(units: Array[BaseUnit]) -> BaseUnit:
	var closest: BaseUnit = null
	var min_distance := INF
	for unit in units:
		var dist := global_position.distance_squared_to(unit.global_position)
		if dist < min_distance:
			min_distance = dist
			closest = unit
	return closest
