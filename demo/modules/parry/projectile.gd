class_name Projectile
extends Node2D
## 적 투사체. 아래로 이동하며 패링 라인을 지난다.
## 판정은 Main 에서 시간 기반으로 계산하고, 여기서는 표현/이동/튕김만 담당.

signal passed_player

@export var speed := 900.0
@export var radius := 30.0
@export var base_color := Color(1.0, 0.45, 0.35)
var alive := true           # 판정 가능 상태
var bouncing := false       # 패막되어 튕기는 중
var _pulse := 0.0


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	_pulse += delta * 8.0
	if not bouncing:
		position.y += speed * delta
	queue_redraw()


func _draw() -> void:
	var col := base_color
	if bouncing:
		col = Color(0.16, 0.88, 0.95)   # 튕기면 시안으로 변환
	# 바깥 글로우
	var glow_a := 0.35 + 0.12 * sin(_pulse)
	draw_circle(Vector2.ZERO, radius + 10.0, Color(col.r, col.g, col.b, glow_a * 0.4))
	# 본체
	draw_circle(Vector2.ZERO, radius, col)
	# 하이라이트 링
	draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 40, col.lightened(0.4), 2.5)
	# 코어
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, 0.85))


## 패막 성공 시 위쪽으로 튕기며 사라짐.
func bounce_away(strong: bool) -> void:
	bouncing = true
	alive = false
	var dir := Vector2(randf_range(-0.3, 0.3), -1.0).normalized()
	var dist := 900.0 if strong else 520.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position",
		position + dir * dist, 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "rotation", TAU * (2.0 if strong else 1.0), 0.5)
	tw.chain().tween_callback(func() -> void: queue_free())


## 피격(관통) 시 사라짐.
func vanish() -> void:
	bouncing = true
	alive = false
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.8, 1.8), 0.08)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.18)
	tw.tween_callback(func() -> void: queue_free())
