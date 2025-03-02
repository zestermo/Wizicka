extends Control

@onready var health_bar = $HealthBar
@onready var mana_bar = $ManaBar
@onready var stamina_bar = $StaminaBar

var player: Node

func _ready():
	# Start checking for the player every frame until found
	set_process(true)

func _process(_delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player:
			player.connect("health_changed", _on_health_changed)
			player.connect("mana_changed", _on_mana_changed)
			player.connect("stamina_changed", _on_stamina_changed)
			print("found_player")
			# Initialize values
			_on_health_changed(player.health, player.max_health)
			_on_mana_changed(player.mana, player.max_mana)
			_on_stamina_changed(player.stamina, player.max_stamina)
			
			# Stop checking once the player is found
			set_process(false)

func _on_health_changed(current, max):
	health_bar.value = (current / float(max)) * 100

func _on_mana_changed(current, max):
	mana_bar.value = (current / float(max)) * 100

func _on_stamina_changed(current, max):
	stamina_bar.value = (current / float(max)) * 100
