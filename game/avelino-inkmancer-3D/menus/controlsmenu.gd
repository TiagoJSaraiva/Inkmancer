extends Control

var modo_ingame := false

const ACTIONS = {
	"walk_front": "Mover Cima",
	"walk_back":  "Mover Baixo",
	"walk_left":  "Mover Esquerda",
	"walk_right": "Mover Direita",
	"summon":     "Invocar (2 cliques)",
	"slot_0":     "Carimbo 1",
	"slot_1":     "Carimbo 2",
	"slot_2":     "Carimbo 3",
	"slot_3":     "Carimbo 4",
	"pause":      "Pausar",
}

@onready var grid       = $Pergaminho/GridControles
@onready var btn_voltar = $Pergaminho/BtnVoltar

@onready var pergaminho = $Pergaminho

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_voltar.pressed.connect(_on_voltar)
	_preencher_controles()
	if modo_ingame:
		call_deferred("_centralizar_menu")


func _preencher_controles():
	for action in ACTIONS.keys():
		var label_acao = Label.new()
		label_acao.text = ACTIONS[action]
		_estilizar_label(label_acao)
		grid.add_child(label_acao)

		var label_tecla = Label.new()
		label_tecla.text = _get_key_name(action)
		_estilizar_label(label_tecla)
		grid.add_child(label_tecla)


func _estilizar_label(label: Label):
	# Cor do texto
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	
	# Tamanho da fonte
	label.add_theme_font_size_override("font_size", 21)
	
	var fonte = preload("res://utilitarios/EagleLake-Regular.ttf")
	label.add_theme_font_override("font", fonte)


func _get_key_name(action: String) -> String:
	if not InputMap.has_action(action):
		return "Não definido"
	var events = InputMap.action_get_events(action)
	if events.is_empty():
		return "Não definido"
	
	for event in events:
		if event is InputEventKey:
			return event.as_text().replace(" (Physical)", "")
		if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_LEFT:   return "Click Esquerdo"
				MOUSE_BUTTON_RIGHT:  return "Click Direito"
		if event is InputEventJoypadButton:
			return "Botão " + str(event.button_index)
	
	return "Não definido"


func _on_voltar():
	queue_free()


func _input(event):
	if event.is_action_pressed("ui_cancel") and modo_ingame:
		get_viewport().set_input_as_handled()
		queue_free()

func _centralizar_menu():
	await get_tree().process_frame
	pergaminho.scale = Vector2(0.5, 0.5)
	pergaminho.set_anchors_preset(Control.PRESET_CENTER)
	
	var metade = (pergaminho.size * pergaminho.scale) / 2
	pergaminho.offset_left   = -metade.x
	pergaminho.offset_top    = -metade.y
	pergaminho.offset_right  =  metade.x
	pergaminho.offset_bottom =  metade.y
	pergaminho.pivot_offset  = pergaminho.size / 2
