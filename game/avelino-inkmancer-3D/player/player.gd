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

@export_group("Ataque de carimbo")
@export var stamp_damage: float = 15.0
@export var stamp_radius: float = 3.0
@export var stamp_cooldown: float = 0.8

const STAMP_ANIMATION := "stamp_attack-Armature_001"

var current_mana: float
var index_counter : int = 0
var _time_since_damage: float = 0.0
var _stamp_cooldown_left: float = 0.0

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

	anim_player.animation_finished.connect(_on_animation_finished)
	call_deferred("_refresh_hud")


func _refresh_hud() -> void:
	hud.atualizar_vida(current_health, max_health)
	hud.atualizar_mana(current_mana, max_mana)


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == STAMP_ANIMATION:
		if state != UnitState.DEAD:
			state = UnitState.IDLE


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		try_stamp_attack()


func _process(delta: float) -> void:
	if state == UnitState.DEAD:
		return

	if _stamp_cooldown_left > 0.0:
		_stamp_cooldown_left -= delta

	if current_mana < max_mana:
		current_mana = min(current_mana + mana_regen * delta, max_mana)
		hud.atualizar_mana(current_mana, max_mana)

	_time_since_damage += delta
	if _time_since_damage >= health_regen_delay and current_health < max_health:
		current_health = min(current_health + health_regen_per_second * delta, max_health)
		hud.atualizar_vida(current_health, max_health)

	super._process(delta)


## Toca a animação/som de carimbada e trava o movimento até ela acabar.
func play_stamp_animation(speed: float = 1.5) -> void:
	if state == UnitState.DEAD:
		return
	state = UnitState.ATTACKING
	anim_player.stop()
	anim_player.play(STAMP_ANIMATION, -1, speed)
	$AudioCarimbo.play()


## Ataque corpo a corpo do jogador: dano em área na direção do mouse.
func try_stamp_attack() -> void:
	if state == UnitState.DEAD or state == UnitState.ATTACKING or _stamp_cooldown_left > 0.0:
		return
	_stamp_cooldown_left = stamp_cooldown

	var aim = _get_mouse_ground_position()
	if aim != null:
		var to_aim: Vector3 = aim - global_position
		to_aim.y = 0.0
		if to_aim.length() > 0.1:
			rotation.y = atan2(to_aim.x, to_aim.z)

	play_stamp_animation(2.0)

	var forward := global_transform.basis.z
	forward.y = 0.0
	var center := global_position + forward.normalized() * (stamp_radius * 0.6)
	for unit in get_tree().get_nodes_in_group("base_unit"):
		if not is_unit_alive(unit) or unit.faction == faction:
			continue
		var offset: Vector3 = unit.global_position - center
		offset.y = 0.0
		if offset.length() <= stamp_radius:
			unit.take_damage(stamp_damage)


func _get_mouse_ground_position():
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var mouse_pos := get_viewport().get_mouse_position()
	var plane := Plane(Vector3.UP, global_position.y)
	return plane.intersects_ray(camera.project_ray_origin(mouse_pos), camera.project_ray_normal(mouse_pos))


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


func add_carimbo(unit_type: Carimbo.TipoUnidade, unit_attack, unit_hp, unit_ms, carimbo_rarity: Carimbo.Raridade):
	if index_counter >= 4:
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
