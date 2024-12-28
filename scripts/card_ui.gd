extends Sprite2D

const Card = preload("res://scripts/card.gd").Card
const Bloc = preload("res://scripts/card.gd").Bloc
const star_usa = preload("res://sprite/star_usa.png");
const star_ussr = preload("res://sprite/star_soviet.png");
const star_neutral = preload("res://sprite/star_neutral.png");
const romania_jpeg = preload("res://sprite/ceausescu.jpeg")
var held : Card


func apply_ui(card : Card) -> void:
	held = card
	$Name.text = held.name
	$Desc.text = held.desc
	if held.bloc == Bloc.USA:
		$Star.texture = star_usa
	elif held.bloc == Bloc.USSR:
		$Star.texture = star_ussr
	elif held.bloc == Bloc.NEUTRAL:
		$Star.texture = star_neutral
	$Star/Operations.text = str(held.ops)
	if held.asterisk:
		$Name.text += "*"
	
	# Romania
	if held.id == 22:
		texture = romania_jpeg

# Drag
@export
var draggable = true
var active = false
var dif = Vector2(0, 0)

func _process(_delta):
	var mouse_position = get_viewport().get_mouse_position()
	if draggable and active:
		global_position = mouse_position + dif

func _on_button_button_down() -> void:
	dif = get_global_position() - get_viewport().get_mouse_position()
	z_index = 5
	active = true

func _on_button_button_up() -> void:
	z_index = 0
	active = false
