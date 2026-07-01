extends Node
## Autoload "SFX" — 절차 합성 WAV 로드 & 재생.
## 매 호출마다 독립 AudioStreamPlayer 를 달아 겹침 재생.

var _streams := {}


func _ready() -> void:
	for n in ["perfect", "good", "hit", "whoosh"]:
		var path := "res://assets/sfx/%s.wav" % n
		var s: AudioStream = load(path)
		if s:
			_streams[n] = s
		else:
			push_warning("SFX 누락: %s" % path)


func play(name: String, db: float = 0.0) -> void:
	if not _streams.has(name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = _streams[name]
	player.volume_db = db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func has(name: String) -> bool:
	return _streams.has(name)
