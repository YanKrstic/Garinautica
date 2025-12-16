extends RigidBody3D
class_name InteractableObject

@export_group("Configurações")
@export var pode_ser_aberto: bool = true 

@export_group("Visuais")
@export var modelo_fechado: Node3D
@export var modelo_aberto: Node3D

@export_group("Colisões")
@export var shapes_fechados: Array[CollisionShape3D]
@export var shapes_abertos: Array[CollisionShape3D]

@export_group("Loot / Itens")
@export var loot_dentro: Array[PackedScene] = []
@export var tabela_de_loot: Array[PackedScene] = []

# VARIÁVEIS DE ESTADO
var esta_segurado: bool = false
var ja_foi_aberto: bool = false
var esta_focado: bool = false
var material_outline: StandardMaterial3D

func _ready():
	# Configuração do Outline
	material_outline = StandardMaterial3D.new()
	material_outline.cull_mode = BaseMaterial3D.CULL_FRONT 
	material_outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED 
	material_outline.albedo_color = Color.WHITE 
	material_outline.grow = true 
	
	loot_dentro = loot_dentro.duplicate()
	
	alternar_visual(false)
	alternar_lista_colisores(shapes_fechados, true)
	alternar_lista_colisores(shapes_abertos, false)
	
	if loot_dentro.size() == 0 and tabela_de_loot.size() > 0:
		var qtd = randi_range(1, 3)
		for i in range(qtd):
			loot_dentro.append(tabela_de_loot.pick_random())

# --- FUNÇÕES DE INTERAÇÃO ---

func interagir_abrir():
	# TRAVA DE SEGURANÇA:
	# Se o objeto não foi feito para abrir (ex: latinha, bola),
	# paramos aqui. Assim a física não quebra.
	if not pode_ser_aberto:
		return

	if ja_foi_aberto: return
	
	print("Abrindo objeto...")
	ja_foi_aberto = true
	
	alternar_visual(true)
	alternar_lista_colisores(shapes_fechados, false)
	alternar_lista_colisores(shapes_abertos, true)
	spawnar_loot()
	
	atualizar_outline()

# --- FUNÇÕES DE CONTROLE VISUAL ---

func set_focado(estado: bool):
	esta_focado = estado
	atualizar_outline()

func ao_ser_pego():
	esta_segurado = true
	atualizar_outline()

func ao_ser_solto():
	esta_segurado = false
	atualizar_outline()

func atualizar_outline():
	if esta_segurado:
		material_outline.grow_amount = 0.05 
		material_outline.albedo_color = Color(1, 1, 0.5) 
	elif esta_focado:
		material_outline.grow_amount = 0.02 
		material_outline.albedo_color = Color.WHITE
	else:
		material_outline.grow_amount = 0.0 
	
	var modelo_atual = modelo_aberto if ja_foi_aberto else modelo_fechado
	aplicar_overlay_no_modelo(modelo_atual, material_outline if (esta_focado or esta_segurado) else null)

func aplicar_overlay_no_modelo(no_pai: Node, material: Material):
	if not no_pai: return
	if no_pai is MeshInstance3D:
		no_pai.material_overlay = material
	for filho in no_pai.get_children():
		aplicar_overlay_no_modelo(filho, material)

# --- AUXILIARES ---

func alternar_visual(aberto: bool):
	if modelo_fechado: modelo_fechado.visible = !aberto
	if modelo_aberto: modelo_aberto.visible = aberto

func alternar_lista_colisores(lista: Array[CollisionShape3D], ativar: bool):
	for shape in lista:
		if shape: shape.set_deferred("disabled", !ativar)

func spawnar_loot():
	if loot_dentro.is_empty(): return
	for item in loot_dentro:
		if item:
			var novo = item.instantiate()
			get_parent().add_child(novo)
			var offset = Vector3(0, 0, 1.0) if esta_segurado else Vector3(0, 0.5, 0)
			novo.global_position = global_position + offset
			if novo is RigidBody3D:
				novo.apply_impulse(Vector3(randf_range(-1,1), 2, randf_range(-1,1)))
	loot_dentro.clear()
