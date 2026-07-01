extends Node
## Autoload "FX" — 전역 이펙트 헬퍼.
## 손맛의 3축: 히트스톱 / 스크린 셰이크 / 파티클 + 화면 플래시.
## 히트스톱 중에도 동작해야 하므로 PROCESS_MODE_ALWAYS.

var _shake_target: CanvasItem = null
var _shake_base := Vector2.ZERO
var _shake_amp := 0.0
var _shake_t := 0.0
var _shake_dur := 0.3
var _hitstop_left := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	# 히트스톱: 실제 시간 기준 복귀 (time_scale 영향 안 받음)
	if _hitstop_left > 0.0:
		_hitstop_left -= delta
		if _hitstop_left <= 0.0:
			Engine.time_scale = 1.0

	# 셰이크: 감쇠 진동 (진폭은 시간의 제곱으로 줄어듦)
	if _shake_target and is_instance_valid(_shake_target):
		_shake_t += delta
		if _shake_t >= _shake_dur:
			_shake_target.position = _shake_base
			_shake_target = null
		else:
			var k: float = 1.0 - (_shake_t / _shake_dur)
			var a: float = _shake_amp * k * k
			_shake_target.position = _shake_base + Vector2(
				_rng.randf_range(-a, a),
				_rng.randf_range(-a, a)
			)
	elif _shake_target:
		_shake_target = null


## 히트스톱. real_seconds 동안 time_scale 을 scale 로 고정.
func hitstop(real_seconds: float, scale: float = 0.04) -> void:
	Engine.time_scale = scale
	_hitstop_left = real_seconds


## target 의 position 기준으로 진동. amp(픽셀) dur(초).
func shake(target: CanvasItem, amp: float, dur: float = 0.3) -> void:
	if target == null:
		return
	_shake_target = target
	_shake_base = target.position
	_shake_amp = amp
	_shake_dur = dur
	_shake_t = 0.0


## 풀스크린 컬러 플래시 후 서서히 사라짐.
func flash(color: Color, alpha: float = 0.5, dur: float = 0.12) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(color.r, color.g, color.b, alpha)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	get_tree().root.add_child(layer)
	var tw := create_tween()
	tw.tween_property(rect, "color:a", 0.0, dur).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: layer.queue_free())


## 방사형 파티클 폭발. count 개가 pos 에서 사방으로 퍼지며 사라짐.
func burst(pos: Vector2, color: Color, count: int = 16,
		speed: float = 420.0, size: float = 5.0) -> void:
	var c := Node2D.new()
	c.position = pos
	get_tree().current_scene.add_child(c)
	for i in count:
		var ang: float = TAU * float(i) / float(count) + _rng.randf_range(-0.18, 0.18)
		var p := _make_particle(color, size * _rng.randf_range(0.7, 1.2))
		c.add_child(p)
		var dist: float = speed * _rng.randf_range(0.55, 1.15)
		var tw := c.create_tween().set_parallel(true)
		tw.tween_property(p, "position",
			Vector2(cos(ang), sin(ang)) * dist, 0.34).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "scale", Vector2.ZERO, 0.36).set_ease(Tween.EASE_IN)
	# 0.5초 후 컨테이너 정리
	var cleanup := c.create_tween()
	cleanup.tween_interval(0.5)
	cleanup.tween_callback(func() -> void: c.queue_free())


## 충격파 링 — 중심에서 바깥으로 퍼지는 원.
func shockwave(pos: Vector2, color: Color, max_r: float = 160.0, dur: float = 0.28) -> void:
	var ring := _RingDrawer.new()
	ring.position = pos
	ring.modulate = color
	get_tree().current_scene.add_child(ring)
	var tw := create_tween().set_parallel(true)
	tw.tween_method(ring.set_radius, 8.0, max_r, dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void: ring.queue_free())


func _make_particle(color: Color, size: float) -> Polygon2D:
	var poly := Polygon2D.new()
	var h: float = size * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)
	])
	poly.color = color
	return poly


## _draw 로 원을 그리는 충격파 노드.
class _RingDrawer extends Node2D:
	var radius: float = 8.0
	func set_radius(r: float) -> void:
		radius = r
		queue_redraw()
	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48,
			Color.WHITE, 4.0, true)
