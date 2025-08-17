extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var damage_area: Area2D = $DamageArea
@export var character_texture: Texture2D
@export var weapon_texture: Texture2D

var move_speed: float = 50
var launch_force_min: float = 10
var launch_force_max: float = 18
var launch_force: float = launch_force_min
var launch_force_buildup_rate: float = 0.2

var can_aim: bool = true
var is_aiming: bool = false
var is_weapon: bool = false
var just_launched: bool = false

var can_move: bool = true

var motion: Vector2 = Vector2.ZERO
var move_motion: Vector2 = Vector2.ZERO

var deaccel: float = 1.3

var shift_reset_time: float = 2.1
var _shift_timer: float = 0


func _ready() -> void:
	sprite.texture = character_texture


func _process(delta: float) -> void:
	is_aiming = Input.is_action_pressed("mouse2") and can_aim and !just_launched
	sprite.texture = weapon_texture if is_aiming or is_weapon else character_texture
	can_move = !is_aiming and !just_launched

	if not is_weapon:
		rotation = 0

	if is_aiming:
		move_motion = Vector2.ZERO
		rotation += get_angle_to(get_global_mouse_position()) + deg_to_rad(90)
		launch_force = move_toward(launch_force, launch_force_max, launch_force_buildup_rate)
		if Input.is_action_just_pressed("mouse1"):
			is_weapon = true
			just_launched = true
			can_aim = false
			_shift_timer = 0
			motion = (get_global_mouse_position() - global_position).normalized() * launch_force
	else:
		launch_force = launch_force_min

	if !can_aim and !is_weapon:
		_shift_timer += delta
		if _shift_timer >= shift_reset_time:
			can_aim = true

	if just_launched:
		move_motion = Vector2.ZERO
		motion = motion.move_toward(Vector2.ZERO, deaccel)
		if motion.is_equal_approx(Vector2.ZERO):
			just_launched = false
			is_weapon = false
			launch_force = launch_force_min
		move_and_collide(motion)
		return

	if can_move:
		move_motion = Vector2(Input.get_axis("a", "d"), Input.get_axis("w", "s")).normalized() * move_speed
		if move_motion.x > 0:
			sprite.flip_h = false
		elif move_motion.x < 0:
			sprite.flip_h = true

	velocity = move_motion
	move_and_slide()


func take_damage(attacker: Enemy) -> void:
	pass


func deal_damage(target: Enemy) -> void:
	pass


func _on_damage_area_entered(area: Area2D) -> void:
	if area is not Enemy:
		return

	if is_weapon:
		deal_damage(area)
	else:
		take_damage(area)
