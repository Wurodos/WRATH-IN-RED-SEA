extends TextureRect

const headline_img = preload("res://icon/headline.png")
const place_inf_img = preload("res://icon/influence.png")
const coup_img = preload("res://icon/coup.png")
const realign_img = preload("res://icon/realignment.png")
const event_img = preload("res://icon/event.png")
const space_img = preload("res://icon/space.png")
const Card = preload("res://scripts/card.gd").Card
const Blank = preload("res://scripts/card.gd").Blank

enum Mode{
	HEADLINE,
	PLACE_INFLUENCE,
	COUP,
	REALIGNMENT,
	EVENT,
	SPACE_RACE,
	OPP_EVENT
}

var mode : Mode
var min_ops = 0

signal headline_chosen(card : Card)
signal place_influence(card : Card)
signal coup(card: Card)
signal realignment(card: Card)
signal event(card: Card)
signal space(card: Card)

func apply_ui(mode : Mode):
	self.mode = mode
	if mode == Mode.HEADLINE:
		texture = headline_img
	elif mode == Mode.PLACE_INFLUENCE:
		texture = place_inf_img
	elif mode == Mode.COUP:
		texture = coup_img
	elif mode == Mode.REALIGNMENT:
		texture = realign_img
	elif mode == Mode.EVENT:
		texture = event_img
	elif mode == Mode.SPACE_RACE:
		texture = space_img

func enable_button():
	$Button.disabled = false
	$Area2D.monitoring = false

func _on_button_pressed() -> void:
	if mode == Mode.HEADLINE:
		emit_signal("headline_chosen", -1)
	elif mode == Mode.PLACE_INFLUENCE:
		emit_signal("place_influence", -1)
	elif mode == Mode.COUP:
		emit_signal("coup", -1)
	elif mode == Mode.REALIGNMENT:
		emit_signal("realignment", -1)
	elif mode == Mode.EVENT:
		emit_signal("event", -1)
	self.queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	var card_id = area.get_parent().held.id
	if mode == Mode.HEADLINE:
		if card_id == 22:
			area.get_parent().position = Vector2.ZERO
			return
		emit_signal("headline_chosen", card_id)
	elif mode == Mode.PLACE_INFLUENCE:
		emit_signal("place_influence", card_id)
	elif mode == Mode.COUP:
		emit_signal("coup", card_id)
	elif mode == Mode.REALIGNMENT:
		emit_signal("realignment", card_id)
	elif mode == Mode.EVENT:
		if card_id == 22:
			area.get_parent().position = Vector2.ZERO
			return
		emit_signal("event", card_id)
	elif mode == Mode.SPACE_RACE:
		if area.get_parent().held.ops < min_ops:
			area.get_parent().position = Vector2.ZERO
			return
		emit_signal("space", card_id)
	if card_id != 22:
		area.get_parent().get_parent().free()
	self.queue_free()
	
	
