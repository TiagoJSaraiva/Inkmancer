extends CanvasLayer

@onready var pocao_vida_liquido = $HUDRoot/VidaSection/PocaoLiquido
@onready var pocao_mana_liquido = $HUDRoot/ManaSection/PocaoLiquido

@onready var vida_section = $HUDRoot/VidaSection
@onready var mana_section = $HUDRoot/ManaSection

@onready var btn_habilidade = [
	$HUDRoot/CentroSection/Habilidades/Hab0,
	$HUDRoot/CentroSection/Habilidades/Hab1,
	$HUDRoot/CentroSection/Habilidades/Hab2,
	$HUDRoot/CentroSection/Habilidades/Hab3,
]

@onready var btn_ataque    = $HUDRoot/CentroSection/AcoesExtra/BtnAtaque
@onready var btn_invocacao = $HUDRoot/CentroSection/AcoesExtra/BtnInvocacao

var habilidade_selecionada: int = 0
var vida_atual: float = 100.0
var vida_max: float = 100.0
var mana_atual: float = 100.0
var mana_max: float = 100.0

var _aviso_label: Label
var _aviso_tween: Tween


func _ready():
	vida_section.mouse_filter = Control.MOUSE_FILTER_STOP
	mana_section.mouse_filter = Control.MOUSE_FILTER_STOP
	vida_section.mouse_entered.connect(_on_vida_hover_enter)
	vida_section.mouse_exited.connect(_on_vida_hover_exit)
	mana_section.mouse_entered.connect(_on_mana_hover_enter)
	mana_section.mouse_exited.connect(_on_mana_hover_exit)

	# Inicializa líquido cheio
	_atualizar_liquido(pocao_vida_liquido, 1.0)
	_atualizar_liquido(pocao_mana_liquido, 1.0)

	# Botões de habilidade: a seleção de slot vive no ButtonManager
	for i in btn_habilidade.size():
		var idx = i
		btn_habilidade[i].pressed.connect(func(): _pedir_slot(idx))

	# Botões de ação
	btn_ataque.pressed.connect(_on_ataque)
	btn_invocacao.pressed.connect(_on_invocacao)

	destacar_habilidade(0)
	_criar_aviso()

	call_deferred("_posicionar_hud")


func _on_vida_hover_enter():
	vida_section.tooltip_text = "Vida: %d / %d" % [int(vida_atual), int(vida_max)]

func _on_vida_hover_exit():
	vida_section.tooltip_text = ""

func _on_mana_hover_enter():
	mana_section.tooltip_text = "Tinta: %d / %d" % [int(mana_atual), int(mana_max)]

func _on_mana_hover_exit():
	mana_section.tooltip_text = ""


func atualizar_vida(valor: float, maximo: float = 100.0):
	vida_max = max(maximo, 1.0)
	vida_atual = clamp(valor, 0, vida_max)
	_atualizar_liquido(pocao_vida_liquido, vida_atual / vida_max)


func atualizar_mana(valor: float, maximo: float = 100.0):
	mana_max = max(maximo, 1.0)
	mana_atual = clamp(valor, 0, mana_max)
	_atualizar_liquido(pocao_mana_liquido, mana_atual / mana_max)


func _atualizar_liquido(liquido: TextureRect, fracao: float):
	var mat = liquido.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("percentual", fracao)
	else:
		push_error("PocaoLiquido '%s' nao tem ShaderMaterial!" % liquido.name)


## Só muda o destaque visual; quem decide o slot é o ButtonManager.
func destacar_habilidade(idx: int):
	for i in btn_habilidade.size():
		btn_habilidade[i].modulate = Color(1, 1, 1, 1)
	habilidade_selecionada = idx
	btn_habilidade[idx].modulate = Color(1.5, 1.2, 0.2, 1)


func _pedir_slot(idx: int):
	var bm = get_node_or_null("../ButtonManager")
	if bm != null and bm.has_method("select_slot"):
		bm.select_slot(idx)
	else:
		destacar_habilidade(idx)


func _on_ataque():
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("try_stamp_attack"):
		player.try_stamp_attack()


func _on_invocacao():
	var summon = get_node_or_null("../SummonSystem")
	if summon != null and summon.has_method("alternar_modo_invocacao"):
		summon.alternar_modo_invocacao()


## Mensagem curta no centro da tela (ex.: "Tinta insuficiente").
func mostrar_aviso(texto: String) -> void:
	if _aviso_label == null:
		return
	_aviso_label.text = texto
	_aviso_label.modulate.a = 1.0
	_aviso_label.visible = true
	if _aviso_tween != null and _aviso_tween.is_valid():
		_aviso_tween.kill()
	_aviso_tween = create_tween()
	_aviso_tween.tween_interval(1.0)
	_aviso_tween.tween_property(_aviso_label, "modulate:a", 0.0, 0.5)


func _criar_aviso() -> void:
	_aviso_label = Label.new()
	_aviso_label.visible = false
	_aviso_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aviso_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_aviso_label.offset_top = 140
	_aviso_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_aviso_label.add_theme_font_override("font", preload("res://utilitarios/EagleLake-Regular.ttf"))
	_aviso_label.add_theme_font_size_override("font_size", 32)
	_aviso_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_aviso_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_aviso_label.add_theme_constant_override("outline_size", 8)
	add_child(_aviso_label)


# não fale nada sobre isso
func _posicionar_hud():
	var escala = 0.7
	var viewport = get_viewport().get_visible_rect().size
	
	var centro = $HUDRoot/CentroSection
	var vida   = $HUDRoot/VidaSection
	var mana   = $HUDRoot/ManaSection
	
	# Posições originais
	var pos_centro = Vector2(440, 742)
	var pos_vida   = Vector2(467, 596)
	var pos_mana   = Vector2(1331, 678)
	
	# Tamanhos originais
	var tam_centro = Vector2(1100, 300)
	var _tam_vida   = Vector2(164, 438)
	var _tam_mana   = Vector2(202, 338)
	var centro_hud_x = pos_centro.x + tam_centro.x / 2
	var offset_x = (viewport.x / 2) - (centro_hud_x * escala)
	var offset_y = viewport.y - (1080 * escala)
	
	centro.scale    = Vector2(escala, escala)
	centro.position = Vector2(pos_centro.x * escala + offset_x, pos_centro.y * escala + offset_y)
	vida.scale      = Vector2(escala, escala)
	vida.position   = Vector2(pos_vida.x * escala + offset_x, pos_vida.y * escala + offset_y)
	mana.scale      = Vector2(escala, escala)
	mana.position   = Vector2(pos_mana.x * escala + offset_x, pos_mana.y * escala + offset_y)
