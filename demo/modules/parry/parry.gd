extends Node2D
## Parry Demo 메인. 모든 노드를 동적으로 생성한다 (헤드리스 안정성).
##
## 판정 = 시간 기반. 투사체가 패링 라인에 도달할 "남은 시간" dt(초) 로 등급:
##   |dt| <= PERFECT_WINDOW  -> Perfect (히트스톱 + 대폭발)
##   |dt| <= GOOD_WINDOW     -> Good  (일반 패링)
## 투사체가 라인을 지나 플레이어까지 관통하면 -> Hit (체력 -1)
##
## 손맛 튜닝값은 상단 _TUNE 블록에 모아둠.

# === _TUNE (이사님 폰 피드백 후 조정 대상) ===
const PERFECT_WINDOW := 0.065   # ±65 ms
const GOOD_WINDOW := 0.140      # ±140 ms
const HIT_GRACE_PX := 70.0      # 라인 통과 후 이만큼 더 내려오면 피격
const SPAWN_START := 1.25       # 초
const SPAWN_MIN := 0.52
const SPEED_START := 880.0
const SPEED_GROW := 5.5         # px/s per second
# === /_TUNE ===

const COL_BG := Color(0.039, 0.039, 0.078)
const COL_LINE := Color(0.28, 0.88, 0.83, 0.55)
const COL_PLAYER := Color(0.16, 0.88, 0.95)
const COL_PERFECT := Color(0.5, 1.0, 0.95)
const COL_GOOD := Color(0.35, 0.9, 1.0)
const COL_HIT := Color(1.0, 0.4, 0.4)
const COL_TEXT := Color(0.92, 0.94, 1.0)

enum State { PLAY, GAMEOVER }

var viewport_w := 720.0
var viewport_h := 1280.0
var parry_line_y := 1000.0
var player_y := 1080.0

var world: Node2D
var projectiles: Node2D
var player: PlayerAvatar
var parry_band: ColorRect
var ui_score: Label
var ui_combo: Label
var ui_health: Label
var overlay: ColorRect
var overlay_label: Label

var state := State.PLAY
var score := 0
var combo := 0
var best_combo := 0
var health := 3
var time := 0.0
var spawn_timer := 0.0
var spawn_interval := SPAWN_START


func _ready() -> void:
	var size := get_viewport_rect().size
	viewport_w = size.x
	viewport_h = size.y
	parry_line_y = viewport_h * 0.80
	player_y = parry_line_y + 70.0

	_build_scene()
	update_ui()


func _build_scene() -> void:
	# 배경
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(bg)
	add_child(bg_layer)

	# 월드 (셰이크 대상)
	world = Node2D.new()
	add_child(world)

	# 그리드 라인 (깊이감)
	var grid := _GridDrawer.new()
	grid.color = Color(1, 1, 1, 0.03)
	world.add_child(grid)

	# 패링 존 밴드 (시각 유도)
	parry_band = ColorRect.new()
	parry_band.color = Color(0.28, 0.88, 0.83, 0.07)
	parry_band.size = Vector2(viewport_w, GOOD_WINDOW * SPEED_START * 2.0)
	parry_band.position = Vector2(0, parry_line_y - parry_band.size.y * 0.5)
	parry_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(parry_band)

	# 패링 라인
	var line := Line2D.new()
	line.width = 2.5
	line.default_color = COL_LINE
	line.add_point(Vector2(0, parry_line_y))
	line.add_point(Vector2(viewport_w, parry_line_y))
	world.add_child(line)

	# 투사체 컨테이너
	projectiles = Node2D.new()
	world.add_child(projectiles)

	# 플레이어
	player = PlayerAvatar.new()
	player.position = Vector2(viewport_w * 0.5, player_y)
	player.color = COL_PLAYER
	world.add_child(player)

	# UI
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 50
	_add_ui(ui_layer)
	add_child(ui_layer)

	# 게임오버 오버레이
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.02, 0.05, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ov_layer := CanvasLayer.new()
	ov_layer.layer = 80
	ov_layer.add_child(overlay)
	overlay_label = Label.new()
	overlay_label.add_theme_font_size_override("font_size", 46)
	overlay_label.add_theme_color_override("font_color", COL_TEXT)
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov_layer.add_child(overlay_label)
	add_child(ov_layer)


func _add_ui(layer: CanvasLayer) -> void:
	ui_score = Label.new()
	ui_score.text = "0"
	ui_score.add_theme_font_size_override("font_size", 54)
	ui_score.add_theme_color_override("font_color", COL_TEXT)
	ui_score.position = Vector2(28, 36)
	ui_score.size = Vector2(400, 70)
	ui_score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui_score)

	ui_combo = Label.new()
	ui_combo.text = ""
	ui_combo.add_theme_font_size_override("font_size", 28)
	ui_combo.add_theme_color_override("font_color", COL_PERFECT)
	ui_combo.position = Vector2(30, 100)
	ui_combo.size = Vector2(400, 40)
	ui_combo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui_combo)

	ui_health = Label.new()
	ui_health.add_theme_font_size_override("font_size", 38)
	ui_health.add_theme_color_override("font_color", COL_HIT)
	ui_health.position = Vector2(viewport_w - 200, 44)
	ui_health.size = Vector2(180, 50)
	ui_health.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui_health)


# === 입력 ===
func _unhandled_input(event: InputEvent) -> void:
	if state == State.GAMEOVER:
		if event.is_action_pressed("parry"):
			restart()
		return
	if event.is_action_pressed("parry"):
		try_parry()


func try_parry() -> void:
	player.punch()
	var best: Projectile = null
	var best_dt := INF
	for child in projectiles.get_children():
		var p := child as Projectile
		if p == null or not p.alive:
			continue
		# 라인 도달까지 남은 시간(초). + = 아직 위, - = 이미 지남
		var dt: float = (parry_line_y - p.position.y) / p.speed
		var adt: float = abs(dt)
		if adt <= GOOD_WINDOW and adt < best_dt:
			best_dt = adt
			best = p
	if best:
		on_parry(best, best_dt <= PERFECT_WINDOW)
	else:
		on_whiff()


func on_parry(p: Projectile, perfect: bool) -> void:
	if perfect:
		combo += 1
		best_combo = max(best_combo, combo)
		score += 100 * combo
		FX.hitstop(0.085, 0.05)
		FX.shake(world, 16.0, 0.34)
		FX.flash(Color(1, 1, 1), 0.5, 0.10)
		FX.shockwave(p.position, Color(0.18, 0.95, 0.9), 210.0, 0.30)
		FX.burst(p.position, Color(0.4, 1.0, 0.95), 28, 540.0, 6.0)
		FX.burst(p.position, Color.WHITE, 10, 280.0, 4.0)
		SFX.play("perfect", -2)
		p.bounce_away(true)
		spawn_floating(p.position, "PERFECT", COL_PERFECT, 48)
	else:
		combo += 1
		best_combo = max(best_combo, combo)
		score += 40
		FX.shake(world, 7.0, 0.20)
		FX.burst(p.position, COL_GOOD, 12, 340.0, 4.0)
		SFX.play("good", -3)
		p.bounce_away(false)
		spawn_floating(p.position, "GOOD", COL_GOOD, 34)
	update_ui()


func on_whiff() -> void:
	# 헛스윙 — 콤보는 유지, 작은 시각만 (너무 관대하면 타임패밍 의미 없음)
	combo = 0
	update_ui()


func on_hit(p: Projectile) -> void:
	p.vanish()
	combo = 0
	health -= 1
	FX.shake(world, 11.0, 0.30)
	FX.flash(Color(1.0, 0.18, 0.2), 0.45, 0.14)
	FX.burst(p.position, COL_HIT, 16, 380.0, 5.0)
	SFX.play("hit", -3)
	spawn_floating(Vector2(viewport_w * 0.5, player_y), "HIT", COL_HIT, 40)
	if health <= 0:
		game_over()
	update_ui()


# === 루프 ===
func _process(delta: float) -> void:
	if state != State.PLAY:
		return
	time += delta
	# 난이도 상승
	spawn_interval = clamp(SPAWN_START - time * 0.012, SPAWN_MIN, SPAWN_START)
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_projectile()
	# 피격 체크
	for child in projectiles.get_children():
		var p := child as Projectile
		if p and p.alive and p.position.y > player_y + HIT_GRACE_PX:
			on_hit(p)


func spawn_projectile() -> void:
	var p := Projectile.new()
	var x := randf_range(90.0, viewport_w - 90.0)
	p.position = Vector2(x, -50.0)
	p.speed = SPEED_START + time * SPEED_GROW + randf_range(-30.0, 60.0)
	p.radius = randf_range(26.0, 34.0)
	projectiles.add_child(p)
	SFX.play("whoosh", -10.0)


# === 게임오버 / 재시작 ===
func game_over() -> void:
	state = State.GAMEOVER
	FX.shake(world, 22.0, 0.5)
	FX.flash(Color(1, 0.15, 0.2), 0.6, 0.4)
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 0.78, 0.4)
	overlay_label.text = "GAME OVER\nScore %d   Best Combo %d\n\n탭해서 재시작" % [score, best_combo]


func restart() -> void:
	for child in projectiles.get_children():
		child.queue_free()
	score = 0
	combo = 0
	health = 3
	time = 0.0
	spawn_timer = 0.0
	spawn_interval = SPAWN_START
	state = State.PLAY
	overlay.color.a = 0.0
	overlay_label.text = ""
	update_ui()


# === UI 헬퍼 ===
func update_ui() -> void:
	ui_score.text = str(score)
	ui_combo.text = "COMBO x%d" % combo if combo > 1 else ""
	var hearts := ""
	for i in 3:
		hearts += "♥ " if i < health else "· "
	ui_health.text = hearts.strip_edges()


func spawn_floating(pos: Vector2, text: String, color: Color, font_size: int) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.position = pos - Vector2(80, 40)
	l.size = Vector2(160, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 130.0, 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tw.tween_property(l, "scale", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_BACK)
	tw.chain().tween_callback(func() -> void: l.queue_free())


# === 플레이어 아바타 (원 + 펀치 애니메이션) ===
class PlayerAvatar extends Node2D:
	var color := Color(0.16, 0.88, 0.95)
	var _scale := 1.0
	var _pulse := 0.0
	func _ready() -> void:
		z_index = 3
	func _process(delta: float) -> void:
		_pulse += delta * 5.0
		_scale = lerp(_scale, 1.0, min(1.0, delta * 12.0))
		queue_redraw()
	func _draw() -> void:
		var s := _scale
		var r := 42.0 * s
		# 바깥 글로우
		draw_circle(Vector2.ZERO, r + 18.0 + sin(_pulse) * 3.0,
			Color(color.r, color.g, color.b, 0.12))
		draw_circle(Vector2.ZERO, r + 8.0,
			Color(color.r, color.g, color.b, 0.25))
		# 본체
		draw_circle(Vector2.ZERO, r, color)
		# 링
		draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 48,
			color.lightened(0.5), 3.0)
		# 코어
		draw_circle(Vector2.ZERO, r * 0.4, Color(1, 1, 1, 0.9))
	func punch() -> void:
		_scale = 1.35


# === 그리드 (깊이감 배경) ===
class _GridDrawer extends Node2D:
	var color := Color(1, 1, 1, 0.03)
	func _draw() -> void:
		var w := 720.0
		var h := 1280.0
		var step := 90.0
		var y := stepfmod(0.0, step)
		while y < h:
			draw_line(Vector2(0, y), Vector2(w, y), color, 1.0)
			y += step
		var x := step
		while x < w:
			draw_line(Vector2(x, 0), Vector2(x, h), color, 1.0)
			x += step
	func stepfmod(a: float, s: float) -> float:
		return a
