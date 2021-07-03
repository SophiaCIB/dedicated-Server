extends KinematicBody

# network related
var action_log : Dictionary = {}
var last_tick : int = 0

#movement
var skip : bool = false
const GRAVITY = -40
var vel = Vector3()
const MAX_SPEED = 12
const JUMP_SPEED = 15
const ACCEL = 4.5
var dir = Vector3()
const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

# Player Stats
var health : float = 100
var dead : bool = false
var team : int


# Player Config
var MOUSE_SENSITIVITY : float = 0.05

export var camera_path : NodePath 
onready var camera = get_node(camera_path)

export var weapon_helper_path : NodePath
onready var weapon_helper : Node = get_node(weapon_helper_path)

export var rotation_helper_path : NodePath
onready var rotation_helper : Node = get_node(rotation_helper_path)

export var hud_path : NodePath
onready var hud : Node = get_node(hud_path)

#signals
signal drop_weapon



func init(player_id : int, team : int):
	self.team = team
	set_network_master(player_id)
	set_name(str(player_id))
	add_to_group("team" + str(team))
	add_to_group("hitable")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#hud.health_status_changed(health)
	#signals
	weapon_helper.connect("dropWeapon", self, "forwardDropWeapon")
	weapon_helper.connect("shoot", self, "forwardShoot")

func process_input(delta):
	# ----------------------------------
	# Walking
	dir = Vector3()
	if action_log.get("weapon_shoot"):
		weapon_helper.shoot()
		#weapon_helper.rpc_unreliable('shoot')
	if action_log.get("weapon_reload"):
		weapon_helper.weapon_reload()		
		#weapon_helper.rpc_unreliable('reload')
	if action_log.get("decrease_latest_recoil"):
		#weapon_helper.decrease_latest_recoil()
		#rpc_unreliable('weapon_helper.decrease_latest_recoil')
		pass
	if not action_log.get("rotation_rotation_degrees") == null && not action_log.get("rotation_rotation_camera_rot") == null: 
		self.rotation_degrees = action_log["rotation_rotation_degrees"]
		rotation_helper.rotation_degrees = action_log["rotation_rotation_camera_rot"]
	else:
		self.rotation_degrees = Vector3(0,0,0)
		rotation_helper.rotation_degrees = Vector3(0,0,0)
		

func process_movement(delta):
	if not action_log.get("pos") == null:
		global_transform.origin = action_log["pos"]
	else:
		global_transform.origin = Vector3(0,0,0)

func forwardDropWeapon(weapon, pos, dir):
	emit_signal("dropWeapon", weapon, pos, dir)

func forwardShoot(pos, dir):
	emit_signal("shoot", pos, dir)

func hit(damage : float) -> void:
	if multiplayer.get_rpc_sender_id() == 1:	
		health -= damage
		if health <= 0:
			dead = true
			health = 0
		print("i have been hit", health)


func spawn() -> void:
	if multiplayer.get_rpc_sender_id() == 1:
		translation = GlobalMapInformation.get_player_spawn(self)
		dead = false

sync func update_action(action : Dictionary):
	# nur neu informationen dürfen übernommen werden 
	action_log = action

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
