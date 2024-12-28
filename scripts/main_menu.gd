extends Control

var main_game = preload("res://Main.tscn").instantiate()


func _on_create_pressed() -> void:
	Network.create_server()
	get_parent().get_node("Game").add_child(main_game)
	queue_free()


func _on_join_pressed() -> void:
	Network.join_server()
	queue_free()
