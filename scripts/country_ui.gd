extends Node

const Country = preload("res://scripts/map.gd").Country
const inf_ussr_un = preload("res://sprite/influence_sov/inf_uncontrol.png")
const inf_ussr_ctr = preload("res://sprite/influence_sov/inf_control.png")
const inf_usa_un = preload("res://sprite/influence_usa/inf_uncontrol.png")
const inf_usa_ctr = preload("res://sprite/influence_usa/inf_control.png")

var held : Country
signal chosen(id : int)

func on_pressed():
	emit_signal("chosen", held.id)
	

func make_pressable():
	if not $CountryButton.pressed.is_connected(on_pressed):
		$CountryButton.pressed.connect(on_pressed)
		$CountryButton.self_modulate = Color.WHITE

func unmake_pressable():
	if $CountryButton.pressed.is_connected(on_pressed):
		$CountryButton.pressed.disconnect(on_pressed)
		$CountryButton.self_modulate = Color.TRANSPARENT

func set_inf_soviet(inf : int, delta = false):
	if delta:
		held.inf_soviet += inf
	else:
		held.inf_soviet = inf
	if held.inf_soviet > 0:
		$USSRinf/Label.text = str(held.inf_soviet)
	else:
		held.inf_soviet = 0
		$USSRinf/Label.text = ""
	check_tokens()

func set_inf_usa(inf : int, delta = false):
	if delta:
		held.inf_usa += inf
	else:
		held.inf_usa = inf
	if held.inf_usa > 0:
		$USinf/Label.text = str(held.inf_usa)
	else:
		held.inf_usa = 0
		$USinf/Label.text = ""
	check_tokens()


func check_tokens():
	if held.inf_soviet <= 0:
		$USSRinf.texture = null
	elif held.inf_soviet < held.stability + held.inf_usa:
		$USSRinf.texture = inf_ussr_un
	else:
		$USSRinf.texture = inf_ussr_ctr
	
	if held.inf_usa <= 0:
		$USinf.texture = null
	elif held.inf_usa < held.stability + held.inf_soviet:
		$USinf.texture = inf_usa_un
	else:
		$USinf.texture = inf_usa_ctr


func add_famine():
	held.famine = true
	$Famine.visible = true
	
func remove_famine():
	held.famine = false
	$Famine.visible = false
