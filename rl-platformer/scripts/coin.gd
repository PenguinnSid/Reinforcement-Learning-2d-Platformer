extends Area2D

@onready var game_manager: Node = %"game manager"
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	set_deferred("monitoring", false)
	print("Collected Coin:",name)
	game_manager.add_point()
	animation_player.play("pickup")
	
func  reset_coin():
	animation_player.stop()
	animation_player.play("RESET")
	set_deferred("monitoring", true)
