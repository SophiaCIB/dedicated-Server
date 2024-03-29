extends Node
var tick : int = 0
var time : float = 0
enum team {A, B}
enum side {ATTACKER, DEFENDER}
# global win conditions
var rounds_to_win : int
var tie : bool

# rounds win condiitions
var defuse : bool
var dead_enemy : bool

# live state
var team_a : Array
var team_b : Array

var side_team_a : int
var side_team_b : int

var score_team_a : int = 0
var score_team_b : int = 0

func _ready():
	set_network_master(1)

func _physics_process(delta):
	#multiplayer.poll()
	#Engine.iterations_per_second
	#tick += 1
	time += delta
	if 1/128 <= time:
		time = time - 0.0078125
		tick += 1

func getSide(player_team : int) -> int:
	match player_team:
		team.A: return side_team_a
		team.B: return side_team_b
	return -1

func reset_tick():
	tick = 0

func get_team(player_team : int) -> Array:
	match player_team:
		team.A: return team_a
		team.B: return team_b
	return []

func changed() -> void:
	team_a = get_tree().get_nodes_in_group("team0")
	team_b = get_tree().get_nodes_in_group("team1")

func team_a_is_alive() -> bool:
	if team_a.size() > 0:
		for player in team_a:
			if not player.dead:
				return true
		return false
	else:
		return true

func team_b_is_alive() -> bool:
	if team_b.size() > 0:
		for player in team_b:
			if not player.dead:
				return true
		return false
	else:
		return true
		
	
