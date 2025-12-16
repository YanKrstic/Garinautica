extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ARREMESSO_FORCA = 8.0 
const EMPURRAO_FORCA = 2.0 

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var joint: Generic6DOFJoint3D
var hand_body: StaticBody3D 
var hold_relative_transform: Transform3D 

@onready var camera = $CameraHolder/Camera3D
@onready var raycast = $CameraHolder/Camera3D/RayCast3D

var objeto_na_mao: InteractableObject = null

# --- NOVO: Variável para lembrar o que estávamos olhando antes ---
var ultimo_objeto_focado: InteractableObject = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hand_body = StaticBody3D.new()
	hand_body.top_level = true 
	hand_body.collision_layer = 0
	hand_body.collision_mask = 0
	add_child(hand_body)
	joint = Generic6DOFJoint3D.new()
	add_child(joint)
	_configurar_joint_travado()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(event.relative.x * -0.11))
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("mouse_left"): 
		if objeto_na_mao: soltar_objeto(0.0)
		else: tentar_pegar_objeto()
	if event.is_action_pressed("mouse_right"): 
		if objeto_na_mao: soltar_objeto(ARREMESSO_FORCA)
	if event.is_action_pressed("interact"): 
		if objeto_na_mao: 
			if objeto_na_mao.has_method("interagir_abrir"): objeto_na_mao.interagir_abrir()
		elif raycast.is_colliding():
			var corpo = raycast.get_collider()
			if corpo.has_method("interagir_abrir"): corpo.interagir_abrir()

func _physics_process(delta):
	# ... (Código de movimento e gravidade continua igual) ...
	if not is_on_floor(): velocity.y -= gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): velocity.y = JUMP_VELOCITY
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	
	# Empurrar objetos (igual antes)
	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var corpo = colisao.get_collider()
		if corpo is RigidBody3D and corpo != objeto_na_mao:
			corpo.apply_central_impulse(-colisao.get_normal() * EMPURRAO_FORCA)

	# Atualizar Mão
	if objeto_na_mao:
		hand_body.global_transform = camera.global_transform * hold_relative_transform

	# --- NOVO: LÓGICA DE SILHUETA (HOVER) ---
	_processar_silhueta()

func _processar_silhueta():
	# 1. Verifica o que o Raycast está olhando
	var objeto_atual: InteractableObject = null
	
	if raycast.is_colliding():
		var colisor = raycast.get_collider()
		if colisor is InteractableObject:
			objeto_atual = colisor
	
	# 2. Se mudou de objeto (ou parou de olhar), desliga o antigo
	if ultimo_objeto_focado and ultimo_objeto_focado != objeto_atual:
		ultimo_objeto_focado.set_focado(false)
	
	# 3. Se tem um objeto novo, liga ele
	if objeto_atual and objeto_atual != ultimo_objeto_focado:
		objeto_atual.set_focado(true)
		
	# Atualiza a referência
	ultimo_objeto_focado = objeto_atual

# ... (Funções tentar_pegar_objeto, soltar_objeto e _configurar_joint continuam iguais) ...
func tentar_pegar_objeto():
	if raycast.is_colliding():
		var corpo = raycast.get_collider()
		if corpo is InteractableObject:
			objeto_na_mao = corpo
			add_collision_exception_with(objeto_na_mao)
			hold_relative_transform = camera.global_transform.affine_inverse() * objeto_na_mao.global_transform
			hand_body.global_transform = objeto_na_mao.global_transform
			joint.node_a = hand_body.get_path()
			joint.node_b = objeto_na_mao.get_path()
			objeto_na_mao.ao_ser_pego() # Isso já vai atualizar a silhueta pra ficar grossa

func soltar_objeto(forca: float):
	if objeto_na_mao:
		remove_collision_exception_with(objeto_na_mao)
		joint.node_a = NodePath("")
		joint.node_b = NodePath("")
		objeto_na_mao.ao_ser_solto() # Isso já vai tirar a silhueta grossa
		if forca > 0:
			var direcao = -camera.global_transform.basis.z
			objeto_na_mao.apply_central_impulse(direcao * forca)
		objeto_na_mao = null
func _configurar_joint_travado():
	# Eixo X
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	
	# Eixo Y
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	
	# Eixo Z
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	
	# Angular
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)

	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
