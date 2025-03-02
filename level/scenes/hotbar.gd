extends Control

# Number of total slots (6 for future expansion)
const TOTAL_SLOTS = 6

# Array to store spells (use actual spell resources later)
var spells := ["blaze", "gust", "glaze", "float", null, null]

# Currently selected spell index
var selected_index: int = 0

@onready var slots = $HBoxContainer.get_children()  # Assuming a UI layout with an HBoxContainer

func _ready():
	update_hotbar_ui()

func _input(event):
	for i in range(TOTAL_SLOTS):
		if Input.is_action_just_pressed("spell_%d" % (i + 1)):
			select_spell(i)

func select_spell(index):
	if index >= len(spells) or spells[index] == null:
		return  # Ignore if invalid or empty slot
	
	selected_index = index
	update_hotbar_ui()
	print("Selected Spell: ", spells[selected_index])  # Debugging feedback

func update_hotbar_ui():
	for i in range(TOTAL_SLOTS):
		var slot = slots[i]
		if i == selected_index:
			slot.modulate = Color(1, 1, 1, 1)  # Highlight selected slot
		else:
			slot.modulate = Color(0.5, 0.5, 0.5, 1)  # Dim unselected slots
