extends Node

const Card = preload("res://scripts/card.gd").Card
const cardPrefab = preload("res://scripts/card.tscn")

var alternate = false

func add(card):
	var instance = cardPrefab.instantiate()
	if alternate:
		$VBox_r.add_child(instance)
	else:
		$VBox_l.add_child(instance)
	instance.get_node("Card").apply_ui(card)
	alternate = !alternate

func find(card):
	for c in $VBox_r.get_children():
		if c.get_node("Card").held.id == card.id:
			return c
	for c in $VBox_l.get_children():
		if c.get_node("Card").held.id == card.id:
			return c

func remove(card):
	for c in $VBox_r.get_children():
		if c.get_node("Card").held.id == card.id:
			c.queue_free()
			return
	for c in $VBox_l.get_children():
		if c.get_node("Card").held.id == card.id:
			c.queue_free()
			return
