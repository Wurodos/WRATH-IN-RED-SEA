extends Node


var map
var map_node
const Region = preload("res://scripts/map.gd").Region
const Country = preload("res://scripts/map.gd").Country

class MapFilter:
	var region = Region.ALL
	var need_control_ussr = false
	var need_control_usa = false
	var need_presence_ussr = false
	var need_presence_usa = false
	var need_battleground = false
	var ban = Array()
	var allow = Array()
	var reverse = false
	var adjacent = false
	var in_famine = false
	
	
	func pass_the_filter(country : Country) -> bool:
		# Non-reversible
		for id : int in ban:
			if id == country.id:
				return false
		#Non-reversible
		for id : int in allow:
			if id == country.id:
				return true
		
		if not allow.is_empty():
			return false
		if region != Region.ALL and country.region != region and country.region != Region.EGY:
			return reverse
		if need_control_ussr and country.inf_soviet < country.inf_usa + country.stability:
			return reverse
		if need_control_usa and country.inf_usa < country.inf_soviet + country.stability:
			return reverse
		if need_presence_ussr and country.inf_soviet <= 0:
			return reverse
		if need_presence_usa and country.inf_usa <= 0:
			return reverse
		if need_battleground and not country.battleground:
			return reverse
		if in_famine and not country.famine:
			return reverse
		return !reverse

var game

func _ready() -> void:
	map = $Node.map
	map_node = $Node
	game = get_parent()

var die_faces : Array

@rpc("authority", "call_local")
func setup():
	for i in range($Countries.get_child_count()):
		$Countries.get_child(i).held = map[i]
	for i in range(1, 7, 1):
		die_faces.append(load("res://sprite/dice/" + str(i) + ".png"))
	set_inf_soviet(4, 1)
	set_inf_soviet(8, 1)
	set_inf_usa(2, 1)
	set_inf_usa(7, 1)

@rpc("any_peer", "call_local")
func set_inf_soviet(id, inf, delta = false):
	print($Countries.get_child(id).name)
	$Countries.get_child(id).set_inf_soviet(inf, delta)

@rpc("any_peer", "call_local")
func set_inf_usa(id, inf, delta = false):
	print($Countries.get_child(id).name)
	$Countries.get_child(id).set_inf_usa(inf, delta)

func disable_countries():
	for country : Node in $Countries.get_children():
		country.unmake_pressable()
		for dict in country.chosen.get_connections():
			country.chosen.disconnect(dict.callable)
	

@rpc("any_peer", "call_remote")
func info_picking_country():
	$Info.text = "Противник выбирает страну..."

func enable_eligible(eligible : Array, effect: Callable):
	print("enabling countries...")
	var any_target = false
	info_picking_country.rpc()
	for i in eligible:
		var country = $Countries.get_child(i)
		country.make_pressable()
		if not country.chosen.is_connected(effect):
			country.chosen.connect(effect)
		any_target = true
	if not any_target:
		effect.call(-1)

func enable_countries(map_filter : MapFilter, effect: Callable):
	print("enabling countries...")
	var any_target = false
	info_picking_country.rpc()
	for country : Node in $Countries.get_children():
		if map_filter.pass_the_filter(country.held):
			country.make_pressable()
			country.chosen.connect(effect)
			any_target = true
	if not any_target:
		effect.call(-1)

# All countries adjacent to USSR-controlled ones
func victorious_leader() -> Array:
	var eligible = Array()
	for country : Country in map:
		if country.inf_soviet >= country.inf_usa + country.stability:
			eligible.append_array(country.adjacent)
	return eligible

func score_region(region : Region) -> int:
	var usa_con = 0
	var usa_con_bat = 0
	var sov_con = 0
	var sov_con_bat = 0
	var total = 0
	for country : Country in map:
		if country.region == region or country.region == Region.EGY:
			if country.usa_control():
				usa_con += 1
				if country.battleground:
					usa_con_bat += 1
			elif country.sov_control():
				sov_con += 1
				if country.battleground:
					sov_con_bat += 1
	total += usa_con_bat - sov_con_bat
	
	# SOV === Presence
	if sov_con > 0:
		if region == Region.AFR:
			total -= 1
		elif region == Region.ME:
			total -= 3
		# Domination
		if sov_con_bat > usa_con_bat and sov_con > usa_con and sov_con > sov_con_bat:
			if region == Region.AFR:
				total -= 3
			elif region == Region.ME:
				total -= 5
		# Control
		if sov_con_bat == 2 and sov_con > usa_con:
			if region == Region.AFR:
				total -= 4
			elif region == Region.ME:
				total -= 7
	
	# USA ==== Presence
	if usa_con > 0:
		if region == Region.AFR:
			total += 1
		elif region == Region.ME:
			total += 3
		# Domination
		if sov_con_bat < usa_con_bat and sov_con < usa_con and usa_con > usa_con_bat:
			if region == Region.AFR:
				total += 3
			elif region == Region.ME:
				total += 5
		# Control
		if usa_con_bat == 2 and sov_con < usa_con:
			if region == Region.AFR:
				total += 4
			elif region == Region.ME:
				total += 7
	
	return total

# Make ethiopia 3 stab
@rpc("any_peer", "call_local")
func derg():
	map[2].stability = 3

var last_roll = 0

@rpc("any_peer", "call_local")
func place_famine(id : int):
	$Countries.get_child(id).add_famine()

@rpc("any_peer", "call_local")
func remove_famine(id : int):
	$Countries.get_child(id).remove_famine()

@rpc("any_peer", "call_local")
func roll_d6(die_id : int) -> void:
	#Dice roll animation
	last_roll = randi_range(1, 6)
	if die_id == 0:
		$USAd6.texture = die_faces[last_roll-1]
	elif die_id == 1:
		$SOVd6.texture = die_faces[last_roll-1]
