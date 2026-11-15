extends BaseUnit

@export var win_scene: PackedScene
@export var retreat_time: float = 3.0
@export var projectile_scene: PackedScene
@export var projectile_arc_time: float = 0.8
@export var projectile_offset_distance: float = 5.0
@export var projectile_splash_radius: float = 1.5
## Altura (m) acima dos pés do alvo que o projétil mira (centro do corpo)
@export var aim_height_offset: float = 1.5
@export var attack_origin_path: NodePath = NodePath("AttackOrigin")

var player: Node3D
var retreat_timer: float = 0.0
var retreated: float = 0.0
var attack_origin: Node3D

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if state == UnitState.ATTACKING:
		get_node("anjo/AnimationPlayer").play("ataque")
	else:
		get_node("anjo/AnimationPlayer").play("idle")

func _ready() -> void:
	super._ready()
	add_to_group("boss")
	player = get_tree().get_first_node_in_group("player")
	attack_origin = get_node_or_null(attack_origin_path)
	if attack_origin == null:
		attack_origin = self


func _on_damaged() -> void:
	retreat_timer = retreat_time

func behavior_ai(delta: float) -> void:
	if state == UnitState.DEAD:
		return

	if player != null and retreat_timer > 0.0 and current_health < max_health / 2.0 and retreated < retreat_time:
		retreat_timer -= delta
		retreated += delta

		var dir = (global_position - player.global_position).normalized()
		move_to(global_position + dir * 3.0)
		return

	var enemies = get_valid_enemies()
	if enemies.size() > 0:
		target = get_closest_enemy(enemies)
		if state != UnitState.ATTACKING:
			chase(target)
		return

	if player is BaseUnit and player.state != UnitState.DEAD:
		if target != player or state != UnitState.ATTACKING:
			chase(player)
		return

	if player != null:
		move_to(player.global_position)


func attack(enemy: BaseUnit) -> void:
	if enemy == null:
		return

	if projectile_scene == null:
		rotate_towards(enemy.global_position)
		enemy.take_damage(damage)
		return

	rotate_towards(enemy.global_position)

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	var start_pos = attack_origin.global_position
	var aim_pos: Vector3 = enemy.global_position + Vector3.UP * aim_height_offset
	var dir = aim_pos - start_pos
	dir.y = 0.0
	dir = dir.normalized()
	var target_point = aim_pos + dir * projectile_offset_distance

	projectile.arc_time = projectile_arc_time
	projectile.splash_radius = projectile_splash_radius
	projectile.initialize(start_pos, target_point, damage, faction)


func get_valid_enemies() -> Array[BaseUnit]:
	var result: Array[BaseUnit] = []
	for unit in get_tree().get_nodes_in_group("base_unit"):
		if unit == self:
			continue
		if not (unit is BaseUnit):
			continue
		if unit.state == UnitState.DEAD:
			continue
		if unit.faction == faction:
			continue
		result.append(unit)
	return result


func get_closest_enemy(enemies: Array[BaseUnit]) -> BaseUnit:
	var closest: BaseUnit = null
	var min_distance := INF

	for unit in enemies:
		var dist = global_position.distance_to(unit.global_position)
		if dist < min_distance:
			min_distance = dist
			closest = unit

	return closest
		
func die():
	if state == UnitState.DEAD:
		return
	var player_dead: bool = player is BaseUnit and player.state == UnitState.DEAD
	if win_scene != null and not player_dead:
		UiUtil.show_menu(get_tree(), win_scene.instantiate())
	super.die()
