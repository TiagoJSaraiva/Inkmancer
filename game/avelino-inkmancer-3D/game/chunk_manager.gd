extends Node3D

@export var chunk_size : int = 128
@export var world_radius : int = 5   # Quantas chunk pra cada lado
@export var world_seed : int = 12345
@export var carimbo_scene : PackedScene
## Carimbo que já fica no mapa desde o início (entra no cálculo da rota)
@export var fixed_carimbo : Node3D
## Faixa (m) do menor caminho do jogador até coletar todos os carimbos
@export var carimbo_route_min : float = 900.0
@export var carimbo_route_max : float = 1200.0
## Distância mínima (m) entre dois carimbos, para não nascerem amontoados
@export var carimbo_min_spacing : float = 100.0

const CARIMBOS_SORTEADOS : int = 3
const CARIMBO_ROUTE_ATTEMPTS : int = 400

var chunk_pool : Array = [] # Pool de chunks (definida no _ready)

var chunks : Dictionary = {} # Dicionário para armazenar chunks gerados

var rng : RandomNumberGenerator

func _ready():
	randomize_seed()
	setup_chunk_pool()
	generate_world()
	spawn_carimbos()


func randomize_seed():
	rng = RandomNumberGenerator.new()
	world_seed = int(Time.get_unix_time_from_system())
	rng.seed = world_seed


func setup_chunk_pool():
	# Cada lista é composta de: [referência a um chunk, peso na pool]

	chunk_pool = [
		[preload("res://chunks/common/common_chunk_1.tscn"), 1],
		[preload("res://chunks/common/common_chunk_2.tscn"), 5],
		[preload("res://chunks/common/common_chunk_3.tscn"), 1],
		[preload("res://chunks/common/common_chunk_4.tscn"), 1],
		[preload("res://chunks/common/common_chunk_5.tscn"), 1],
	]


func generate_world():

	# Registrar o spawn chunk como (0,0)
	chunks[Vector2i(0,0)] = self

	for x in range(-world_radius, world_radius + 1):
		for z in range(-world_radius, world_radius + 1):

			var coord = Vector2i(x, z)

			# Pula o centro (já existe)
			if coord == Vector2i(0,0):
				continue

			spawn_chunk_at(coord)


func spawn_chunk_at(coord: Vector2i):

	if chunks.has(coord):
		return

	var scene = get_weighted_chunk()
	var chunk_instance = scene.instantiate()

	add_child(chunk_instance)

	chunk_instance.position = Vector3(
		coord.x * chunk_size,
		0,
		coord.y * chunk_size
	)

	chunks[coord] = chunk_instance


func get_weighted_chunk() -> PackedScene:

	var total_weight = 0

	for entry in chunk_pool:
		total_weight += entry[1]

	var roll = rng.randi_range(1, total_weight)

	var cumulative = 0

	for entry in chunk_pool:
		cumulative += entry[1]
		if roll <= cumulative:
			return entry[0]

	# fallback
	return chunk_pool[0][0]

func spawn_carimbos():

	var spawners = get_tree().get_nodes_in_group("carimbo_spawner")

	if spawners.size() < CARIMBOS_SORTEADOS:
		push_warning("Menos de 3 carimbo_spawner encontrados!")
		return

	for spawner in choose_carimbo_spawners(spawners):
		var instance = carimbo_scene.instantiate()
		spawner.add_child(instance)

		instance.transform = Transform3D.IDENTITY


## Sorteia os spawners de carimbo de modo que o menor caminho do jogador,
## do início até coletar todos (incluindo o carimbo fixo), fique entre
## carimbo_route_min e carimbo_route_max. Assim toda run tem uma distância
## parecida a percorrer.
func choose_carimbo_spawners(spawners: Array) -> Array:
	var fixed_points: Array[Vector2] = []
	if fixed_carimbo != null and is_instance_valid(fixed_carimbo):
		fixed_points.append(_xz(fixed_carimbo.global_position))

	var start := Vector2.ZERO
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		start = _xz(player.global_position)

	var best: Array = []
	var best_error := INF
	var target_mid := (carimbo_route_min + carimbo_route_max) / 2.0

	for _attempt in range(CARIMBO_ROUTE_ATTEMPTS):
		var picked := _pick_distinct(spawners, CARIMBOS_SORTEADOS)
		var points: Array[Vector2] = fixed_points.duplicate()
		for s in picked:
			points.append(_xz(s.global_position))

		if not _min_spacing_ok(points):
			continue

		var length := _shortest_route(start, points)
		if length >= carimbo_route_min and length <= carimbo_route_max:
			return picked

		var error: float = abs(length - target_mid)
		if error < best_error:
			best_error = error
			best = picked

	push_warning("Nenhum sorteio de carimbos ficou na faixa de distância; usando o mais próximo")
	if best.is_empty():
		best = _pick_distinct(spawners, CARIMBOS_SORTEADOS)
	return best


func _pick_distinct(items: Array, count: int) -> Array:
	var indices: Array[int] = []
	while indices.size() < count:
		var i := rng.randi_range(0, items.size() - 1)
		if not indices.has(i):
			indices.append(i)
	var result: Array = []
	for i in indices:
		result.append(items[i])
	return result


func _min_spacing_ok(points: Array[Vector2]) -> bool:
	for i in range(points.size()):
		for j in range(i + 1, points.size()):
			if points[i].distance_to(points[j]) < carimbo_min_spacing:
				return false
	return true


## Menor caminho partindo de `start` e passando por todos os pontos
## (força bruta: com 4 pontos são só 24 ordens).
func _shortest_route(start: Vector2, points: Array[Vector2]) -> float:
	var best := INF
	for order in _permutations(range(points.size())):
		var length := 0.0
		var current := start
		for i in order:
			length += current.distance_to(points[i])
			current = points[i]
		best = min(best, length)
	return best


func _permutations(items: Array) -> Array:
	if items.size() <= 1:
		return [items]
	var result: Array = []
	for i in range(items.size()):
		var rest := items.duplicate()
		var head = rest.pop_at(i)
		for perm in _permutations(rest):
			result.append([head] + perm)
	return result


static func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

