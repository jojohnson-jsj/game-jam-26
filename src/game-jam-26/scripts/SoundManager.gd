extends Node

func play_sfx(stream: AudioStream, volume_db := 0, pitch := 1.0):
	var player = AudioStreamPlayer.new()
	add_child(player)

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.bus = "Master"

	player.play()
	player.finished.connect(player.queue_free)
