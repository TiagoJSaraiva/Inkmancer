extends Node3D

const MELEE_ALLY_SCENE := preload("res://unit/ally/melee_ally.tscn")
const RANGED_ALLY_SCENE := preload("res://unit/ally/ranged_ally.tscn")
const SIEGE_ALLY_SCENE := preload("res://unit/ally/siege_ally.tscn")

@export var player: BaseUnit
@export var camera: Camera3D
@export var invocation_range: float = 10.0
@export var cursor_circle_radius: float = 0.5
@export var common_mana_cost: float = 30.0
@export var uncommon_mana_cost: float = 35.0
@export var rare_mana_cost: float = 40.0
## Máximo de aliados invocados vivos ao mesmo tempo
@export var max_allies: int = 8
## Bônus por ponto de atributo do carimbo (linear: 5 pontos = +60%)
@export var bonus_por_ponto: float = 0.12
## Segundos até a unidade "secar", por raridade
@export var lifetime_common: float = 40.0
@export var lifetime_uncommon: float = 50.0
@export var lifetime_rare: float = 60.0

const SUMMON_GROUP := "summoned_ally"

var em_modo_invocacao: bool = false
var posicao_invocacao: Vector3 = Vector3.ZERO

var range_mesh: MeshInstance3D
var cursor_mesh: MeshInstance3D

var button_manager: Node
var hud


func _ready():
	call_deferred("_setup_circulos")
	button_manager = get_node("../ButtonManager")
	hud = get_node_or_null("../HUD")


func _setup_circulos():
	range_mesh = MeshInstance3D.new()
	range_mesh.mesh = _gerar_circulo_mesh(invocation_range, 64)
	range_mesh.material_override = _criar_material(Color(0.0, 0.0, 0.001, 0.416))
	range_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	range_mesh.visible = false
	get_tree().current_scene.add_child(range_mesh)

	cursor_mesh = MeshInstance3D.new()
	cursor_mesh.mesh = _gerar_circulo_mesh(cursor_circle_radius, 32)
	cursor_mesh.material_override = _criar_material(Color(1.0, 0.8, 0.2, 0.5))
	cursor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cursor_mesh.visible = false
	get_tree().current_scene.add_child(cursor_mesh)


# Gera um círculo preenchido como ArrayMesh no plano XZ
func _gerar_circulo_mesh(raio: float, segmentos: int) -> ArrayMesh:
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()

	# Centro
	vertices.append(Vector3(0, 0, 0))

	# Vértices da borda
	for i in range(segmentos):
		var angulo = (float(i) / float(segmentos)) * TAU
		vertices.append(Vector3(cos(angulo) * raio, 0, sin(angulo) * raio))

	# Triângulos (leque a partir do centro)
	for i in range(segmentos):
		indices.append(0)
		indices.append(i + 1)
		indices.append((i + 1) % segmentos + 1)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _criar_material(cor: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = cor
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	return mat


func _process(_delta):
	if not em_modo_invocacao or player == null or camera == null:
		return
	if range_mesh == null or cursor_mesh == null:
		return

	# Círculo de range segue o player
	range_mesh.global_position = player.global_position + Vector3(0, 0.05, 0)

	# Posição do mouse no mundo
	var pos_mouse = _get_mouse_world_position()
	if pos_mouse == Vector3.ZERO:
		return

	# Limita dentro da range
	var diff = Vector3(
		pos_mouse.x - player.global_position.x,
		0,
		pos_mouse.z - player.global_position.z
	)
	if diff.length() > invocation_range:
		diff = diff.normalized() * invocation_range

	posicao_invocacao = player.global_position + diff
	cursor_mesh.global_position = posicao_invocacao + Vector3(0, 0.06, 0)


func _unhandled_input(event):
	if not event.is_action_pressed("summon"):
		return
	alternar_modo_invocacao()


## 1º clique mostra o alcance; 2º clique invoca no cursor.
func alternar_modo_invocacao():
	if not em_modo_invocacao:
		_entrar_modo_invocacao()
	else:
		_invocar()
		_sair_modo_invocacao()


func _avisar(texto: String) -> void:
	if hud != null and hud.has_method("mostrar_aviso"):
		hud.mostrar_aviso(texto)


func _entrar_modo_invocacao():
	if range_mesh == null or cursor_mesh == null:
		return
	em_modo_invocacao = true
	range_mesh.global_position = player.global_position + Vector3(0, 0.05, 0)
	range_mesh.visible = true
	cursor_mesh.visible = true


func _sair_modo_invocacao():
	em_modo_invocacao = false
	if range_mesh:
		range_mesh.visible = false
	if cursor_mesh:
		cursor_mesh.visible = false


func _get_mouse_world_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var origem = camera.project_ray_origin(mouse_pos)
	var direcao = camera.project_ray_normal(mouse_pos)

	var plano = Plane(Vector3.UP, player.global_position.y)
	var intersecao = plano.intersects_ray(origem, direcao)

	if intersecao == null:
		return Vector3.ZERO
	return intersecao


func _invocar():
	if player == null:
		return

	if player.state == BaseUnit.UnitState.DEAD:
		return

	if button_manager == null:
		push_warning("ButtonManager não encontrado para invocação.")
		return

	var selected_slot: int = button_manager.slot_selected
	if selected_slot < 0:
		push_warning("Nenhum slot selecionado para invocar.")
		return

	if selected_slot >= player.list_of_carimbos.size():
		_avisar("Slot vazio: encontre um carimbo")
		return

	var carimbo_data: Dictionary = player.list_of_carimbos[selected_slot]
	if carimbo_data.is_empty():
		push_warning("Carimbo inválido no slot selecionado.")
		return

	var carimbo_rarity: int = int(carimbo_data.get("rarity", Carimbo.Raridade.COMUM))
	if button_manager.is_slot_on_cooldown(selected_slot):
		var remaining_cd: float = button_manager.get_slot_cooldown_remaining(selected_slot)
		_avisar("Carimbo recarregando: %.0fs" % ceil(remaining_cd))
		return

	var mana_cost: float = _get_mana_cost_by_rarity(carimbo_rarity)
	if player.current_mana < mana_cost:
		_avisar("Tinta insuficiente (%.0f)" % mana_cost)
		return

	if get_tree().get_nodes_in_group(SUMMON_GROUP).size() >= max_allies:
		_avisar("Limite de %d aliados" % max_allies)
		return

	if not carimbo_data.has("unit_type"):
		push_warning("Carimbo sem unit_type.")
		return

	var unit_scene: PackedScene
	match carimbo_data["unit_type"]:
		Carimbo.TipoUnidade.GUERREIRO:
			unit_scene = MELEE_ALLY_SCENE
		Carimbo.TipoUnidade.ARQUEIRO:
			unit_scene = RANGED_ALLY_SCENE
		Carimbo.TipoUnidade.CANHAO:
			unit_scene = SIEGE_ALLY_SCENE
		_:
			push_warning("Tipo de unidade desconhecido no carimbo.")
			return

	var unit_instance := unit_scene.instantiate() as BaseUnit
	if unit_instance == null:
		push_warning("Falha ao instanciar unidade da invocação.")
		return

	var attack_points: int = int(carimbo_data.get("unit_attack", 0))
	var hp_points: int = int(carimbo_data.get("unit_hp", 0))
	var ms_points: int = int(carimbo_data.get("unit_ms", 0))

	unit_instance.damage *= 1.0 + bonus_por_ponto * attack_points
	unit_instance.max_health *= 1.0 + bonus_por_ponto * hp_points
	unit_instance.move_speed *= 1.0 + bonus_por_ponto * ms_points
	unit_instance.faction = BaseUnit.Faction.ALLY
	unit_instance.lifetime = _get_lifetime_by_rarity(carimbo_rarity)
	unit_instance.add_to_group(SUMMON_GROUP)

	get_tree().current_scene.add_child(unit_instance)
	unit_instance.global_position = posicao_invocacao
	player.spend_mana(mana_cost)
	if player.has_method("play_summon_sound"):
		player.play_summon_sound()

	var cooldown_duration: float = _get_cooldown_by_rarity(carimbo_rarity)
	button_manager.start_slot_cooldown(selected_slot, cooldown_duration)


func _get_cooldown_by_rarity(rarity: int) -> float:
	match rarity:
		Carimbo.Raridade.COMUM:
			return 10.0
		Carimbo.Raridade.INCOMUM:
			return 10.0
		Carimbo.Raridade.RARO:
			return 11.0
		_:
			return 10.0


func _get_lifetime_by_rarity(rarity: int) -> float:
	match rarity:
		Carimbo.Raridade.INCOMUM:
			return lifetime_uncommon
		Carimbo.Raridade.RARO:
			return lifetime_rare
		_:
			return lifetime_common


func _get_mana_cost_by_rarity(rarity: int) -> float:
	match rarity:
		Carimbo.Raridade.COMUM:
			return common_mana_cost
		Carimbo.Raridade.INCOMUM:
			return uncommon_mana_cost
		Carimbo.Raridade.RARO:
			return rare_mana_cost
		_:
			return common_mana_cost
