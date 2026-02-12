extends Node2D

const GameScript = preload("res://scripts/game/game.gd")


func _ready() -> void:
	var game = GameScript.new()
	game.setup_run({
		"hero_id": "warden",
		"realm_id": "endless",
		"meta": {},
		"settings": {}
	})
	add_child(game)

