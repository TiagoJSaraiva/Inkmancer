extends Marker3D

## CARIMBO: aponta para o carimbo mais próximo.
## BOSS: aponta para o boss enquanto ele existe e está fora da tela.
enum TargetMode { CARIMBO, BOSS }

@export var distance_from_camera : float = 3.0
@export var target_mode : TargetMode = TargetMode.CARIMBO
## Altura (m) do centro do boss acima da origem dele (usada para saber se está na tela)
@export var boss_center_height : float = 2.24
@export var arrow_color : Color = Color(0.8, 0, 0, 0.6313726)
## Deslocamento (m) na direção do alvo; separa esta seta de outras no mesmo ponto
@export var orbit_radius : float = 0.0

var camera : Camera3D

func _ready():
	camera = get_parent()
	visible = false
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh != null:
		var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat != null:
			mat = mat.duplicate()
			mat.albedo_color = arrow_color
			mesh.set_surface_override_material(0, mat)

func _process(delta):

	if ArrowManager.player == null:
		visible = false
		return

	var target: Node3D = null
	if target_mode == TargetMode.BOSS:
		target = get_boss()
	else:
		target = get_closest_carimbo()

	if target == null:
		visible = false
		return

	update_position(target)
	update_rotation(target)
	update_visibility(target)


func get_boss() -> Node3D:
	var boss := get_tree().get_first_node_in_group("boss") as Node3D
	if boss == null or not is_instance_valid(boss) or boss.is_queued_for_deletion():
		return null
	return boss


func get_closest_carimbo() -> Node3D:

	var player_pos = ArrowManager.player.global_position
	var closest : Node3D = null
	var min_dist := INF

	for c in ArrowManager.carimbos:
		if not is_instance_valid(c):
			continue

		var dist = player_pos.distance_to(c.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = c

	return closest


func update_position(target: Node3D):
	position = Vector3(0, 0, -distance_from_camera)
	if orbit_radius > 0.0 and camera != null:
		# Desloca no plano da tela (espaço local da câmera), sem mudar a profundidade
		var dir: Vector3 = camera.global_basis.inverse() * (target.global_position - global_position)
		dir.z = 0.0
		if dir.length() > 0.01:
			position += dir.normalized() * orbit_radius


func update_rotation(target: Node3D):
	look_at(target.global_position, Vector3.UP)


func update_visibility(target: Node3D):

	if target_mode == TargetMode.BOSS:
		# Some quando o boss já está visível na tela
		var center: Vector3 = target.global_position + Vector3.UP * boss_center_height
		visible = camera == null or not camera.is_position_in_frustum(center)
		return

	var player_pos = ArrowManager.player.global_position
	var dist = player_pos.distance_to(target.global_position)

	visible = dist > distance_from_camera
