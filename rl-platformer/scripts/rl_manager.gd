extends Node

var client := StreamPeerTCP.new()
var buffer := ""
var connected := false

# store action until physics step
var pending_action = null

# used to prevent jump spam
var last_action = -1
var last_action_time := 0.0
var last_send_time := 0.0
var last_recv_time := 0.0

@onready var gm = get_node("../game manager")

func _ready():
	print("RL Manager is ready")
	client.connect_to_host("127.0.0.1", 9999)
	print("Connecting to Python...")

func _physics_process(_delta):
	client.poll()
	
	# wait until connected
	if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	
	if not connected:
		connected = true
		print("Python connected!")
	
	# read incoming data
	var available = client.get_available_bytes()
	if available > 0:
		last_recv_time = Time.get_ticks_msec()
		buffer += client.get_string(available)
	
	# parse messages
	while "\n" in buffer or (buffer.begins_with("{") and buffer.ends_with("}")):
		var end_idx = buffer.find("\n")
		var msg_str: String
		
		if end_idx == -1:
			msg_str = buffer
			buffer = ""
		else:
			msg_str = buffer.substr(0, end_idx)
			buffer = buffer.substr(end_idx + 1)
			
		if msg_str.length() > 0:
			var msg = JSON.parse_string(msg_str)
			if msg != null:
				_handle_message(msg)

	# action queued after physics
	if pending_action != null:
		var wait_time = Time.get_ticks_msec() - last_action_time
		#if wait_time > 100:  # more than 100ms gap
			#print("Long action delay: ", wait_time, "ms | last recv: ", Time.get_ticks_msec() - last_recv_time, "ms ago")
		_apply_action(pending_action)
		pending_action = null
		last_send_time = Time.get_ticks_msec()
		send_state(gm.get_state(), gm.get_reward(), gm.is_done())
		last_action_time = Time.get_ticks_msec()
		
func _handle_message(msg):	
	get_tree().paused = false
	if msg.has("command") and msg["command"] == "reset":
		gm.reset_episode()
		send_state(gm.get_state(), gm.get_reward(), gm.is_done())
	elif msg.has("action"):
		# queues action for physics step
		pending_action = int(msg["action"])


func _apply_action(action):
	match action:
		0: # left
			Input.action_press("move_left")
			Input.action_release("move_right")
			Input.action_release("jump")

		1: # right
			Input.action_press("move_right")
			Input.action_release("move_left")
			Input.action_release("jump")

		2: # jump
			Input.action_release("move_left")
			Input.action_release("move_right")
			Input.action_press("jump")

		3: # idle
			Input.action_release("move_left")
			Input.action_release("move_right")
			Input.action_release("jump")

		4: # jump + left
			Input.action_press("move_left")
			Input.action_release("move_right")
			if last_action != 4:
				Input.action_press("jump")

		5: # jump + right
			Input.action_press("move_right")
			Input.action_release("move_left")
			if last_action != 5:
				Input.action_press("jump")
			
	if action not in [2, 4, 5]:
		Input.action_release("jump")
	last_action = action


func send_state(state: Array, reward: float, done: bool):
	var msg = JSON.stringify({
		"state": state,
		"reward": reward,
		"done": done
	}) + "\n"
	client.put_data(msg.to_utf8_buffer())
