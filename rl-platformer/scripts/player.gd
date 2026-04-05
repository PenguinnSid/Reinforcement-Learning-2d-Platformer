extends CharacterBody2D

const SPEED = 140.0
const JUMP_VELOCITY = -250.0
var spawn_timer := 0.0
const SPAWN_GRACE = 0.5

@onready var anim = $AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var rl = get_node_or_null("../rl_manager")
@onready var gm = get_node("../game manager")

var is_dead = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	spawn_timer += delta

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")

	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if is_on_floor():
		if direction == 0:
			animated_sprite.play("default")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func die():
	if is_dead:
		return
	if spawn_timer < SPAWN_GRACE:
		return
	is_dead = true
	spawn_timer = 0.0
	velocity = Vector2.ZERO
	set_physics_process(false)
	Engine.time_scale = 0.75
	anim.play("death")
	print("Player died - ending episode")
	anim.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

func _on_death_animation_finished():
	Engine.time_scale = 1
	anim.disconnect("animation_finished", Callable(self, "_on_death_animation_finished"))
	if rl:
		gm.reset_episode()
		rl.send_state(gm.get_state(), gm.get_reward(), gm.is_done())
	else:
		get_tree().reload_current_scene()

func reset():
	is_dead = false
	spawn_timer = 0.0
	velocity = Vector2.ZERO
	set_physics_process(true)
	animated_sprite.play("default")
