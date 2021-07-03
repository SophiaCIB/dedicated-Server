extends Node
var ping : Dictionary = {}
# ping = {
# 	player_id: {
# 		'ping': 0,
# 		'start': 0,
# 		'recieved': false
#		'ten_last_pings': []
#		'average_ping': float
# 	}
# }
var tick_offset : int = 25
var action_log : Dictionary = {}

# structure of action_log
# action_log = {
# 	tickid: {
# 		weapon_drop_pos: Vector2,
# 		weapon_drop_dir: Vector2,
# 		pos: Vector3,
# 		weapon_shoot: bool,
# 		weapon_reload: bool,
# 		decrease_latest_recoil: bool,
# 		rotation_rotation_degrees: Vector3,
# 		rotation_rotation_camera_rot: Vector3,
# 		tick: int
# 	}
# }

enum argument_types {INT, FLOAT, STRING, ARRAY}

var callable_by_command : Array = [
	['start', [argument_types.INT]],
	['connect_to', [argument_types.STRING, argument_types.INT]],
	['init_game', []]
]

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	set_network_master(1)
	start(3)

# Player info, associate ID to data
var player_id : Dictionary = {}
# Info we send to other players
var my_info = { name = "Johnson Magenta", favorite_color = Color8(255, 0, 255) }

func _player_connected(id):
	# Called on both clients and server when a peer connects. Send my info to it.
	print("player connected")
	rpc_id(id, "register_player", my_info)
	#get_tree().get_root().get_node("GameStateManager").rpc('add_player', id)
	ping[id] = {
		'ping': -1,
		'start': -1,
		'recieved': true,
		'ten_last_pings': [],
		'average_ping': -1.0
	}

func _player_disconnected(id):
	player_id.erase(id)
	ping.erase(id)

func _connected_ok():
	pass

func _server_disconnected():
	pass # Server kicked us; show error and abort.

func _connected_fail():
	pass # Could not even connect to server; abort.

remote func register_player(info):
	# Get the id of the RPC sender.
	var id = get_tree().get_rpc_sender_id()
	# Store the info
	player_id[id] = {'info': info}


	# Call function to update lobby UI here

func start(max_players : int) -> String:
	var peer = NetworkedMultiplayerENet.new()
	var port : int = 28111
	peer.create_server(port, max_players)
	peer.set_target_peer(peer.TARGET_PEER_BROADCAST)
	peer.set_transfer_mode(peer.TRANSFER_MODE_UNRELIABLE)
	get_tree().network_peer = peer
	get_tree().set_multiplayer_poll_enabled(false)
	return 'server started with ' + str(max_players) + " on port " + str(port) 

func connect_to(SERVER_IP : String, SERVER_PORT : int) -> String:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	peer.set_target_peer(peer.TARGET_PEER_SERVER)
	peer.set_transfer_mode(peer.TRANSFER_MODE_UNRELIABLE)
	get_tree().network_peer = peer
	get_tree().set_multiplayer_poll_enabled(false)
	return 'connecting to server'

master func init_game() -> String:
	#if is_network_master():
	#	rpc("init_game")
	get_tree().get_root().get_node("GameStateManager").init_game()
	return "initalizing game"

# funktioniert nur für einen player gerade
func init_ping() -> void:
	if GameState.tick % 64 == 0:
		for player_name in player_id.keys():
			# für jeden spieler muss ein ping angelegt werden
			var player_ping : Dictionary = ping[player_name]
			if player_ping['recieved'] == true or GameState.tick - player_ping['start'] > 512:
				player_ping['start'] = GameState.tick
				player_ping['recieved'] = false
				rpc_unreliable_id(player_name, 'recieve_ping', player_ping['average_ping'])
				# print('sending ping to : ', player_name)
	
remote func ping_end() -> void:
	var player_name : int = multiplayer.get_rpc_sender_id()
	var player_ping : Dictionary = ping[player_name]
	var last_ping : int = GameState.tick - player_ping['start']
	player_ping['ping'] = last_ping
	player_ping['recieved'] = true
	player_ping['ten_last_pings'].push_front(last_ping)
	if player_ping['ten_last_pings'].size() > 10:
		player_ping['ten_last_pings'].remove(10)
	var average : float = 0
	for i in player_ping['ten_last_pings']:
		average += i
	player_ping['average_ping'] = average / player_ping['ten_last_pings'].size()	
	# print('ping recieved: ', player_ping, " ", player_ping['average_ping'])


remote func update_action(action : Dictionary) -> void:
	print('from ', multiplayer.get_rpc_sender_id(), ' recieved: ', action['tick'], ", mine: ", GameState.tick)
	if action['tick'] > GameState.tick - tick_offset:
		action_log[action['tick']] = {multiplayer.get_rpc_sender_id(): action}
		for player_key in action.keys():
			get_node('/root/GameStateManager/' + str(multiplayer.get_rpc_sender_id())).action_log = action

func send_current_state() -> void:
	if action_log.size() > 0 && not action_log.get(GameState.tick - tick_offset) == null:
		rpc('recieve_current_state', action_log[GameState.tick - tick_offset])

func _physics_process(delta):
	send_current_state()
	init_ping()
	get_tree().multiplayer.poll()