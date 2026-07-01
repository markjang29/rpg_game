extends Node2D
## grid_parry — 파랜드 택틱스풍 그리드/턴 전술 × 패링 결합 한 장면.
##
## 흐름:
##   PLAYER_TURN  : 인접 빈 타일 탭=이동 / 자기 유닛 탭=대기  →  적 턴
##   ENEMY_TURN   : 적 1칸 이동 → 표적 타일 0.55초 예고(telegraph) → 투사체 발사
##   RESOLVE      : 투사체 비행 중 탭 = 패링. Perfect(±70ms)/Good(±155ms)/Miss.
##   GAMEOVER     : 탭 = 재시작
##
## "예측 가능한 여유(telegraph) → 찰나 긴장(패링)" 대비가 그리드 위 패링의 핵.
## FX/SFX 는 shared/ 재사용 (모듈식 첫 사례).

const COLS := 5
const ROWS := 6
const TILE := 120.0
const PERFECT_WINDOW := 0.070   # ±초
const GOOD_WINDOW := 0.155      # ±초
const TELEGRAPH := 0.55         # 표적 예고 시간
const ENEMY_MOVE_T := 0.26
const PLAYER_MOVE_T := 0.16

const COL_BG := Color(0.039, 0.039, 0.078)
const COL_GRID := Color(1, 1, 1, 0.05)
const COL_TILE_HI := Color(0.28, 0.88, 0.83, 0.10)  # 이동 가능 타일
const COL_TARGET := Color(1.0, 0.32, 0.28)         # 예고 표적
const COL_PLAYER := Color(0.16, 0.88, 0.95)
const COL_ENEMY := Color(1.0, 0.42, 0.36)
const COL_TEXT := Color(0.92, 0.94, 1.0)
const COL_PERFECT := Color(0.5, 1.0, 0.95)
const COL_GOOD := Color(0.35, 0.9, 1.0)
const COL_HIT := Color(1.0, 0.4, 0.4)

enum State { PLAYER_TURN, ENEMY_TURN, RESOLVE, GAMEOVER }

var state := State.PLAYER_TURN
var grid_origin := Vector2(60, 300)
var player_cell := Vector2i(2, 4)
var enemy_cell := Vector2i(2, 1)
var player_hp := 3
var enemy_hp := 3
var parries := 0
var perfects := 0
var _busy := false

var world: Node2D
var projectiles: Node2D
var player_node: UnitSprite
var enemy_node: UnitSprite
var target_marker: Node2D
var hint_label: Label
var top_label: Label
var overlay: ColorRect
var overlay_label: Label


func _ready() -> void:
	var size := get_viewport_rect().size
	grid_origin = Vector2((size.x - COLS * TILE) * 0.5, 270.0)
	_build_scene()
	_start_player_turn()


# === 씬 구성 ===
func _build_scene() -> void:
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(bg)
	add_child(bg_layer)

	world = Node2D.new()
	add_child(world)

	var grid := _GridDrawer.new()
	grid.color = COL_GRID
	grid.origin = grid_origin
	grid.cols = COLS
	grid.rows = ROWS
	grid.tile = TILE
	world.add_child(grid)

	projectiles = Node2D.new()
	world.add_child(projectiles)

	player_node = UnitSprite.new()
	player_node.color = COL_PLAYER
	player_node.position = tile_center(player_cell)
	world.add_child(player_node)

	enemy_node = UnitSprite.new()
	enemy_node.color = COL_ENEMY
	enemy_node.position = tile_center(enemy_cell)
	world.add_child(enemy_node)

	target_marker = _TargetMarker.new()
	target_marker.visible = false
	world.add_child(target_marker)

	# UI
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 50
	top_label = Label.new()
	top_label.add_theme_font_size_override("font_size", 30)
	top_label.add_theme_color_override("font_color", COL_TEXT)
	top_label.position = Vector2(28, 40)
	top_label.size = Vector2(660, 50)
	top_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(top_label)

	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 26)
	hint_label.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	hint_label.position = Vector2(28, 88)
	hint_label.size = Vector2(660, 40)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hint_label)

	# 게임오버 오버레이
	var ov_layer := CanvasLayer.new()
	ov_layer.layer = 80
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.02, 0.05, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov_layer.add_child(overlay)
	overlay_label = Label.new()
	overlay_label.add_theme_font_size_override("font_size", 42)
	overlay_label.add_theme_color_override("font_color", COL_TEXT)
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov_layer.add_child(overlay_label)
	add_child(ov_layer)


func _draw() -> void:
	# 이동 가능 타일 하이라이트 (PLAYER_TURN)
	if state == State.PLAYER_TURN and not _busy:
		for c in _adjacent(player_cell):
			var r := Rect2(grid_origin + Vector2(c.x * TILE, c.y * TILE), Vector2(TILE, TILE))
			draw_rect(r, COL_TILE_HI, false, 3.0)
			draw_rect(r, COL_TILE_HI, true)


# === 좌표 헬퍼 ===
func tile_center(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell.x * TILE + TILE * 0.5, cell.y * TILE + TILE * 0.5)


func world_to_cell(p: Vector2) -> Vector2i:
	var local := p - grid_origin
	var c := int(local.x / TILE)
	var r := int(local.y / TILE)
	if c < 0 or c >= COLS or r < 0 or r >= ROWS:
		return Vector2i(-1, -1)
	return Vector2i(c, r)


func _adjacent(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d in dirs:
		var c: Vector2i = cell + d
		if c.x >= 0 and c.x < COLS and c.y >= 0 and c.y < ROWS:
			out.append(c)
	return out


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


# === 입력 ===
func _unhandled_input(event: InputEvent) -> void:
	if state == State.GAMEOVER:
		if event.is_action_pressed("parry"):
			_restart()
		return
	if event.is_action_pressed("parry"):
		if state == State.RESOLVE:
			_try_parry()
		elif state == State.PLAYER_TURN and not _busy:
			_on_player_tap(event)


func _on_player_tap(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		pos = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton:
		pos = (event as InputEventMouseButton).position
	else:
		return
	var cell := world_to_cell(pos)
	if cell == player_cell:
		# 자기 유닛 탭 = 대기
		queue_redraw()
		_end_player_turn(null)
	elif cell == enemy_cell or cell.x < 0:
		return
	else:
		# 인접 타일만 이동
		if _manhattan(cell, player_cell) == 1:
			_end_player_turn(cell)
		else:
			queue_redraw()


# === 플레이어 턴 ===
func _start_player_turn() -> void:
	state = State.PLAYER_TURN
	_busy = false
	top_label.text = "YOU %d   ENEMY %d" % [player_hp, enemy_hp]
	hint_label.text = "이동할 타일 탭 / 본인 탭=대기"
	queue_redraw()


func _end_player_turn(move_to: Variant) -> void:
	_busy = true
	queue_redraw()
	if move_to != null:
		player_cell = move_to
		var tw := create_tween()
		tw.tween_property(player_node, "position", tile_center(player_cell), PLAYER_MOVE_T)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		await tw.finished
	_start_enemy_turn()


# === 적 턴: 이동 → 예고 → 발사 ===
func _start_enemy_turn() -> void:
	state = State.ENEMY_TURN
	hint_label.text = "적의 턴…"
	# 적: 플레이어 방향으로 1칸 이동 (행 우선, 열 차이 다음)
	var step := _step_toward(enemy_cell, player_cell)
	if step != enemy_cell:
		enemy_cell = step
		var tw := create_tween()
		tw.tween_property(enemy_node, "position", tile_center(enemy_cell), ENEMY_MOVE_T)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		await tw.finished
	# 표적 예고(telegraph) → 발사
	_telegraph_then_fire()


func _step_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var dx: int = sign(to.x - from.x)
	var dy: int = sign(to.y - from.y)
	# 행(거리) 우선 — 플레이어가 있는 쪽으로
	if dy != 0 and from.y + dy >= 0 and from.y + dy < ROWS:
		return Vector2i(from.x, from.y + dy)
	if dx != 0 and from.x + dx >= 0 and from.x + dx < COLS:
		return Vector2i(from.x + dx, from.y)
	return from


func _telegraph_then_fire() -> void:
	var target_world := tile_center(player_cell)
	target_marker.position = target_world
	target_marker.visible = true
	target_marker.modulate.a = 1.0
	hint_label.text = "표적 예고 — 타이밍을 잡아라"
	await get_tree().create_timer(TELEGRAPH).timeout
	target_marker.visible = false
	_fire_projectile(target_world)


func _fire_projectile(target_world: Vector2) -> void:
	state = State.RESOLVE
	hint_label.text = "탭 = 패링!"
	var p := GridProjectile.new()
	var from := tile_center(enemy_cell)
	var dist := float(_manhattan(player_cell, enemy_cell))
	var flight := 0.42 + dist * 0.07
	p.setup(from, target_world, flight, GridProjectile.now())
	projectiles.add_child(p)


# === 판정 ===
func _try_parry() -> void:
	var best: GridProjectile = null
	var best_dt := INF
	var now := GridProjectile.now()
	for child in projectiles.get_children():
		var p := child as GridProjectile
		if p == null or not p.alive:
			continue
		var dt: float = p.t_hit - now
		var adt: float = abs(dt)
		if adt <= GOOD_WINDOW and adt < best_dt:
			best_dt = adt
			best = p
	if best:
		_on_parry(best, best_dt <= PERFECT_WINDOW)
	else:
		# 헛스윙 — 약한 피드백만
		player_node.punch()
		SFX.play("whoosh", -12.0)


func _on_parry(p: GridProjectile, perfect: bool) -> void:
	parries += 1
	if perfect:
		perfects += 1
		enemy_hp -= 1
		FX.hitstop(0.09, 0.05)
		FX.shake(world, 16.0, 0.34)
		FX.flash(Color(1, 1, 1), 0.5, 0.10)
		FX.shockwave(p.position, Color(0.18, 0.95, 0.9), 210.0, 0.30)
		FX.burst(p.position, Color(0.4, 1.0, 0.95), 28, 540.0, 6.0)
		FX.burst(p.position, Color.WHITE, 10, 280.0, 4.0)
		SFX.play("perfect", -2)
		p.bounce_to(tile_center(enemy_cell), true)
		enemy_node.hit()
		_floating(p.position, "PERFECT!", COL_PERFECT, 44)
		_floating(tile_center(enemy_cell), "-1", COL_PERFECT, 36)
	else:
		FX.shake(world, 7.0, 0.20)
		FX.burst(p.position, COL_GOOD, 12, 340.0, 4.0)
		SFX.play("good", -3)
		p.vanish()
		_floating(p.position, "GOOD", COL_GOOD, 34)
	await get_tree().create_timer(0.12).timeout
	_resolve_end()


func _on_miss(p: GridProjectile) -> void:
	player_hp -= 1
	FX.shake(world, 11.0, 0.30)
	FX.flash(Color(1.0, 0.18, 0.2), 0.45, 0.14)
	FX.burst(p.position, COL_HIT, 16, 380.0, 5.0)
	SFX.play("hit", -3)
	p.vanish()
	player_node.hit()
	_floating(tile_center(player_cell), "HIT", COL_HIT, 40)
	_resolve_end()


func _resolve_end() -> void:
	# 잔여 투사체 정리
	for child in projectiles.get_children():
		child.queue_free()
	if player_hp <= 0 or enemy_hp <= 0:
		_game_over()
	else:
		_start_player_turn()


# === 루프: 투사체 도달(Miss) 감지 ===
func _process(_delta: float) -> void:
	if state != State.RESOLVE:
		return
	for child in projectiles.get_children():
		var p := child as GridProjectile
		if p and not p.alive:
			_on_miss(p)
			return


# === 게임오버 / 재시작 ===
func _game_over() -> void:
	state = State.GAMEOVER
	FX.shake(world, 22.0, 0.5)
	FX.flash(Color(1, 0.15, 0.2), 0.6, 0.4)
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 0.78, 0.4)
	var won := enemy_hp <= 0
	var title := "승 리!" if won else "패 배"
	overlay_label.text = "%s\n패막 %d회 (Perfect %d)\n탭=재시작" % [title, parries, perfects]


func _restart() -> void:
	for child in projectiles.get_children():
		child.queue_free()
	player_cell = Vector2i(2, 4)
	enemy_cell = Vector2i(2, 1)
	player_node.position = tile_center(player_cell)
	enemy_node.position = tile_center(enemy_cell)
	player_hp = 3
	enemy_hp = 3
	parries = 0
	perfects = 0
	overlay.color.a = 0.0
	overlay_label.text = ""
	_start_player_turn()


# === 헬퍼 ===
func _floating(pos: Vector2, text: String, color: Color, fs: int) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	l.position = pos - Vector2(90, 30)
	l.size = Vector2(180, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 110.0, 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void: l.queue_free())


# === 유닛 스프라이트 ===
class UnitSprite extends Node2D:
	var color := Color(1, 1, 1)
	var _scale := 1.0
	var _pulse := 0.0
	var _hit_flash := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		_pulse += delta * 5.0
		_scale = lerpf(_scale, 1.0, minf(1.0, delta * 12.0))
		_hit_flash = maxf(0.0, _hit_flash - delta * 4.0)
		queue_redraw()

	func _draw() -> void:
		var r := 40.0 * _scale
		var c := color
		if _hit_flash > 0.0:
			c = c.lerp(Color.WHITE, _hit_flash)
		draw_circle(Vector2.ZERO, r + 16.0 + sin(_pulse) * 2.5,
			Color(c.r, c.g, c.b, 0.12))
		draw_circle(Vector2.ZERO, r + 7.0, Color(c.r, c.g, c.b, 0.25))
		draw_circle(Vector2.ZERO, r, c)
		draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 44, c.lightened(0.5), 3.0)
		draw_circle(Vector2.ZERO, r * 0.4, Color(1, 1, 1, 0.9))

	func punch() -> void:
		_scale = 1.3

	func hit() -> void:
		_scale = 1.4
		_hit_flash = 1.0


# === 표적 예고 마커 (붉은 링) ===
class _TargetMarker extends Node2D:
	var _t := 0.0
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * 12.0)
		draw_arc(Vector2.ZERO, 52.0 + pulse * 6.0, 0.0, TAU, 40,
			Color(1.0, 0.32, 0.28, 0.9), 5.0)
		draw_arc(Vector2.ZERO, 70.0, 0.0, TAU, 40,
			Color(1.0, 0.32, 0.28, 0.3), 2.0)


# === 그리드 ===
class _GridDrawer extends Node2D:
	var color := Color(1, 1, 1, 0.05)
	var origin := Vector2.ZERO
	var cols := 5
	var rows := 6
	var tile := 120.0
	func _draw() -> void:
		for r in rows + 1:
			var y := origin.y + r * tile
			draw_line(Vector2(origin.x, y), Vector2(origin.x + cols * tile, y), color, 1.5)
		for c in cols + 1:
			var x := origin.x + c * tile
			draw_line(Vector2(x, origin.y), Vector2(x, origin.y + rows * tile), color, 1.5)
