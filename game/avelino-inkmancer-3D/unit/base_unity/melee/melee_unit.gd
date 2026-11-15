extends BaseUnit
class_name MeleeUnit

var detected_units: Array[BaseUnit] = []

@onready var detection_area: Area3D = $DetectionArea

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

## Animação de ataque (definida pelas subclasses) e AnimationPlayer que a toca
var attack_animation: StringName = &""
var _attack_committed: bool = false
var _attack_time_left: float = 0.0
var _attack_target: BaseUnit = null


func _get_anim_player() -> AnimationPlayer:
	return null


## Verdadeiro enquanto um golpe já iniciado não terminou (a unidade não pode
## se mover, trocar de alvo nem trocar de animação).
func is_attack_committed() -> bool:
	return _attack_committed


## Velocidade extra da animação de ataque, para o golpe caber no intervalo
## entre ataques (senão animações longas reduziriam o DPS).
func _attack_anim_speed() -> float:
	var player := _get_anim_player()
	if player == null or attack_animation == &"" or not player.has_animation(attack_animation):
		return 1.0
	var anim_len: float = player.get_animation(attack_animation).length / max(absf(player.speed_scale), 0.01)
	var interval: float = 1.0 / max(attack_speed, 0.01)
	return max(anim_len / interval, 1.0)


func _attack_duration() -> float:
	var player := _get_anim_player()
	if player == null or attack_animation == &"" or not player.has_animation(attack_animation):
		return 0.0
	var anim_speed: float = max(absf(player.speed_scale), 0.01) * _attack_anim_speed()
	return player.get_animation(attack_animation).length / anim_speed


func _start_attack() -> void:
	_attack_committed = true
	_attack_target = target
	_attack_time_left = _attack_duration()
	attack_cooldown = 1.0 / max(attack_speed, 0.01)
	velocity = Vector3.ZERO
	_play_attack_sound()
	var player := _get_anim_player()
	if player != null and _attack_time_left > 0.0:
		player.stop()
		player.play(attack_animation, -1, _attack_anim_speed())


## Golpe iniciado sempre termina: o dano é aplicado ao fim da animação, mesmo
## que o alvo tenha saído do alcance (desde que ainda esteja vivo).
func process_attack() -> void:
	if _attack_committed:
		velocity = Vector3.ZERO
		_attack_time_left -= get_physics_process_delta_time()
		if _attack_time_left > 0.0:
			return
		_attack_committed = false
		var victim := _attack_target
		_attack_target = null
		if is_unit_alive(victim):
			attack(victim)

	if not is_unit_alive(target):
		state = UnitState.IDLE
		return

	var distance: float = global_position.distance_to(target.global_position) - target.body_radius
	if distance > attack_range:
		state = UnitState.CHASING
		return

	rotate_towards(target.global_position)

	if attack_cooldown <= 0.0:
		_start_attack()
		if _attack_time_left <= 0.0:
			# Sem animação: aplica o dano imediatamente
			_attack_committed = false
			var victim := _attack_target
			_attack_target = null
			attack(victim)


func attack(enemy: BaseUnit):
	if not is_unit_alive(enemy):
		return
	
	rotate_towards(enemy.global_position)
	enemy.take_damage(damage)

func get_valid_enemies() -> Array[BaseUnit]:
	var result: Array[BaseUnit] = []
	
	for unit in detected_units:
		if is_unit_alive(unit) and unit.faction != faction:
			result.append(unit)
	
	return result
