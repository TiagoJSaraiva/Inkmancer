extends Node
class_name ButtonManager

const COOLDOWN_FONT := preload("res://utilitarios/EagleLake-Regular.ttf")

@export var interface_scene_melee: PackedScene
@export var interface_scene_ranged: PackedScene
@export var interface_scene_siege: PackedScene
@export var interface_scene_common: PackedScene
@export var interface_scene_uncommon: PackedScene
@export var interface_scene_rare: PackedScene
@export var canvas_layer_path: NodePath
@export var cooldown_icon_alpha: float = 0.6
@export var slot_selector_scale: Vector2 = Vector2(1.0, 1.0)
@export var rarity_icon_scale: Vector2 = Vector2(0.72, 0.72)
@export var type_icon_scale: Vector2 = Vector2(0.72, 0.72)

var canvas_layer: CanvasLayer
var slot_selected: int = 0
var _selectors: Array[Control] = []
var _slots: Array[Control] = []
var _habs: Array[Control] = []
var slot_unit_type_icons: Array = [null, null, null, null]
var slot_unit_rarity_icons: Array = [null, null, null, null]
var slot_cooldown_labels: Array[Label] = []
var slot_cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]


func _ready():
	canvas_layer = get_node(canvas_layer_path)
	for i in range(4):
		_selectors.append(get_node_or_null("../HUD/HUDRoot/SlotSelecter%d" % i) as Control)
		_slots.append(get_node_or_null("../HUD/HUDRoot/Slot%d" % i) as Control)
		_habs.append(get_node_or_null("../HUD/HUDRoot/CentroSection/Habilidades/Hab%d" % i) as Control)
	select_slot(0)
	_sync_slot_layout_with_habilidades()
	_setup_cooldown_labels()


func _process(delta: float) -> void:
	_sync_slot_layout_with_habilidades()
	_apply_slot_selector_scale()
	_reposition_slot_visuals()

	for slot_idx in range(slot_cooldowns.size()):
		if slot_cooldowns[slot_idx] <= 0.0:
			continue

		slot_cooldowns[slot_idx] = max(slot_cooldowns[slot_idx] - delta, 0.0)
		_update_slot_cooldown_visual(slot_idx)


func _setup_cooldown_labels() -> void:
	for i in range(4):
		var slot := _slots[i]
		if slot == null:
			slot_cooldown_labels.append(null)
			continue

		var label := Label.new()
		label.visible = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = Vector2(140, 140)
		label.scale = Vector2(0.9, 0.9)
		label.modulate = Color(0.0, 0.0, 0.0, 1.0)
		label.text = ""

		if COOLDOWN_FONT != null:
			label.add_theme_font_override("font", COOLDOWN_FONT)
			label.add_theme_font_size_override("font_size", 54)

		canvas_layer.add_child(label)
		slot_cooldown_labels.append(label)
		_position_cooldown_label(i)


func _position_cooldown_label(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slot_cooldown_labels.size():
		return

	var label := slot_cooldown_labels[slot_index]
	if label == null:
		return

	var slot := _slots[slot_index]
	if slot == null:
		return

	var center = _get_slot_center(slot)
	label.position = center - label.size / 2


func _get_slot_center(slot: Control) -> Vector2:
	if slot == null:
		return Vector2.ZERO

	return slot.global_position


func _get_visual_size(icon: Control) -> Vector2:
	if icon == null:
		return Vector2.ZERO

	var visual_size := icon.size
	if visual_size.x <= 0.0 or visual_size.y <= 0.0:
		visual_size = icon.get_combined_minimum_size()

	if visual_size == Vector2.ZERO and icon is TextureRect:
		var tex_rect := icon as TextureRect
		if tex_rect.texture != null:
			visual_size = tex_rect.texture.get_size()

	return visual_size


func _sync_slot_layout_with_habilidades() -> void:
	for i in range(4):
		var hab := _habs[i]
		if hab == null:
			continue

		var center := hab.get_global_rect().position + hab.get_global_rect().size / 2.0

		var slot := _slots[i]
		if slot != null:
			slot.global_position = center

		var selector := _selectors[i]
		if selector != null:
			selector.global_position = center


func _apply_slot_selector_scale() -> void:
	for i in range(4):
		var selector := _selectors[i]
		if selector == null:
			continue
		selector.scale = slot_selector_scale


func _apply_symbol_scales() -> void:
	for i in range(4):
		var rarity_icon := slot_unit_rarity_icons[i] as Control
		if rarity_icon != null:
			rarity_icon.scale = rarity_icon_scale

		var type_icon := slot_unit_type_icons[i] as Control
		if type_icon != null:
			type_icon.scale = type_icon_scale


func _reposition_slot_visuals() -> void:
	for i in range(4):
		var slot := _slots[i]
		if slot == null:
			continue

		var center := _get_slot_center(slot)

		var rarity_icon := slot_unit_rarity_icons[i] as Control
		if rarity_icon != null:
			var rarity_size := _get_visual_size(rarity_icon) * rarity_icon.scale
			rarity_icon.position = center - rarity_size / 2.0

		var type_icon := slot_unit_type_icons[i] as Control
		if type_icon != null:
			var type_size := _get_visual_size(type_icon) * type_icon.scale
			type_icon.position = center - type_size / 2.0

		if i < slot_cooldown_labels.size():
			var label := slot_cooldown_labels[i]
			if label != null:
				label.position = center - label.size / 2.0


func is_slot_on_cooldown(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slot_cooldowns.size():
		return false
	return slot_cooldowns[slot_index] > 0.0


func get_slot_cooldown_remaining(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= slot_cooldowns.size():
		return 0.0
	return slot_cooldowns[slot_index]


func start_slot_cooldown(slot_index: int, duration: float) -> void:
	if slot_index < 0 or slot_index >= slot_cooldowns.size():
		return

	slot_cooldowns[slot_index] = max(duration, 0.0)
	_update_slot_cooldown_visual(slot_index)


func _update_slot_cooldown_visual(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slot_cooldowns.size():
		return

	var remaining := slot_cooldowns[slot_index]
	var on_cooldown := remaining > 0.0

	var type_icon = slot_unit_type_icons[slot_index]
	if type_icon != null:
		type_icon.modulate = Color(1, 1, 1, cooldown_icon_alpha) if on_cooldown else Color(1, 1, 1, 1)

	var rarity_icon = slot_unit_rarity_icons[slot_index]
	if rarity_icon != null:
		rarity_icon.modulate = Color(1, 1, 1, cooldown_icon_alpha) if on_cooldown else Color(1, 1, 1, 1)

	if slot_index >= slot_cooldown_labels.size():
		return

	var label := slot_cooldown_labels[slot_index]
	if label == null:
		return

	_position_cooldown_label(slot_index)

	if on_cooldown:
		label.visible = true
		label.text = str(int(ceil(remaining)))
	else:
		label.visible = false
		label.text = ""

func spawn_interface(index: int, unit_type: Carimbo.TipoUnidade, rarity: Carimbo.Raridade):
	if index < 0 or index > 3:
		push_error("Índice de slot inválido: %d" % index)
		return

	if !interface_scene_melee or !interface_scene_ranged or !interface_scene_siege:
		push_error("interface_scene não atribuída!")
		return

	var slot := _slots[index]
	if slot == null:
		push_error("Slot não encontrado. Verifique o caminho.")
		return

	var instance_unit_type: Control
	match unit_type:
		Carimbo.TipoUnidade.GUERREIRO:
			instance_unit_type = interface_scene_melee.instantiate()
		Carimbo.TipoUnidade.ARQUEIRO:
			instance_unit_type = interface_scene_ranged.instantiate()
		Carimbo.TipoUnidade.CANHAO:
			instance_unit_type = interface_scene_siege.instantiate()

	var instance_unit_rarity: Control
	match rarity:
		Carimbo.Raridade.COMUM:
			instance_unit_rarity = interface_scene_common.instantiate()
		Carimbo.Raridade.INCOMUM:
			instance_unit_rarity = interface_scene_uncommon.instantiate()
		Carimbo.Raridade.RARO:
			instance_unit_rarity = interface_scene_rare.instantiate()

	if instance_unit_type == null or instance_unit_rarity == null:
		push_error("Falha ao instanciar ícones do slot %d" % index)
		return

	# Adiciona ao Canvas (raridade atrás, tipo por cima)
	if slot_unit_type_icons[index] != null:
		slot_unit_type_icons[index].queue_free()
	if slot_unit_rarity_icons[index] != null:
		slot_unit_rarity_icons[index].queue_free()

	canvas_layer.add_child(instance_unit_rarity)
	canvas_layer.add_child(instance_unit_type)

	instance_unit_rarity.scale = rarity_icon_scale
	instance_unit_type.scale = type_icon_scale
	slot_unit_type_icons[index] = instance_unit_type
	slot_unit_rarity_icons[index] = instance_unit_rarity
	_apply_symbol_scales()
	_reposition_slot_visuals()
	_update_slot_cooldown_visual(index)


func select_slot(idx: int) -> void:
	if idx < 0 or idx > 3:
		return
	slot_selected = idx
	for i in range(_selectors.size()):
		if _selectors[i] != null:
			_selectors[i].visible = i == idx
	var hud = get_node_or_null("../HUD")
	if hud != null and hud.has_method("destacar_habilidade"):
		hud.destacar_habilidade(idx)


func _input(event: InputEvent) -> void:
	for i in range(4):
		if event.is_action_pressed("slot_%d" % i):
			select_slot(i)
			return
