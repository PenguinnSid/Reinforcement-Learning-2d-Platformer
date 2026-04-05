extends Node2D

const speed = 0
var direction = 1
var initial_position: Vector2  # added for RL reset

@onready var raycast_right: RayCast2D = $raycast_right
@onready var raycast_left: RayCast2D = $raycast_left
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	initial_position = position  # store spawn position

func _process(delta: float) -> void:
	if raycast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if raycast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false  # also fixed this, was true in both cases
	position.x += direction * speed * delta

func _on_deadzone_body_entered(body: Node2D) -> void:
	body.die()
