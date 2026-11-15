extends CharacterBody3D
class_name BaseUnit

const LAYER_WORLD: int = 1
const LAYER_ALLY_UNITS: int = 1 << 1
const LAYER_ENEMY_UNITS: int = 1 << 2
const LAYER_PROJECTILE_ALLY: int = 1 << 3
const LAYER_PROJECTILE_ENEMY: int = 1 << 4

enum Faction { ALLY, ENEMY }
enum UnitState { IDLE, MOVING, CHASING, ATTACKING, DEAD }

@export var faction: Faction
@export var max_health: float = 100.0
@export var move_speed: float = 5.0
@export var damage: float = 10.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 2.0
## Raio aproximado do corpo; o alcance de quem ataca esta unidade conta até a borda
@export var body_radius: float = 0.5
@export var show_health_bar: bool = true
@export var health_bar_scene: PackedScene
@export var health_bar_offset: Vector3 = Vector3(0, 3.2, 0)
@export var health_bar_scale: Vector3 = Vector3(1, 1, 1)

var health_bar_instance: HealthBar3D = null
var current_health: float
var state: UnitState = UnitState.IDLE
var target: BaseUnit = null
var move_target_position: Vector3
var attack_cooldown: float = 0.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Tinta que o jogador recebe ao matar uma unidade inimiga
const ENEMY_INK_REWARD: float = 3.0
const ATTACK_AUDIO_NODES: Array[String] = ["AudioAtaque", "AudioFlecha", "AudioTiro"]

# Tempo de vida (aliados invocados "secam"). 0 = infinito.
var lifetime: float = 0.0
var _lifetime_left: float = 0.0
var _attack_audio: Node = null


func _ready() -> void:
	current_health = max_health
	add_to_group("base_unit")
	_configure_collision_layers()
	_lifetime_left = lifetime

	for audio_name in ATTACK_AUDIO_NODES:
		_attack_audio = get_node_or_null(audio_name)
		if _attack_audio != null:
			break

	if show_health_bar and health_bar_scene != null:
		call_deferred("_spawn_health_bar")


func _configure_collision_layers() -> void:
	if faction == Faction.ALLY:
		collision_layer = LAYER_ALLY_UNITS
		collision_mask = LAYER_WORLD | LAYER_ALLY_UNITS | LAYER_ENEMY_UNITS
	else:
		collision_layer = LAYER_ENEMY_UNITS
		collision_mask = LAYER_WORLD | LAYER_ALLY_UNITS | LAYER_ENEMY_UNITS

	var detection_area := get_node_or_null("DetectionArea") as Area3D
	if detection_area != null:
		detection_area.collision_layer = 0
		detection_area.collision_mask = LAYER_ALLY_UNITS | LAYER_ENEMY_UNITS
	
	
func _spawn_health_bar() -> void:
	health_bar_instance = health_bar_scene.instantiate()
	get_parent().add_child(health_bar_instance)

	health_bar_instance.global_position = global_position + health_bar_offset
	health_bar_instance.scale = health_bar_scale
	health_bar_instance.setup(max_health, faction)
	
	
func _process(delta: float) -> void:
	if health_bar_instance != null:
		health_bar_instance.global_position = global_position + health_bar_offset
		health_bar_instance.rotation_degrees = Vector3(0, 135, 0)
	
	
func _physics_process(delta: float) -> void:
	if state == UnitState.DEAD:
		return
	
	if lifetime > 0.0:
		_lifetime_left -= delta
		if _lifetime_left <= 0.0:
			die()
			return
		# Pisca nos últimos segundos para avisar que vai secar
		visible = _lifetime_left > 3.0 or fmod(_lifetime_left, 0.4) > 0.2

	update_cooldowns(delta)
	behavior_ai(delta)
	
	match state:
		UnitState.MOVING:
			process_movement()
		UnitState.CHASING:
			process_chasing()
		UnitState.ATTACKING:
			process_attack()
		UnitState.IDLE:
			velocity = Vector3.ZERO

	move_and_slide()
	_update_prop_stuck(delta)


## Tempo (s) preso contra um prop até passar a atravessá-lo
const STUCK_TIME_TO_GHOST: float = 2.0
## Quanto (m) a unidade precisa se afastar para deixar de contar como presa
const STUCK_ANCHOR_RADIUS: float = 1.0
## Normais com y acima disto são chão (não contam como prop bloqueando)
const PROP_NORMAL_MAX_Y: float = 0.7

var _stuck_anchor: Vector3
var _stuck_time: float = 0.0
## Props que a unidade está atravessando (com exceção de colisão ativa)
var _ghosted_props: Array[PhysicsBody3D] = []
var _body_shape: CollisionShape3D = null


## Se a unidade fica presa tentando andar contra um prop, desliga a colisão
## com ele até ela sair do outro lado. Não usa distância fixa: a exceção só
## é desfeita quando a forma da unidade não sobrepõe mais o prop, então
## funciona igual para props finos e grossos.
func _update_prop_stuck(delta: float) -> void:
	_release_cleared_props()

	var trying_to_move := state == UnitState.MOVING or state == UnitState.CHASING
	var blocking: Array[PhysicsBody3D] = []
	if trying_to_move:
		blocking = _get_blocking_props()

	if blocking.is_empty():
		_stuck_time = 0.0
		_stuck_anchor = global_position
		return

	var moved := global_position - _stuck_anchor
	moved.y = 0.0
	if moved.length() > STUCK_ANCHOR_RADIUS:
		_stuck_time = 0.0
		_stuck_anchor = global_position
		return

	_stuck_time += delta
	if _stuck_time < STUCK_TIME_TO_GHOST:
		return

	for body in blocking:
		if not _ghosted_props.has(body):
			add_collision_exception_with(body)
			_ghosted_props.append(body)
	_stuck_time = 0.0
	_stuck_anchor = global_position


func _get_blocking_props() -> Array[PhysicsBody3D]:
	var result: Array[PhysicsBody3D] = []
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var body := collision.get_collider() as StaticBody3D
		if body == null:
			continue
		if collision.get_normal().y > PROP_NORMAL_MAX_Y:
			continue
		if not result.has(body):
			result.append(body)
	return result


func _release_cleared_props() -> void:
	if _ghosted_props.is_empty():
		return

	var overlapping := _get_overlapping_world_bodies()
	for body in _ghosted_props.duplicate():
		if not is_instance_valid(body):
			_ghosted_props.erase(body)
			continue
		if not overlapping.has(body):
			remove_collision_exception_with(body)
			_ghosted_props.erase(body)


func _get_overlapping_world_bodies() -> Array:
	if _body_shape == null:
		for child in get_children():
			if child is CollisionShape3D and child.shape != null:
				_body_shape = child
				break
	if _body_shape == null:
		return []

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _body_shape.shape
	query.transform = _body_shape.global_transform
	query.collision_mask = LAYER_WORLD
	query.margin = 0.2
	query.exclude = [get_rid()]

	var bodies: Array = []
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 32):
		bodies.append(hit["collider"])
	return bodies
	
	
func update_cooldowns(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	
	
func move_to(position: Vector3) -> void:
	move_target_position = position
	target = null
	state = UnitState.MOVING
	
	
func process_movement() -> void:
	var direction: Vector3 = move_target_position - global_position
	direction.y = 0.0
	
	if direction.length() < 0.1:
		velocity = Vector3.ZERO
		state = UnitState.IDLE
		return
	
	direction = direction.normalized()
	velocity = direction * move_speed
	rotate_towards(move_target_position)
	
	
## Multiplica vida e dano (usado no spawn para escalar inimigos com o tempo).
## Deve ser chamado antes de adicionar a unidade na árvore.
func apply_stat_multiplier(mult: float) -> void:
	max_health *= mult
	damage *= mult


static func is_unit_alive(unit) -> bool:
	return unit != null and is_instance_valid(unit) and unit.state != UnitState.DEAD


## Folga (m) além do alcance antes de sair do ataque e voltar a perseguir.
## Evita alternar entre perseguir e atacar a cada quadro no limite do alcance.
const ATTACK_RANGE_TOLERANCE: float = 0.75


## Distância horizontal até a borda do corpo do alvo (ignora a altura, que
## varia entre modelos e faria as checagens de alcance discordarem).
func distance_to_target_edge(unit: BaseUnit) -> float:
	var offset: Vector3 = unit.global_position - global_position
	offset.y = 0.0
	return offset.length() - unit.body_radius


func chase(enemy: BaseUnit) -> void:
	if not is_unit_alive(enemy):
		return
	
	target = enemy
	state = UnitState.CHASING
	
	
func process_chasing() -> void:
	if not is_unit_alive(target):
		state = UnitState.IDLE
		return
	
	var direction: Vector3 = target.global_position - global_position
	direction.y = 0.0
	var distance: float = distance_to_target_edge(target)

	if distance <= attack_range:
		velocity = Vector3.ZERO
		state = UnitState.ATTACKING
		return
	
	direction = direction.normalized()
	velocity = direction * move_speed
	rotate_towards(target.global_position)
	
	
func process_attack() -> void:
	if not is_unit_alive(target):
		state = UnitState.IDLE
		return
	
	var distance: float = distance_to_target_edge(target)

	if distance > attack_range + ATTACK_RANGE_TOLERANCE:
		state = UnitState.CHASING
		return
	
	rotate_towards(target.global_position)
	
	if attack_cooldown <= 0.0:
		attack(target)
		attack_cooldown = 1.0 / max(attack_speed, 0.01)
		_play_attack_sound()


func _play_attack_sound() -> void:
	if _attack_audio != null and _attack_audio.has_method("play"):
		_attack_audio.play()
	
	
func take_damage(amount: float) -> void:
	if state == UnitState.DEAD:
		return
	
	current_health -= amount
	
	if health_bar_instance != null:
		health_bar_instance.update_health(current_health)

	if current_health <= 0.0:
		die()
		return

	_on_damaged()
		
	
	
func die() -> void:
	if state == UnitState.DEAD:
		return
	state = UnitState.DEAD
	velocity = Vector3.ZERO

	if faction == Faction.ENEMY:
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("gain_mana"):
			player.gain_mana(ENEMY_INK_REWARD)
	
	if health_bar_instance != null:
		health_bar_instance.queue_free()

	queue_free()
	
	
func rotate_towards(position: Vector3) -> void:
	var dir: Vector3 = position - global_position
	dir.y = 0.0

	if dir.length() > 0.01:
		look_at(global_position + dir, Vector3.UP)
	
	
func attack(enemy: BaseUnit) -> void:
	pass
	
	
func behavior_ai(delta: float) -> void:
	pass
	
func _on_damaged():
	pass
	
