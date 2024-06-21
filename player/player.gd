class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var speed: float = 3
@export_category("Sword")
@export var sword_damage: int = 2
@export_category("Ritual")
@export var ritual_damage: int = 1
@export var ritual_interval: float = 30
@export var ritual_scene: PackedScene
@export_category("Life")
@export var health: int = 20
@export var max_health: int = 20
@export var death_prefab: PackedScene
@export_category("Sounds")
@export var sword_sounds_sfx: Array[AudioStreamPlayer]


@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar
@onready var ritual_progress_bar: TextureProgressBar = $RitualProgressBar
@onready var sprite_2d: Sprite2D = $Sprite2D




var input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var was_running: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var ritual_cooldown: float = 15.0
var critical_chance: float = 0.1
var critical_damage: float = 2.0

signal meat_collected(value:int)

func _ready():
	GameManager.player = self
	meat_collected.connect(func(value: int): GameManager.meat_counter += 1)

func _process(delta):
	GameManager.player_position = position	
	
	#Ler Inputs
	read_input()
	
	#Atualizar Cooldown do Ataque
	update_attack_cooldown(delta)
	
	#Ataque
	if Input.is_action_just_pressed("attack"):
		attack()
	
	#Processar animação e rotaçaõ de sprite
	play_run_idle_animation()
	if not is_attacking:
		rotate_sprite()
	

	
	#Ritual
	update_ritual_cooldown(delta)
		
	#Atualizar textureProgressBar
	ritual_progress_bar.max_value = ritual_interval
	ritual_progress_bar.value = ritual_cooldown
	
	#Processar Dano
	update_hitbox_detection(delta)
	
	#Atualizar Health Bar
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health
	


func _physics_process(delta):
	#Modificar a velocidade
	var target_velocity = input_vector * speed * 100.0
	if is_attacking:
		target_velocity *= 0.25
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide()

func read_input():
	#Obter um input vector
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Apagar deadezone do inpit vector
	var deadzone = 0.15
	if abs(input_vector.x) < 0.15:
		input_vector.x = 0.0
	if abs(input_vector.y) < 0.15:
		input_vector.y = 0.0
		
	# Atualizar o is_running
	was_running = is_running
	is_running = not input_vector.is_zero_approx()

func play_run_idle_animation():
	# Tocar animação
	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")

func rotate_sprite():
	# Girar Sprite
	if  input_vector.x > 0:
		sprite.flip_h = false
		#desmarcar flip_h do Sprite2D
	elif input_vector.x < 0:
		sprite.flip_h = true

func update_attack_cooldown(delta):
		#Atualizar temporizador do ataque
	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")

func update_ritual_cooldown(delta: float) -> void:
	#atualizar o cooldown
	ritual_cooldown -= delta
	if ritual_cooldown > 0: return
	
	#resetar temporizador
	ritual_cooldown = ritual_interval
	
	#criar ritual
	var ritual = ritual_scene.instantiate()
	ritual.damage_amount = ritual_damage
	add_child(ritual)


func attack():
	if is_attacking:
		return
		
		
	#Tocar animação
	animation_player.play("attack_side1")
	

	
	#configurar temporizador
	attack_cooldown = 0.6
	
	#Marcar ataque
	is_attacking = true
	
	
func deal_damage_to_enemies():
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			
			var direction_to_enemy = (enemy.position - position).normalized()
			var attack_direction: Vector2
			if sprite.flip_h:
				attack_direction = Vector2.LEFT
			else:
				attack_direction = Vector2.RIGHT
			var dot_product = direction_to_enemy.dot(attack_direction)
			
			if dot_product >= 0.4:
				var calculated_damage = calculate_damage(sword_damage)
				if calculated_damage <= sword_damage:
					enemy.damage(calculated_damage, false)
				else:
					enemy.damage(calculated_damage, true)
	
func update_hitbox_detection(delta):
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0: return
	
	hitbox_cooldown = 0.5
	
	#detectar inimigos
	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var damage_amount = 1
			damage(damage_amount)
	
func damage(amount: int):
	if health <= 0: return
	
	health -= amount
	print("Player dano ", amount, "vida é ", health, "/", max_health)
	
	# Piscar node
	sprite_2d.modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(sprite_2d, "modulate", Color.WHITE, 0.3)
	
	
	#Processar Morte
	if health <= 0:
		die()
		
func die():
	GameManager.end_game()
	
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
		
	queue_free()
	
	
func heal(amount: int) -> int:
	health += amount
	if health > max_health:
		health = max_health
	print("Player curou ", amount, " vida atual ", health, "/", max_health)
	
	
	# Piscar node
	modulate = Color.LIME_GREEN
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	return health
	

func calculate_damage(damage: int) -> int:
	if randf() <= critical_chance:
		damage *= critical_damage
		return(damage)
	else:
		return(damage)
	

	
func play_attack_sound():
	#Tocar som
	var sound_selected = sword_sounds_sfx.pick_random()
	sound_selected.play()
