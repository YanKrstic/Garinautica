extends RigidBody3D
class_name InteractableObject

# --- CONFIGURAÇÃO VISUAL ---
@export_group("Visuais")
@export var modelo_fechado: Node3D
@export var modelo_aberto: Node3D

# --- CONFIGURAÇÃO DE COLISÃO ---w
@export_group("Colisões")
@export var shapes_fechados: Array[CollisionShape3D]
@export var shapes_abertos: Array[CollisionShape3D]

# --- LOOT ---
@export_group("Loot / Itens")
@export var loot_dentro: Array[PackedScene] = []
@export var tabela_de_loot: Array[PackedScene] = []

var esta_segurado: bool = false
var ja_foi_aberto: bool = false

func _ready():
	loot_dentro = loot_dentro.duplicate()
	
	alternar_visual(false)
	
	# Configuração inicial de física
	alternar_lista_colisores(shapes_fechados, true)
	alternar_lista_colisores(shapes_abertos, false)
	
	if loot_dentro.size() == 0 and tabela_de_loot.size() > 0:
		var qtd = randi_range(1, 3)
		for i in range(qtd):
			loot_dentro.append(tabela_de_loot.pick_random())
			
	print("--- DEBUG DO OBJETO: ", name, " ---")
	print("Modelo Fechado: ", modelo_fechado)
	print("Modelo Aberto: ", modelo_aberto)
	if modelo_aberto:
		print("O modelo aberto está visível? ", modelo_aberto.visible)
		print("Posição do modelo aberto: ", modelo_aberto.global_position)

# --- LÓGICA DE FÍSICA AO PEGAR/SOLTAR ---

func ao_ser_pego():
	esta_segurado = true
	# REMOVIDO: freeze = true (Não usamos mais freeze)
	
	# TRUQUE DA CAMADA DE COLISÃO:
	# Desliga o bit 2 (Layer do Player) da máscara de colisão deste objeto.
	# Assim ele atravessa o player, mas bate nas paredes (Bit 1).
	set_collision_mask_value(2, false) 

func ao_ser_solto():
	esta_segurado = false
	# REMOVIDO: freeze = false
	
	# Liga de volta a colisão com o Player
	set_collision_mask_value(2, true)

# --- INTERAÇÃO DE ABRIR ---

func interagir_abrir():
	if ja_foi_aberto: return

	print("Abrindo objeto...")
	ja_foi_aberto = true
	alternar_visual(true)
	
	# Troca a física imediatamente (Fechado -> Aberto)
	# Como usamos física real agora, isso funciona perfeitamente segurando ou não
	alternar_lista_colisores(shapes_fechados, false)
	alternar_lista_colisores(shapes_abertos, true)
	
	spawnar_loot()

# --- AUXILIARES ---

func alternar_visual(aberto: bool):
	if modelo_fechado: modelo_fechado.visible = !aberto
	if modelo_aberto: modelo_aberto.visible = aberto

func alternar_lista_colisores(lista: Array[CollisionShape3D], ativar: bool):
	for shape in lista:
		if shape:
			shape.set_deferred("disabled", !ativar)

func spawnar_loot():
	if loot_dentro.is_empty(): return
	for item in loot_dentro:
		if item:
			var novo = item.instantiate()
			get_parent().add_child(novo)
			
			# Spawna suavemente
			var offset = Vector3(0, 0, 0.5) if esta_segurado else Vector3(0, 0.5, 0)
			novo.global_position = global_position + offset
			
			if novo is RigidBody3D:
				novo.apply_impulse(Vector3(randf_range(-0.5,0.5), 1, randf_range(-0.5,0.5)))
	loot_dentro.clear()
