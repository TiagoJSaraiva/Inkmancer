extends BaseUnit
class_name Player

@export var max_mana: float = 100.0
## Tinta regenerada por segundo
@export var mana_regen: float = 5.0
@export var list_of_carimbos: Array[Dictionary]

@export_group("Regeneração de vida")
@export var health_regen_per_second: float = 2.0
## Segundos sem levar dano antes de começar a regenerar
@export var health_regen_delay: float = 4.0

var current_mana: float
var index_counter : int = 0
var _time_since_damage: float = 0.0

@onready var anim_player: AnimationPlayer = $mago/AnimationPlayer
const MORTE_SCENE = preload("res://menus/morte.tscn")

var hud : CanvasLayer
var button_manager: Node

func _ready() -> void:
	super._ready()
	current_mana = max_mana
	hud = get_node("../HUD")
	button_manager = get_node("../ButtonManager")
	add_to_group("player")
	ArrowManager.player = self

	call_deferred("_refresh_hud")


func _refresh_hud() -> void:
	hud.atualizar_vida(current_health, max_health)
	hud.atualizar_mana(current_mana, max_mana)


func _physics_process(delta: float) -> void:
	if state == UnitState.DEAD:
		return

	match state:
		UnitState.MOVING:
			anim_player.play("walk-Armature_001")
		UnitState.IDLE:
			anim_player.play("idle-Armature_001")

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("walk_left", "walk_right", "walk_front", "walk_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y)

	if state != UnitState.ATTACKING:
		if direction != Vector3.ZERO:
			state = UnitState.MOVING
			direction = direction.normalized()
			direction = direction.rotated(Vector3.UP, -PI / 4)

			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		else:
			state = UnitState.IDLE
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if direction.length() > 0 and state != UnitState.ATTACKING:
		rotation.y = atan2(direction.x, direction.z)

	move_and_slide()


func _process(delta: float) -> void:
	if state == UnitState.DEAD:
		return

	if current_mana < max_mana:
		current_mana = min(current_mana + mana_regen * delta, max_mana)
		hud.atualizar_mana(current_mana, max_mana)

	_time_since_damage += delta
	if _time_since_damage >= health_regen_delay and current_health < max_health:
		current_health = min(current_health + health_regen_per_second * delta, max_health)
		hud.atualizar_vida(current_health, max_health)

	super._process(delta)


## Toca o som de carimbada (usado ao invocar uma unidade).
func play_summon_sound() -> void:
	if state == UnitState.DEAD:
		return
	$AudioCarimbo.play()


func take_damage(amount: float) -> void:
	if state == UnitState.DEAD:
		return

	current_health -= amount
	_time_since_damage = 0.0
	hud.atualizar_vida(current_health, max_health)

	if current_health <= 0.0:
		die()


func behavior_ai(_delta):
	pass


func die():
	if state == UnitState.DEAD:
		return
	state = UnitState.DEAD
	velocity = Vector3.ZERO
	anim_player.play("morte")
	UiUtil.show_menu(get_tree(), MORTE_SCENE.instantiate())


func gain_mana(amount: float) -> void:
	if state == UnitState.DEAD:
		return
	current_mana = min(current_mana + amount, max_mana)
	hud.atualizar_mana(current_mana, max_mana)


func spend_mana(_mana: float):
	current_mana = max(current_mana - _mana, 0.0)
	hud.atualizar_mana(current_mana, max_mana)


const MAX_CARIMBOS: int = 4

func carimbos_cheio() -> bool:
	return list_of_carimbos.size() >= MAX_CARIMBOS


## Raridade do próximo carimbo, pela ordem de coleta: comum, comum, incomum, raro.
func proxima_raridade() -> Carimbo.Raridade:
	match list_of_carimbos.size():
		0, 1:
			return Carimbo.Raridade.COMUM
		2:
			return Carimbo.Raridade.INCOMUM
		_:
			return Carimbo.Raridade.RARO


func add_carimbo(unit_type: Carimbo.TipoUnidade, unit_attack, unit_hp, unit_ms, carimbo_rarity: Carimbo.Raridade):
	if carimbos_cheio():
		return
	list_of_carimbos.push_back(
		{
			"unit_type": unit_type,
			"unit_attack": unit_attack,
			"unit_hp": unit_hp,
			"unit_ms": unit_ms,
			"rarity": carimbo_rarity
		}
	)
	button_manager.spawn_interface(index_counter, unit_type, carimbo_rarity)
	index_counter += 1
