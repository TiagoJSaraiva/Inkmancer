class_name UiUtil
extends RefCounted

## Camada usada por todos os menus de tela cheia (pausa, morte, vitória,
## gravura de carimbo). Fica acima da HUD (1) e do timer (90).
const MENU_LAYER: int = 100


## Adiciona um menu numa CanvasLayer acima da HUD. A camada é criada dentro da
## cena atual, então some sozinha quando a cena troca.
static func show_menu(tree: SceneTree, menu: Node) -> void:
	var layer := tree.get_first_node_in_group("menu_layer")
	if layer == null:
		var canvas := CanvasLayer.new()
		canvas.name = "MenuLayer"
		canvas.layer = MENU_LAYER
		canvas.process_mode = Node.PROCESS_MODE_ALWAYS
		canvas.add_to_group("menu_layer")
		var host: Node = tree.current_scene if tree.current_scene != null else tree.root
		host.add_child(canvas)
		layer = canvas
	layer.add_child(menu)
