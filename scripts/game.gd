extends Node

enum Phase{USA, USSR, NOT_CHOSEN}
enum Sequence{
	DEFCON_IMPROVE, 
	DEAL_CARDS,
	HEADLINE,
	ACTION_ROUNDS,
	ROMANIA,
	MILITARY_OPS,
	END_TURN
}

const Card = preload("res://scripts/card.gd").Card
const Bloc = preload("res://scripts/card.gd").Bloc
const CardOption = preload("res://icon/CardOption.tscn")
const option_mode = preload("res://icon/card_option.gd").Mode
const MapFilter = preload("res://scripts/map_ui.gd").MapFilter
const card_prefab = preload("res://scripts/card.tscn")
const Romania = preload("res://scripts/card.gd").RomanianAutonomy


var bloc_to_id : Dictionary
var player_country : Phase
var vp : int # + USA, - USSR
var space_usa : int
var space_ussr : int
var mo_usa : int
var mo_ussr : int
var defcon : int
var turn : int
var round : int
var phase : Phase
var sequence : Sequence
var hand = []

var romania_card : Control
var has_romania = false
# Flags

# no 'Ogaden War'
var F56 = false
# 
var nasser = false
# every coup is -1 defcon
var indian_ocean = false
# ethiopia is 3 stab
var the_derg = false
# usa goes first in AR
var usaid = false


# Sequence:
# + DEFCON
# Headline
#

@rpc("any_peer", "call_remote")
func get_romania_facedown():
	romania_card = card_prefab.instantiate()
	romania_card.get_node("Card").apply_ui(Romania.new())
	romania_card.position = Vector2(50, 750)
	romania_card.get_node("Card").draggable = false
	romania_card.modulate = Color(0.3, 0.3, 0.3)
	has_romania = true
	add_child(romania_card)

@rpc("any_peer", "call_remote")
func get_romania():
	romania_card = card_prefab.instantiate()
	romania_card.get_node("Card").apply_ui(Romania.new())
	romania_card.position = Vector2(50, 750)
	has_romania = true
	romania_card.modulate = Color(1,1,1)
	add_child(romania_card)

@rpc("any_peer", "call_local")
func lose_romania():
	if has_romania:
		print(player_country)
		print("LOST ROMANIA ROMANIA")
		romania_card.free()
		romania_card = null
		has_romania = false
	


func _ready() -> void:
	seed(789)
	multiplayer.allow_object_decoding = true
	vp_init_pos = $Map/VP.position
	player_country = Phase.NOT_CHOSEN
	turn = 1
	round = 1
	space_usa = 0
	space_ussr = 0
	defcon = 4
	mo_usa = 0
	mo_ussr = 0
	phase = Phase.USA
	vp = 0
	sov_headline = null
	usa_headline = null
	sequence = Sequence.HEADLINE
	choose_a_country.connect($Map.enable_eligible)
	choose_with_filter.connect($Map.enable_countries)
	

@rpc("any_peer", "call_local")
func discard(id : int):
	if id < 0:
		return
	if id == 22:
		if !has_romania:
			get_romania_facedown()
		else:
			lose_romania()
		return
	var card = Card.find_in_deck(Card.card_manifest, id)
	var instance = card_prefab.instantiate()
	instance.get_node("Card").draggable = false
	instance.get_node("Card").apply_ui(card)
	$DiscardScroll/Discard.add_child(instance)
	Card.discard.append(card)
	

@rpc("any_peer", "call_local")
func change_phase():
	if phase == Phase.USA:
		phase = Phase.USSR
		$Map/Phasing.text = "Фаза:\nСССР"
	else:
		phase = Phase.USA
		$Map/Phasing.text = "Фаза:\nСША"

@rpc
func print_once_per_client():
	print("I will be printed to the console once per each connected client.")

func _on_button_pressed() -> void:
	if player_country != Phase.NOT_CHOSEN:
		change_phase.rpc()
		$Map.setup.rpc()
		$Map/Deck.setup.rpc()
		print_once_per_client.rpc()
		draw_hand()
		if player_country == Phase.USA:
			get_romania()
		else:
			get_romania.rpc()
		draw_hand.rpc()
		headline_phase.rpc()
		reset_confirmation_button.rpc()
	else:
		print("Choose a country!")
	

@rpc("any_peer", "call_local")
func reset_confirmation_button():
	for dict in $Map/Confirmation.pressed.get_connections():
		$Map/Confirmation.pressed.disconnect(dict.callable)
	$Map/Confirmation.text = "Подтвердить"
	$Map/Confirmation.disabled = true

@rpc("any_peer", "call_local")
func make_confirmation_into_proceed():
	$Map/Confirmation.text = "Перейти к этапу действий"
	$Map/Confirmation.pressed.connect(func():
		reset_confirmation_button.rpc()
		action_phase.rpc_id(1)
	)

# HEADLINE

var sov_headline : Card
var usa_headline : Card

@rpc("any_peer", "call_remote")
func opp_chosen(id : int):
	print("opponent has chosen a card!" + str(id))
	$Map/Info.text = "Противник выбрал карту!"
	var chosen = Card.find_in_deck(Card.card_manifest, id)
	if player_country == Phase.USA:
		sov_headline = chosen
	else:
		usa_headline = chosen
	if usa_headline != null and sov_headline != null:
		if sov_headline.id == 16:
			pass
		elif usa_headline.ops >= sov_headline.ops:
			$Map/Confirmation.pressed.connect(func(): 
				reset_confirmation_button.rpc()
				make_confirmation_into_proceed.rpc()
				redirect_event(sov_headline, Phase.USSR)
			)
		else:
			$Map/Confirmation.pressed.connect(func(): 
				reset_confirmation_button.rpc()
				make_confirmation_into_proceed.rpc()
				redirect_event(usa_headline, Phase.USA)
			)

func self_chosen(id : int):
	print("you have chosen a card! " + str(id))
	rpc("opp_chosen", id)
	var chosen = Card.find_in_deck(Card.card_manifest, id)
	
	hand.erase(chosen)
	$HBox.remove(chosen)
	
	print(chosen.name)
	if player_country == Phase.USA:
		usa_headline = chosen
	else:
		sov_headline = chosen
	if usa_headline != null and sov_headline != null:
		if sov_headline.id == 16:
			reset_confirmation_button.rpc()
			make_confirmation_into_proceed.rpc()
			discard.rpc(usa_headline.id)
			redirect_event(sov_headline, Phase.USSR)
		elif usa_headline.ops >= sov_headline.ops:
			phase = Phase.USA
			redirect_event(usa_headline, Phase.USA)
			$Map/Confirmation.pressed.connect(func(): 
				reset_confirmation_button.rpc()
				make_confirmation_into_proceed.rpc()
				redirect_event(sov_headline, Phase.USSR)
			)
		else:
			phase = Phase.USSR
			redirect_event(sov_headline, Phase.USSR)
			$Map/Confirmation.pressed.connect(func():
				reset_confirmation_button.rpc()
				make_confirmation_into_proceed.rpc()
				redirect_event(usa_headline, Phase.USA)
			)


func redirect_event(card: Card, playing_bloc : Phase):
	if card.bloc == Bloc.USA:
		execute_event.rpc_id(bloc_to_id[Phase.USA], card.id)
	elif card.bloc == Bloc.USSR:
		execute_event.rpc_id(bloc_to_id[Phase.USSR], card.id)
	else:
		execute_event.rpc_id(bloc_to_id[playing_bloc], card.id)


# this is disgusting and unnecessary, but it's the only way it works
@rpc("any_peer", "call_local")
func execute_event(card_id : int):
	var card = Card.find_in_deck(Card.card_manifest, card_id)
	if hand.count(card) > 0:
		hand.erase(card)
	if !card.asterisk:
		discard.rpc(card_id)
	card.event()

@rpc("authority", "call_local")
func headline_phase():
	print("USA Player: "  + str(bloc_to_id[Phase.USA]))
	print("USSR Player: " + str(bloc_to_id[Phase.USSR]))
	sequence = Sequence.HEADLINE
	var headline_option = CardOption.instantiate()
	headline_option.apply_ui(option_mode.HEADLINE)
	headline_option.headline_chosen.connect(self_chosen)
	$CardOptions.add_child(headline_option)

# ======================== ACTION ROUNDS ================================

@rpc("any_peer", "call_local")
func action_phase():
	$Map/Info.text = "Фаза действий!"
	sequence = Sequence.ACTION_ROUNDS
	# First, soviets, then (after confirmation), americans
	if usaid:
		print("usaid proc 1/3")
		play_a_card.rpc_id(bloc_to_id[Phase.USA])
		make_confirmation_redirect_to_soviets.rpc_id(bloc_to_id[Phase.USA])
	else:
		play_a_card.rpc_id(bloc_to_id[Phase.USSR])
		make_confirmation_redirect_to_us.rpc_id(bloc_to_id[Phase.USSR])

@rpc("any_peer", "call_local")
func make_confirmation_redirect_to_us():
	print("AAAAAAA")
	
	$Map/Confirmation.pressed.connect(func():
		if usaid:
			move_round.rpc()
		reset_confirmation_button.rpc()
		if round < 8:
			play_a_card.rpc_id(bloc_to_id[Phase.USA])
			make_confirmation_redirect_to_soviets.rpc_id(bloc_to_id[Phase.USA])
	)

@rpc("any_peer", "call_local")
func make_confirmation_redirect_to_soviets():
	print("usaid proc 3/3")
	$Map/Confirmation.pressed.connect(func():
		if !usaid:
			move_round.rpc()
		reset_confirmation_button.rpc()
		if round < 8:
			play_a_card.rpc_id(bloc_to_id[Phase.USSR])
			make_confirmation_redirect_to_us.rpc_id(bloc_to_id[Phase.USSR])
	)

@rpc("any_peer", "call_local")
func play_a_card(id = -1):
	if player_country == Phase.USA:
		print("usaid proc 2/3")
	sequence = Sequence.ACTION_ROUNDS
	$Map/Info.text = "Сыграйте карту"
	var place_influence_ = CardOption.instantiate()
	place_influence_.apply_ui(option_mode.PLACE_INFLUENCE)
	place_influence_.place_influence.connect(place_influence)
	$CardOptions.add_child(place_influence_)
	
	var coup_ = CardOption.instantiate()
	coup_.apply_ui(option_mode.COUP)
	coup_.coup.connect(coup)
	$CardOptions.add_child(coup_)
	
	var realignment_ = CardOption.instantiate()
	realignment_.apply_ui(option_mode.REALIGNMENT)
	realignment_.realignment.connect(realign)
	$CardOptions.add_child(realignment_)
	
	var space_ = CardOption.instantiate()
	if player_country == Phase.USA:
		if space_usa < 2: space_.min_ops = 2
		else: space_.min_ops = 3
	else:
		if space_ussr < 2: space_.min_ops = 2
		else: space_.min_ops = 3
	
	space_.apply_ui(option_mode.SPACE_RACE)
	space_.space.connect(space_race)
	$CardOptions.add_child(space_)
	
	if id == -1:
		var event_ = CardOption.instantiate()
		event_.apply_ui(option_mode.EVENT)
		event_.event.connect(event)
		$CardOptions.add_child(event_)
	
	if id != -1:
		for option in $CardOptions.get_children():
			option.enable_button()

signal choose_a_country
signal choose_with_filter
var eligible = Array()
var ops_left = 0

func clear_card_options():
	for child in $CardOptions.get_children():
		child.queue_free()

func play_opponent_event_after_resolution(chosen: Card):
	if chosen.bloc == Bloc.USSR and player_country != Phase.USSR:
		reset_confirmation_button.rpc()
		$Map/Confirmation.pressed.connect(func():
			reset_confirmation_button.rpc()
			make_confirmation_redirect_to_soviets.rpc_id(bloc_to_id[Phase.USSR])
			execute_event.rpc_id(bloc_to_id[Phase.USSR], chosen.id)
		)
	elif chosen.bloc == Bloc.USA and player_country != Phase.USA:
		reset_confirmation_button.rpc()
		$Map/Confirmation.pressed.connect(func():
			reset_confirmation_button.rpc()
			make_confirmation_redirect_to_us.rpc_id(bloc_to_id[Phase.USA])
			execute_event.rpc_id(bloc_to_id[Phase.USA], chosen.id)
		)
	else:
		hand.erase(chosen)
		discard.rpc(chosen.id)

const Blank = preload("res://scripts/card.gd").Blank

# PLACE PLACE PLACE PLACE PLACE PLACE PLAC


func place_influence(id: int):
	var chosen 
	if id < 0:
		chosen = Blank.new()
		chosen.ops = -id
	else:
		chosen = Card.find_in_deck(Card.card_manifest, id)
	
	# Play opponent event after resolution
	play_opponent_event_after_resolution(chosen)
	
	clear_card_options()
	ops_left = chosen.ops
	eligible.clear()
	if player_country == Phase.USA:
		eligible.append_array($Map/Node.placement_eligible_usa())
		if ops_left == 1:
				eligible.filter(func(id): !$Map.map[id].sov_control())
		emit_signal("choose_a_country", eligible, add_one_american)
	elif player_country == Phase.USSR:
		eligible.append_array($Map/Node.placement_eligible_soviet())
		if ops_left == 1:
				eligible.filter(func(id): !$Map.map[id].usa_control())
		emit_signal("choose_a_country", eligible, add_one_soviet)

func add_one_soviet(chosen_id: int):
	if chosen_id != -1:
		if $Map.map[chosen_id].usa_control():
			ops_left -= 2
		else:
			ops_left -= 1
		$Map.set_inf_soviet.rpc(chosen_id, 1, true)
		if ops_left <= 0:
			$Map.disable_countries()
			$Map/Confirmation.disabled = false
		else:
			if ops_left == 1:
				eligible.filter(func(id): !$Map.map[id].usa_control())
			emit_signal("choose_a_country", eligible, add_one_soviet)
	else:
		$Map.disable_countries()
		$Map/Confirmation.disabled = false

func add_one_american(chosen_id: int):
	if chosen_id != -1:
		if $Map.map[chosen_id].sov_control():
			ops_left -= 2
		else:
			ops_left -= 1
		$Map.set_inf_usa.rpc(chosen_id, 1, true)
		
		if ops_left <= 0:
			$Map.disable_countries()
			$Map/Confirmation.disabled = false
		else:
			if ops_left == 1:
				eligible.filter(func(id): !$Map.map[id].sov_control())
			emit_signal("choose_a_country", eligible, add_one_american)
	else:
		$Map.disable_countries()
		$Map/Confirmation.disabled = false

# COUP COUP COUP COUP COUP COUP COUP
# filter need_opp_inf, ME (if defcon < 4)
# choose 1, roll die

const Region = preload("res://scripts/map_ui.gd").Region

func coup(id : int):
	var chosen : Card
	if id < 0:
		chosen = Blank.new()
		chosen.ops = -id
	else:
		chosen = Card.find_in_deck(Card.card_manifest, id)
	clear_card_options()
	ops_left = chosen.ops
	eligible.clear()
	
	play_opponent_event_after_resolution(chosen)
	
	var map_filter = MapFilter.new()
	if defcon < 4:
		map_filter.region = Region.AFR
		map_filter.ban.append(0)
	map_filter.ban.append(11)
	if player_country == Phase.USA:
		map_filter.need_presence_ussr = true
		emit_signal("choose_with_filter", map_filter, usa_coup)
	elif player_country == Phase.USSR:
		map_filter.need_presence_usa = true
		emit_signal("choose_with_filter", map_filter, soviet_coup)
		
var zbig = false

func usa_coup(chosen_id : int):
	if chosen_id != -1:
		move_MO.rpc(0, ops_left)
		$Map.roll_d6.rpc(0)
		var dice_roll = $Map.last_roll
		var total = dice_roll + ops_left - $Map.map[chosen_id].stability * 2
		if $Map.map[chosen_id].famine:
			total += 1
		if total > 0:
			if total <= $Map.map[chosen_id].inf_soviet:
				$Map.set_inf_soviet.rpc(chosen_id, -total, true) 
			else:
				total -= $Map.map[chosen_id].inf_soviet
				$Map.set_inf_soviet.rpc(chosen_id, 0)
				$Map.set_inf_usa.rpc(chosen_id, total, true)
			if $Map.map[chosen_id].famine:
				$Map.remove_famine.rpc(chosen_id)
		if not zbig and ($Map.map[chosen_id].battleground or indian_ocean):
			move_defcon.rpc(-1)
		if not zbig and $Map.map[chosen_id].flashpoint:
			#TODO
			pass
		$Map.disable_countries()
	zbig = false
	emit_signal("response")
	$Map/Confirmation.disabled = false

func soviet_coup(chosen_id : int):
	if chosen_id != -1:
		move_MO.rpc(1, ops_left)
		$Map.roll_d6.rpc(1)
		var dice_roll = $Map.last_roll
		var total = dice_roll + ops_left - $Map.map[chosen_id].stability * 2
		if $Map.map[chosen_id].famine:
			total += 1
		print(total)
		if total > 0:
			if total <= $Map.map[chosen_id].inf_usa:
				$Map.set_inf_usa.rpc(chosen_id, -total, true) 
			else:
				total -= $Map.map[chosen_id].inf_usa
				print(total)
				$Map.set_inf_usa.rpc(chosen_id, 0)
				$Map.set_inf_soviet.rpc(chosen_id, total, true)
			if $Map.map[chosen_id].famine:
				$Map.remove_famine.rpc(chosen_id)
		if $Map.map[chosen_id].battleground or indian_ocean:
			move_defcon.rpc(-1)
		if $Map.map[chosen_id].flashpoint:
			#TODO
			pass
	$Map.disable_countries()
	$Map/Confirmation.disabled = false

# REALIGN REALIGN REALIGN
# filter need_opp_inf, ME (if defcon < 4)
# choose for each op (refilter), roll die

var realign_filter : MapFilter

func realign(id : int):
	var chosen : Card
	if id < 0:
		chosen = Blank.new()
		chosen.ops = -id
	else:
		chosen = Card.find_in_deck(Card.card_manifest, id)
	clear_card_options()
	ops_left = chosen.ops
	eligible.clear()
	
	play_opponent_event_after_resolution(chosen)
	
	realign_filter = MapFilter.new()
	if defcon < 4:
		realign_filter.region = Region.AFR
		realign_filter.ban.append(0)
	realign_filter.ban.append(11)
	if player_country == Phase.USA:
		realign_filter.need_presence_ussr = true
		emit_signal("choose_with_filter", realign_filter, realign_roll)
	elif player_country == Phase.USSR:
		realign_filter.need_presence_usa = true
		emit_signal("choose_with_filter", realign_filter, realign_roll)

var realign_modifier = 0 # Positive = to USA

func realign_roll(chosen_id: int):
	if chosen_id != -1:
		$Map.roll_d6.rpc(1)
		var sov_total = $Map.last_roll - $Map/Node.neg_modifier(chosen_id, Bloc.USA)
		$Map.roll_d6.rpc(0)
		var usa_total = $Map.last_roll - $Map/Node.neg_modifier(chosen_id, Bloc.USSR)
		if $Map.map[chosen_id].inf_soviet > $Map.map[chosen_id].inf_usa:
			sov_total += 1
		elif $Map.map[chosen_id].inf_soviet < $Map.map[chosen_id].inf_usa:
			usa_total += 1
		
		if realign_modifier > 0:
			usa_total += realign_modifier
		else:
			sov_total -= realign_modifier
		print(usa_total)
		print(sov_total)
	
		if usa_total > sov_total:
			usa_total -= sov_total
			$Map.set_inf_soviet.rpc(chosen_id, -usa_total, true)
		else:
			sov_total -= usa_total
			$Map.set_inf_usa.rpc(chosen_id, -sov_total, true)
		ops_left -= 1
		if ops_left <= 0:
			$Map.disable_countries()
			$Map/Confirmation.disabled = false
		else:
			$Map.disable_countries()
			emit_signal("choose_with_filter", realign_filter, realign_roll)
	else:
		$Map.disable_countries()
		$Map/Confirmation.disabled = false
	last_choice_id = chosen_id
	emit_signal("response")

# EVENT EVENT EVENT EVENT EVENT
# if own/neutral, event()
# if opp, redirect, then play ops

func event(id : int):
	var chosen = Card.find_in_deck(Card.card_manifest, id)
	clear_card_options()
	redirect_event(chosen, player_country)

func space_race(id : int):
	var chosen : Card = Card.find_in_deck(Card.card_manifest, id)
	hand.erase(chosen)
	discard.rpc(id)
	
	if player_country == Phase.USA:
		$Map.roll_d6.rpc(0)
		if space_usa == 0:
			if $Map.last_roll < 5:
				pass # remove 1 influence in next HL
		elif space_usa == 1:
			if $Map.last_roll < 4:
				if collected_3vp: move_VP.rpc(1)
				else: move_VP.rpc(2)
				move_space_race.rpc(0) # 2/1 VP
		else:
			if $Map.last_roll < 5:
				pass # draw card, 3 vp
	else:
		$Map.roll_d6.rpc(1)
		if space_ussr == 0:
			if $Map.last_roll < 5:
				pass # remove 1 influence in next HL
		elif space_ussr == 1:
			if $Map.last_roll < 4:
				if collected_3vp: move_VP.rpc(-1)
				else: move_VP.rpc(-2)
				move_space_race.rpc(1)
		else:
			if $Map.last_roll < 5:
				pass # draw card, 3 vp

# SPACE RACE REWARDS
var collected_3vp = false
	

# DRAWING CARDS



@rpc("any_peer", "call_local")
func remove_top_card():
	Card.mid_war_deck.remove_at(0)

@rpc("authority", "call_remote")
func draw_hand() -> void:
	for i in range(9):
		hand.append(Card.mid_war_deck[0])
		$HBox.add(Card.mid_war_deck[0])
		remove_top_card.rpc()

# MOVING TOKENS

@rpc("any_peer", "call_local")
func move_turn():
	turn += 1
	$Map/Turn.position.x += 37
	mo_usa = 0
	$Map/MO_USA.position.x = -221
	mo_ussr = 0
	$Map/MO_USSR.position.x = -221
	round = 0
	$Map/Round.position.x = -219
	move_defcon.rpc(1)

@rpc("any_peer", "call_local")
func move_defcon(delta : int):
	defcon += delta
	$Map/Defcon.position.x += -37 * delta

@rpc("any_peer", "call_local")
func move_round():
	round += 1
	$Map/Round.position.x += 37

@rpc("any_peer", "call_local")
func move_space_race(bloc_id : int):
	if bloc_id == 0:
		space_usa += 1
		if space_usa == 2:
			collected_3vp = true
		$Map/space_USA.position.y -= 60
	elif bloc_id == 1:
		space_ussr += 1
		if space_usa == 2:
			collected_3vp = true
		$Map/space_USSR.position.y -= 60

@rpc("any_peer", "call_local")
func move_MO(bloc_id : int, delta : int):
	if bloc_id == 0:
		delta = min(delta, 5 - mo_usa)
		delta = max(delta, -mo_usa)
		mo_usa += delta
		$Map/MO_USA.position.x += 37*delta
	else:
		delta = min(delta, 5 - mo_ussr)
		delta = max(delta, -mo_usa)
		mo_ussr += delta
		$Map/MO_USSR.position.x += 37*delta
	

const star_usa = preload("res://sprite/star_usa.png")
const star_soviet = preload("res://sprite/star_soviet.png")
var vp_init_pos : Vector2

@rpc("any_peer", "call_local")
func move_VP(delta : int): # +USA, -USSR
	vp += delta
	if vp >= 0:
		$Map/VP.texture = star_usa
	else:
		$Map/VP.texture = star_soviet
	var box_up = floor((abs(vp)+2)/3)
	var box_right = (abs(vp)-1) % 3
	if vp == 0:
		box_up = 0
		box_right = 0
	$Map/VP.position = vp_init_pos + Vector2(box_right * 37, box_up * -37)
	

# choose a bloc

func _on_play_usa_pressed() -> void:
	player_country = Phase.USA
	bloc_to_id[Phase.USA] = multiplayer.get_unique_id()
	bloc_to_id[Phase.USSR] = multiplayer.get_peers()[0]
	$PlayUSSR.queue_free()
	$PlayUSA/PlayUSA.queue_free()
	clear_country_choosing.rpc(0)

@rpc("any_peer", "call_remote")
func clear_country_choosing(id : int): # 0 - USA, 1 - USSR
	$PlayUSA/PlayUSA.queue_free()
	$PlayUSSR/PlayUSSR.queue_free()
	if id == 0:
		$PlayUSA.queue_free()
		player_country = Phase.USSR
		bloc_to_id[Phase.USA] = multiplayer.get_remote_sender_id()
		bloc_to_id[Phase.USSR] = multiplayer.get_unique_id()
	else:
		$PlayUSSR.queue_free()
		player_country = Phase.USA
		bloc_to_id[Phase.USA] = multiplayer.get_unique_id()
		bloc_to_id[Phase.USSR] = multiplayer.get_remote_sender_id()

func _on_play_ussr_pressed() -> void:
	player_country = Phase.USSR
	bloc_to_id[Phase.USSR] = multiplayer.get_unique_id()
	bloc_to_id[Phase.USA] = multiplayer.get_peers()[0]
	$PlayUSA.queue_free()
	$PlayUSSR/PlayUSSR.queue_free()
	clear_country_choosing.rpc(1)


# =========================== SPECIFIC EVENTS TOKENS =================

const event_icon = preload("res://icon/event_reminders/event_icon.tscn")
const ZOP_icon = preload("res://icon/event_reminders/zone_of_peace.jpg")
const nasser_icon = preload("res://icon/event_reminders/nasser.jpg")
const derg_icon = preload("res://icon/event_reminders/derg.png")

@rpc("any_peer", "call_local")
func zone_of_peace():
	var s = event_icon.instantiate()
	indian_ocean = true
	s.texture = ZOP_icon
	$Map/Reminder.add_child(s)

@rpc("any_peer", "call_local")
func nasserism():
	var s = event_icon.instantiate()
	nasser = true
	s.texture = nasser_icon
	$Map/Reminder.add_child(s)

@rpc("any_peer", "call_local")
func derg():
	var s = event_icon.instantiate()
	the_derg = true
	s.texture = derg_icon
	$Map/Reminder.add_child(s)

@rpc("any_peer", "call_local")
func USAID():
	usaid = true

@rpc("any_peer", "call_local")
func F56_active():
	F56 = true

# =========================== SPECIFIC EVENT EFFECTS =================

signal response
var last_choice_id = -1

# Cyrus Vance
# Gets two random cards, discards one of them
# If discarded.bloc == SOV, -2 VP
var first_card : Node
var second_card : Node

@rpc("any_peer", "call_remote")
func request_two_random_cards():
	var card1 = hand.pick_random()
	hand.erase(card1)
	$HBox.remove(card1)
	var card2 = hand.pick_random()
	hand.erase(card2)
	$HBox.remove(card2)
	receive_two_cards.rpc(card1.id, card2.id)
	
@rpc("any_peer", "call_remote")
func receive_two_cards(id1 : int, id2 : int):
	var card1 = Card.find_in_deck(Card.card_manifest, id1)
	var card2 = Card.find_in_deck(Card.card_manifest, id2)
	
	first_card = card_prefab.instantiate()
	first_card.get_node("Card").apply_ui(card1)
	add_child(first_card)
	first_card.position = Vector2(400, 400)
	first_card.get_node("Card/Button").pressed.connect(take_first)
	
	second_card = card_prefab.instantiate()
	second_card.get_node("Card").apply_ui(card2)
	add_child(second_card)
	second_card.position = Vector2(600, 400)
	second_card.get_node("Card/Button").pressed.connect(take_second)
	

func take_first():
	var card1 = first_card.get_node("Card").held
	var card2 = second_card.get_node("Card").held
	$HBox.add(card1)
	hand.append(card1)
	discard.rpc(card2.id)
	if card2.bloc == Bloc.USSR:
		move_VP.rpc(-2)
	first_card.queue_free()
	second_card.queue_free()
	emit_signal("response")

func take_second():
	var card1 = first_card.get_node("Card").held
	var card2 = second_card.get_node("Card").held
	$HBox.add(card2)
	hand.append(card2)
	discard.rpc(card1.id)
	if card1.bloc == Bloc.USSR:
		move_VP.rpc(-2)
	first_card.queue_free()
	second_card.queue_free()
	emit_signal("response")

# HERO OF THE CROSSING
# Discard soviet event (if none, skip)
# Grab a card from discard (if none, skip)
# Mark every Soviet, then unmark. Same for discard

@rpc("any_peer", "call_local")
func remove_from_discard(discard_id : int):
	$DiscardScroll/Discard.get_child(discard_id).queue_free()
	Card.discard.remove_at(discard_id)

func mark_soviet_in_hand():
	var atleast = false
	var i = 0
	for card in hand:
		if card.bloc == Bloc.USSR:
			atleast = true
			var card_node = $HBox.find(card)
			card_node.get_node("Card/Button").pressed.connect(func():
				discard.rpc(card.id)
				hand.remove_at(i)
				card_node.queue_free()
				unmark_hand()
				mark_neutral_us_in_discard()
			)
		i += 1
	if !atleast:
		mark_neutral_us_in_discard()

func unmark_hand():
	for node in $HBox/VBox_l.get_children():
		if node.get_node("Card").held.bloc == Bloc.USSR:
			var callable = node.get_node("Card/Button").pressed.get_connections()[-1]["callable"]
			node.get_node("Card/Button").pressed.disconnect(callable)
	for node in $HBox/VBox_r.get_children():
		if node.get_node("Card").held.bloc == Bloc.USSR:
			var callable = node.get_node("Card/Button").pressed.get_connections()[-1]["callable"]
			node.get_node("Card/Button").pressed.disconnect(callable)

func mark_neutral_us_in_discard():
	var atleast = false
	var i = 0
	for card in Card.discard:
		if card.bloc != Bloc.USSR and card.id != 6:
			atleast = true
			var card_node = $DiscardScroll/Discard.get_child(i)
			card_node.get_node("Card/Button").pressed.connect(func():
				$HBox.add(card)
				hand.append(card)
				unmark_discard()
				remove_from_discard.rpc(i)
				emit_signal("response")
			)
		i += 1
	if !atleast:	
		emit_signal("response")

func unmark_discard():
	for node in $DiscardScroll/Discard.get_children():
		var card = node.get_node("Card").held
		if card.bloc != Bloc.USSR and card.id != 6:
			var callable = node.get_node("Card/Button").pressed.get_connections()[-1]["callable"]
			node.get_node("Card/Button").pressed.disconnect(callable)
		
