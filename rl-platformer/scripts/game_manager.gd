extends Node
@onready var player: CharacterBody2D = $"../player"
@onready var rl = get_node("../rl_manager")

var score = 0
var prev_score = 0
var initial_player_pos: Vector2
var visited_x := {} #	visited zones
var explore_size := 50 #	new zone every 50 pixels
var prev_player_x: float = 0.0
var prev_dist: float = 0.0
var max_x_reached := 0.0
func _ready():
	player = get_node("../player")
	await get_tree().process_frame
	initial_player_pos = player.position
		
func add_point():
	score += 1

func reset_episode():
	max_x_reached = initial_player_pos.x
	visited_x.clear()
	prev_player_x = initial_player_pos.x
	score = 0
	prev_score = 0
	player.reset()
	player.position = initial_player_pos
	player.velocity = Vector2.ZERO
	var coin = get_nearest_coin()
	if coin != null:
		prev_dist = player.position.distance_to(coin.position)
	else:
		prev_dist = 0.0

	for platform in get_node("../platforms").get_children():
		var anim = platform.get_node_or_null("AnimationPlayer")
		if anim:
			anim.stop()
			anim.seek(0)
			anim.play()

	for c in get_node("../coins").get_children():
		c.reset_coin()
		
	var slime = get_node("../slime")
	slime.position = slime.initial_position
	slime.direction = 1
	
func get_nearest_coin():
	var coins = get_node("../coins").get_children()
	if coins.size() == 0:
		return null
	var nearest = null
	var min_dist = INF
	for coin in coins:
		if not coin.visible:  # skip collected coins
			continue
		var d = player.position.distance_to(coin.position)
		if d < min_dist:
			min_dist = d
			nearest = coin
	return nearest
	
func get_state() -> Array:
	var coin = get_nearest_coin()
	var coin_dx = 0
	var coin_dy = 0
	if coin != null:
		coin_dx = coin.position.x - player.position.x
		coin_dy = coin.position.y - player.position.y
	return [
		player.position.x/1000,
		player.position.y/1000,
		player.velocity.x/1000,
		player.velocity.y/1000,
		coin_dx/1000,
		coin_dy/1000
	]

func get_reward() -> float:
	var reward := 0.0
	var delta_x = player.position.x - prev_player_x
	prev_player_x = player.position.x

	var zone = int(player.position.x / explore_size)
	var coin = get_nearest_coin()

	#const goal_x = 1025.0
	#var goal_dist = goal_x - player.position.x
	#reward -= (goal_dist / goal_x) * 0.01
	# reward for going towards the goal
	#reward += (1.0 - goal_dist / goal_x) * 0.02

	# progress reward
	if player.position.x > max_x_reached:
		reward += (player.position.x - max_x_reached) * 0.05
		max_x_reached = player.position.x

	# penalty for going back
	if player.position.x < max_x_reached - 50:
		reward -= 0.05

	# jump penalty
	if rl.last_action in [2, 4, 5]:
		reward -= 0.02
	#if rl.last_action in [0,1]:
		#reward += 0.01

	# useless jumps penalty
	if abs(player.velocity.y) > 50 and abs(delta_x) < 1:
		reward -= 0.02

	# coin rewards
	if coin != null:
		var dist = player.position.distance_to(coin.position)
		var delta = prev_dist - dist
		if is_finite(delta):
			reward += max(delta, 0) * 0.02
		prev_dist = dist

	# exploration bonus for new zones
	if not visited_x.has(zone):
		visited_x[zone] = true
		reward += 0.5

	# jitter penalty
	#if sign(player.velocity.x) != sign(delta_x) and abs(delta_x) > 1:
	if abs(delta_x) < 1 and abs(player.velocity.x) > 10:
		reward -= 0.02

	# coin collection
	if score > prev_score:
		var new_coin = get_nearest_coin()
		if new_coin != null:
			prev_dist = player.position.distance_to(new_coin.position)
	reward += 10 * (score - prev_score)
	prev_score = score

	# death and goal
	if _in_deadzone():
		reward -= 60.0
	if _reached_goal():
		reward += 200.0

	# time penalty
	reward -= 0.1

	return reward

func is_done() -> bool:
	return _in_deadzone() or _reached_goal()

func _in_deadzone() -> bool:
	return get_node("../deadzone").overlaps_body(player)

func _reached_goal() -> bool:
	if player.position.x > 1025.0:
		print("Reached Goal!!")
	return player.position.x > 1025.0

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):  # spacebar
		print("Player pos: ", player.position)
