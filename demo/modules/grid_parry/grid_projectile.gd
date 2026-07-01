class_name GridProjectile
extends Node2D
## 그리드 전술용 투사체. from 타일 → to 타일을 일정 시간에 걸쳐 비행.
## 판정은 Main 에서 "도달 예정 시각 t_hit" 기준으로 계산한다(시간 기반 패링).
## Time.get_ticks_msec() 기준 — Main 과 동일 클럭.

var from := Vector2.ZERO
var to := Vector2.ZERO
var t_start := 0.0
var flight_time := 0.7
var t_hit := 0.0
var alive := true
var radius := 28.0
var base_color := Color(1.0, 0.45, 0.35)
var _pulse := 0.0

const NOW := "now_marker"  # (사용 안 함 — 문서용)


static func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func setup(p_from: Vector2, p_to: Vector2, p_flight: float, p_t_start: float) -> void:
	from = p_from
	to = p_to
	flight_time = p_flight
	t_start = p_t_start
	t_hit = t_start + p_flight
	position = from
	z_index = 6


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	_pulse += delta * 9.0
	if not alive:
		return
	var k: float = clampf((now() - t_start) / flight_time, 0.0, 1.0)
	# 살짝 아치(포물선) — 시각적 비행감
	var arc := sin(k * PI) * 22.0
	position = from.lerp(to, k) + Vector2(0, -arc)
	queue_redraw()
	if k >= 1.0:
		alive = false


func _draw() -> void:
	var col := base_color
	var glow_a := 0.4 + 0.15 * sin(_pulse)
	draw_circle(Vector2.ZERO, radius + 10.0, Color(col.r, col.g, col.b, glow_a * 0.4))
	draw_circle(Vector2.ZERO, radius, col)
	draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 36, col.lightened(0.4), 2.5)
	draw_circle(Vector2.ZERO, radius * 0.42, Color(1, 1, 1, 0.9))


## 패막 성공 시 표적 반대방향(적 쪽)으로 튕김.
func bounce_to(target: Vector2, strong: bool) -> void:
	alive = false
	var dir := (target - position).normalized()
	var dist := 900.0 if strong else 520.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position", position + dir * dist, 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "rotation", TAU * (2.0 if strong else 1.0), 0.5)
	tw.chain().tween_callback(func() -> void: queue_free())


func vanish() -> void:
	alive = false
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.7, 1.7), 0.08)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.18)
	tw.tween_callback(func() -> void: queue_free())
