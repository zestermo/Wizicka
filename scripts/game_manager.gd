### GODOT 4 MVP TEMPLATE (MAGYK GAME)
# This template includes:
# - Basic typing-based spellcasting
# - Dagger melee combat (light & heavy attack)
# - Stamina-based dodging
# - Small test zone with basic interactables
# - Basic AI enemies (melee + ranged)

extends Node3D

# Load necessary scenes & resources
@onready var player = $Player
#@onready var enemy_spawner = $EnemySpawner
#@onready var test_zone = $TestZone

# Initialize spells
var spells = {
	#"gust": preload("res://spells/gust.tscn"),
	#"zap": preload("res://spells/zap.tscn"),
	#"glaze": preload("res://spells/glaze.tscn"),
	#"blaze": preload("res://spells/blaze.tscn"),
	#"lesser_ward": preload("res://spells/lesser_ward.tscn")
}

# Initialize melee weapon
#@onready var dagger = player.get_node("Dagger")


#func _ready():
	#setup_player()
	#setup_enemies()
	#setup_test_zone()
	
#func setup_player():
	#player.set_weapon(dagger)
	#player.set_spells(spells)
	
#func setup_enemies():
	#enemy_spawner.spawn_enemy("melee_bandit", Vector3(5, 0, 5))
	#enemy_spawner.spawn_enemy("ranged_hunter", Vector3(-5, 0, -5))
	#
#func setup_test_zone():
	#test_zone.setup_environmental_objects()
