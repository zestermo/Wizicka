extends AudioStreamPlayer3D

@export var music_folder: String = "res://assets/bg_music/"  # Folder where songs are stored
@export var fade_duration: float = 5.0  # Fade-in and fade-out time

var song_list = []
var current_song: AudioStream = null

func _ready():
	# Load all songs from the folder
	var dir = DirAccess.open(music_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".ogg") or file_name.ends_with(".mp3") or file_name.ends_with(".wav"):
				song_list.append(music_folder + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if song_list.is_empty():
		push_error("❌ No music files found in " + music_folder)
		return
	
	# Start playing the first song
	play_random_song()

func play_random_song():
	if song_list.is_empty():
		return

	var random_song = load(song_list[randi() % song_list.size()])
	
	if random_song != current_song:
		current_song = random_song
		fade_out_and_play(current_song)

func fade_out_and_play(new_song: AudioStream):
	# Smooth fade-out
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(self, "volume_db", -40, fade_duration)  # Fade out to silence
	await fade_out_tween.finished

	# Set new song and play it
	stream = new_song
	play()
	
	# Smooth fade-in
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(self, "volume_db", -10, fade_duration)  # Fade in to normal volume

func _on_finished():
	play_random_song()  # Play next song when current one ends
