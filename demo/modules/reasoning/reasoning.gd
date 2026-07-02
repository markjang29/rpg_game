extends Node2D
## reasoning — "참모 추론 × 지휘관 결정 × 패링 손맛" 시그니처 프로토타입.
##
## 시그니처(ideation/08):
##   참모(캐릭터)   = 불완전한 추론 보고서(작전안 3 + 위험%)를 낸다. 편향 있음.
##   지휘관(플레이어) = 전제(목표) 토글로 추천을 바꾸고, 작전안을 고른다.
##   손(플레이어)   = 적 공격 임박 타이밍에 패링으로 위험을 0으로 만든다.
##
## 흐름:
##   ADVISOR   : 턴 시작. 참모 작전안 3 + 위험% 산출·표시. 플레이어 = 전제 토글 / 심층(토큰) / 작전안 선택.
##   ENEMY_TURN: 선택 작전안 자동 실행(이동/대기) → 적 이동 → 표적 예고(telegraph)
##   RESOLVE   : 투사체 비행 중 탭 = 패링. Perfect(±70ms)/Good/Miss.
##   GAMEOVER  : 탭 = 재시작
##
## 위험 모델(단순, 거리 기반): d=Manhattan(플레이어 후, 적 후).
##   위험% = clamp(40 - 8*d, 5, 40).  d1=32 / d2=24 / d3=16 / d4=8 / d5=5.
##   패링 성공 시 d≤2 면 튕긴 투사체가 적에 닿아 -1(dmg 1). d≥3 이면 피해만 막고 데미지 0.
## 편향: 공격형 참모 — 킬(B·맞받) 위험을 0.66배 과소평가(32→21%). 심층 분석 시 "정정: 보정 전 32%" 공개.

const COLS := 5
const ROWS := 6
const TILE := 120.0
const PERFECT_WINDOW := 0.070
const GOOD_WINDOW := 0.155
const TELEGRAPH := 0.55
const ENEMY_MOVE_T := 0.26
const PLAYER_MOVE_T := 0.16
const START_TOKENS := 3
const ATTACK_BIAS := 0.66

const COL_BG := Color(0.039, 0.039, 0.078)
const COL_GRID := Color(1, 1, 1, 0.05)
const COL_PLAYER := Color(0.16, 0.88, 0.95)
const COL_ENEMY := Color(1.0, 0.42, 0.36)
const COL_TEXT := Color(0.92, 0.94, 1.0)
const COL_DIM := Color(0.7, 0.78, 0.9)
const COL_PANEL := Color(0.09, 0.11, 0.19, 0.94)
const COL_PANEL_HI := Color(0.16, 0.95, 0.84)
const COL_WARN := Color(1.0, 0.62, 0.38)
const COL_RISK_HI := Color(1.0, 0.42, 0.42)
const COL_RISK_LO := Color(0.42, 1.0, 0.72)
const COL_PERFECT := Color(0.5, 1.0, 0.95)
const COL_GOOD := Color(0.35, 0.9, 1.0)
const COL_HIT := Color(1.0, 0.4, 0.4)
const COL_DIM_BOX := Color(0.13, 0.15, 0.24, 0.9)

enum State { ADVISOR, ENEMY_TURN, RESOLVE, GAMEOVER }
enum Preset { DEFEND, KILL, HOLD }

var state := State.ADVISOR
var grid_origin := Vector2(60, 320)
var player_cell := Vector2i(2, 4)
var enemy_cell := Vector2i(2, 1)
var player_hp := 3
var enemy_hp := 3
var parries := 0
var perfects := 0
var _busy := false

var preset: int = Preset.KILL
var tokens: int = START_TOKENS
var deep: bool = false
var plans: Array = []          # Array[_Plan]
var chosen_plan: _Plan = null

var world: Node2D
var projectiles: Node2D
var player_node: UnitSprite
var enemy_node: UnitSprite
var target_marker: Node2D
var top_label: Label
var hint_label: Label
var token_label: Label
var overlay: ColorRect
var overlay_label: Label
var advisor_root: Control
var plan_boxes: Array = []     # 3 _PlanBox
var preset_chips: Array = []   # 3 _Chip
var deep_btn: Control
var deep_btn_label: Label


func _ready() -> void:
	var size := get_viewport_rect().size
	grid_origin = Vector2((size.x - COLS * TILE) * 0.5, 320.0)
	_build_scene()
	_start_advisor_turn()


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

	# UI 레이어
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 50

	_build_advisor_ui(ui_layer)

	top_label = Label.new()
	top_label.add_theme_font_size_override("font_size", 30)
	top_label.add_theme_color_override("font_color", COL_TEXT)
	top_label.position = Vector2(28, 268)
	top_label.size = Vector2(660, 44)
	top_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(top_label)

	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 24)
	hint_label.add_theme_color_override("font_color", COL_DIM)
	hint_label.position = Vector2(28, 1244)
	hint_label.size = Vector2(660, 30)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hint_label)
	add_child(ui_layer)

	# 게임오버 오버레이
	var ov_layer := CanvasLayer.new()
	ov_layer.layer = 80
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.02, 0.05, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov_layer.add_child(overlay)
	overlay_label = Label.new()
	overlay_label.add_theme_font_size_override("font_size", 40)
	overlay_label.add_theme_color_override("font_color", COL_TEXT)
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov_layer.add_child(overlay_label)
	add_child(ov_layer)


# 상단 추론 패널(0~260): 제목·토큰 / 전제 칩 3 / 심층 버튼 / 작전안 3 박스
func _build_advisor_ui(ui_layer: CanvasLayer) -> void:
	advisor_root = Control.new()
	advisor_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advisor_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(advisor_root)

	var panel := ColorRect.new()
	panel.color = COL_PANEL
	panel.position = Vector2(20, 18)
	panel.size = Vector2(680, 244)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advisor_root.add_child(panel)

	var title := Label.new()
	title.text = "참모 보고서"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COL_TEXT)
	title.position = Vector2(36, 26)
	title.size = Vector2(300, 36)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advisor_root.add_child(title)

	token_label = Label.new()
	token_label.add_theme_font_size_override("font_size", 22)
	token_label.add_theme_color_override("font_color", COL_WARN)
	token_label.position = Vector2(500, 30)
	token_label.size = Vector2(180, 30)
	token_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	token_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advisor_root.add_child(token_label)

	# 전제 칩 3
	var preset_names := ["방어 우선", "킬 우선", "거점 우선"]
	var px := 36.0
	for i in 3:
		var chip := _Chip.new()
		chip.label_text = preset_names[i]
		chip.idx = i
		chip.position = Vector2(px, 70)
		chip.size = Vector2(196, 38)
		chip.rect = Rect2(chip.position, chip.size)
		advisor_root.add_child(chip)
		preset_chips.append(chip)
		px += 204.0

	# 심층 분석 버튼
	deep_btn = Control.new()
	deep_btn.position = Vector2(36, 116)
	deep_btn.size = Vector2(648, 40)
	deep_btn.set_meta("rect", Rect2(deep_btn.position, deep_btn.size))
	var dbg := ColorRect.new()
	dbg.color = Color(0.16, 0.18, 0.30, 0.9)
	dbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deep_btn.add_child(dbg)
	deep_btn_label = Label.new()
	deep_btn_label.add_theme_font_size_override("font_size", 20)
	deep_btn_label.add_theme_color_override("font_color", COL_WARN)
	deep_btn_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	deep_btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deep_btn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deep_btn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deep_btn.add_child(deep_btn_label)
	advisor_root.add_child(deep_btn)

	# 작전안 박스 3 (가로)
	var bx := 36.0
	for i in 3:
		var box := _PlanBox.new()
		box.idx = i
		box.position = Vector2(bx, 164)
		box.size = Vector2(204, 76)
		box.set_meta("rect", Rect2(box.position, box.size))
		box.build()
		advisor_root.add_child(box)
		plan_boxes.append(box)
		bx += 212.0


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


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < COLS and c.y >= 0 and c.y < ROWS


# === 참모 추론: 작전안 3 생성 ===
func _risk_for(p_after: Vector2i, e_after: Vector2i) -> float:
	var d: int = _manhattan(p_after, e_after)
	return clampf(40.0 - 8.0 * float(d), 5.0, 40.0)


# 적이 p_target 쪽으로 한 칸 이동한 예상 위치
func _enemy_step_toward(from: Vector2i, p_target: Vector2i) -> Vector2i:
	var dx: int = sign(p_target.x - from.x)
	var dy: int = sign(p_target.y - from.y)
	if dy != 0 and _in_bounds(Vector2i(from.x, from.y + dy)):
		return Vector2i(from.x, from.y + dy)
	if dx != 0 and _in_bounds(Vector2i(from.x + dx, from.y)):
		return Vector2i(from.x + dx, from.y)
	return from


func _build_plans() -> Array:
	# 후보 이동: 제자리 + 인접 4 (유효). 적 위치는 제외.
	var cands: Array = []
	var here: Array[Vector2i] = [player_cell,
		player_cell + Vector2i(1, 0), player_cell + Vector2i(-1, 0),
		player_cell + Vector2i(0, 1), player_cell + Vector2i(0, -1)]
	for c in here:
		if _in_bounds(c) and c != enemy_cell:
			cands.append(c)

	# 각 후보 평가
	var evals: Array = []
	for c in cands:
		var e_after := _enemy_step_toward(enemy_cell, c)
		var risk_t := _risk_for(c, e_after)
		var d: int = _manhattan(c, e_after)
		var dmg: int = 1 if d <= 2 else 0
		evals.append({"move": c, "risk": risk_t, "dmg": dmg, "dist": d})

	# A 회피: risk 최소
	# B 맞받: 제자리(player_cell) 후보 — 없으면 risk 최대(가까이)
	# C 측면: 적과 직교(좌/우)하며 risk 중간인 후보
	var a: Dictionary = evals[0]
	for e in evals:
		if e.risk < a.risk:
			a = e
	var b: Variant = null
	for e in evals:
		if e.move == player_cell:
			b = e
			break
	if b == null:
		b = evals[0]
		for e in evals:
			if e.risk > b.risk:
				b = e
	# 측면: x만 다르고 y 같은 후보 중 risk 중간
	var sides: Array = []
	for e in evals:
		if e.move.y == player_cell.y and e.move.x != player_cell.x:
			sides.append(e)
	var c: Variant = null
	if sides.size() > 0:
		sides.sort_custom(func(x, y): return x.risk < y.risk)
		c = sides[sides.size() / 2]
	else:
		# 폴백: risk 중간값
		var sorted := evals.duplicate()
		sorted.sort_custom(func(x, y): return x.risk < y.risk)
		c = sorted[sorted.size() / 2]

	var make := func(tag: String, e: Dictionary, name: String) -> _Plan:
		var p := _Plan.new()
		p.tag = tag
		p.title = name
		p.move = e.move
		p.risk_true = e.risk
		p.dmg = e.dmg
		# 편향: 킬(B) 위험 과소평가. 회피(A)는 그대로, 측면(C)은 살짝.
		if tag == "B":
			p.risk_shown = round(e.risk * ATTACK_BIAS)
		elif tag == "C":
			p.risk_shown = round(e.risk * 0.85)
		else:
			p.risk_shown = round(e.risk)
		var chips: Array[String] = []
		chips.append("위험 %d%%" % int(p.risk_shown))
		chips.append("기대 타격 %d" % e.dmg)
		chips.append("거리 %d" % e.dist)
		p.chips = chips
		if deep and tag == "B":
			p.bias_note = "정정: 보정 전 위험 %d%%" % int(e.risk)
		return p

	return [
		make.call("A", a, "A · 회피"),
		make.call("B", b, "B · 맞받아치기"),
		make.call("C", c, "C · 측면"),
	]


# === ADVISOR 턴 ===
func _start_advisor_turn() -> void:
	state = State.ADVISOR
	_busy = false
	deep = false
	plans = _build_plans()
	chosen_plan = null
	top_label.text = "YOU %d   ENEMY %d" % [player_hp, enemy_hp]
	hint_label.text = "전제·작전안을 탭 / 심층 분석 사용 가능"
	_refresh_advisor_ui()


func _recommended_idx() -> int:
	# 전제(목표 함수)에 따른 추천 작전안
	match preset:
		Preset.DEFEND: return 0   # A 회피
		Preset.KILL: return 1     # B 맞받
		Preset.HOLD: return 2     # C 측면
	return 1


func _refresh_advisor_ui() -> void:
	advisor_root.visible = true
	token_label.text = "토큰 %d" % tokens
	# 전제 칩 강조
	for i in 3:
		var chip: _Chip = preset_chips[i]
		chip.active = (i == preset)
		chip.queue_redraw()
	# 심층 버튼
	if deep:
		deep_btn_label.text = "심층 적용됨 (위험 정밀 + 편향 정정)"
		deep_btn.modulate = Color(1, 1, 1, 0.6)
	elif tokens > 0:
		deep_btn_label.text = "▶ 심층 분석 사용 (토큰 -1)"
		deep_btn.modulate = Color(1, 1, 1, 1.0)
	else:
		deep_btn_label.text = "토큰 없음"
		deep_btn.modulate = Color(1, 1, 1, 0.35)
	# 작전안 박스
	var rec := _recommended_idx()
	for i in 3:
		var box: _PlanBox = plan_boxes[i]
		box.plan = plans[i]
		box.highlighted = (i == rec)
		box.deep = deep
		box.refresh()


# === 입력 ===
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("parry"):
		return
	if state == State.GAMEOVER:
		_restart()
		return
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		pos = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton:
		pos = (event as InputEventMouseButton).position
	else:
		# 키보드 스페이스 — RESOLVE 패링만 허용
		if state == State.RESOLVE:
			_try_parry()
		return

	if state == State.RESOLVE:
		_try_parry()
		return
	if state != State.ADVISOR or _busy:
		return

	# ADVISOR: UI hit-test
	for i in 3:
		var chip: _Chip = preset_chips[i]
		if chip.rect.has_point(pos):
			_on_preset_tapped(i)
			return
	if tokens > 0 and not deep:
		var drect: Rect2 = deep_btn.get_meta("rect")
		if drect.has_point(pos):
			_on_deep_tapped()
			return
	for i in 3:
		var box: _PlanBox = plan_boxes[i]
		var brect: Rect2 = box.get_meta("rect")
		if brect.has_point(pos):
			_on_plan_tapped(i)
			return


func _on_preset_tapped(i: int) -> void:
	preset = i
	SFX.play("whoosh", -14.0)
	_refresh_advisor_ui()


func _on_deep_tapped() -> void:
	tokens -= 1
	deep = true
	plans = _build_plans()
	SFX.play("good", -8.0)
	_refresh_advisor_ui()


func _on_plan_tapped(i: int) -> void:
	chosen_plan = plans[i]
	advisor_root.visible = false
	_execute_plan(chosen_plan)


# === 작전안 실행 → 적 턴 ===
func _execute_plan(plan: _Plan) -> void:
	state = State.ENEMY_TURN
	_busy = true
	hint_label.text = "%s 시전…" % plan.title
	if plan.move != player_cell:
		player_cell = plan.move
		var tw := create_tween()
		tw.tween_property(player_node, "position", tile_center(player_cell), PLAYER_MOVE_T)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		await tw.finished
	_start_enemy_phase()


func _start_enemy_phase() -> void:
	hint_label.text = "적의 턴…"
	var step := _enemy_step_toward(enemy_cell, player_cell)
	if step != enemy_cell:
		enemy_cell = step
		var tw := create_tween()
		tw.tween_property(enemy_node, "position", tile_center(enemy_cell), ENEMY_MOVE_T)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		await tw.finished
	_telegraph_then_fire()


func _telegraph_then_fire() -> void:
	var target_world := tile_center(player_cell)
	target_marker.position = target_world
	target_marker.visible = true
	target_marker.modulate.a = 1.0
	# B(맞받)는 적이 인접 → 비행 짧다(빡빡한 패링). A(회피)는 멀어 비행 길다.
	var dist := float(_manhattan(player_cell, enemy_cell))
	if dist < 1:
		dist = 1.0
	var flight := 0.30 + dist * 0.075
	hint_label.text = "표적 예고 — 타이밍을 잡아라"
	await get_tree().create_timer(TELEGRAPH).timeout
	target_marker.visible = false
	_fire_projectile(target_world, flight)


func _fire_projectile(target_world: Vector2, flight: float) -> void:
	state = State.RESOLVE
	hint_label.text = "탭 = 패링!"
	var p := GridProjectile.new()
	var from := tile_center(enemy_cell)
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
		player_node.punch()
		SFX.play("whoosh", -12.0)


func _on_parry(p: GridProjectile, perfect: bool) -> void:
	parries += 1
	var dist := _manhattan(player_cell, enemy_cell)
	var can_hit_enemy: bool = (dist <= 2)
	if perfect:
		perfects += 1
		FX.hitstop(0.09, 0.05)
		FX.shake(world, 16.0, 0.34)
		FX.flash(Color(1, 1, 1), 0.5, 0.10)
		FX.shockwave(p.position, Color(0.18, 0.95, 0.9), 210.0, 0.30)
		FX.burst(p.position, Color(0.4, 1.0, 0.95), 28, 540.0, 6.0)
		FX.burst(p.position, Color.WHITE, 10, 280.0, 4.0)
		SFX.play("perfect", -2)
		if can_hit_enemy:
			enemy_hp -= 1
			p.bounce_to(tile_center(enemy_cell), true)
			enemy_node.hit()
			_floating(tile_center(enemy_cell), "-1", COL_PERFECT, 36)
			_floating(p.position, "PERFECT!", COL_PERFECT, 44)
		else:
			# 멀어서 적 못 맞힘 — 피해만 막음
			p.vanish()
			_floating(p.position, "PERFECT 막기", COL_PERFECT, 34)
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
	for child in projectiles.get_children():
		child.queue_free()
	if player_hp <= 0 or enemy_hp <= 0:
		_game_over()
	else:
		_start_advisor_turn()


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
	tokens = START_TOKENS
	preset = Preset.KILL
	overlay.color.a = 0.0
	overlay_label.text = ""
	_start_advisor_turn()


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


# === 내부 클래스 ===
class _Plan:
	var tag := ""           # A/B/C
	var title := ""
	var move: Vector2i = Vector2i.ZERO
	var risk_true := 0.0    # 실제 위험(판정/내부용)
	var risk_shown := 0.0   # 참모 보고(편향 적용)
	var dmg := 0            # 패링 성공 시 기대 타격
	var chips: Array[String] = []
	var bias_note := ""     # 심층 시 편향 정정 문구


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
		draw_circle(Vector2.ZERO, r + 16.0 + sin(_pulse) * 2.5, Color(c.r, c.g, c.b, 0.12))
		draw_circle(Vector2.ZERO, r + 7.0, Color(c.r, c.g, c.b, 0.25))
		draw_circle(Vector2.ZERO, r, c)
		draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 44, c.lightened(0.5), 3.0)
		draw_circle(Vector2.ZERO, r * 0.4, Color(1, 1, 1, 0.9))
	func punch() -> void:
		_scale = 1.3
	func hit() -> void:
		_scale = 1.4
		_hit_flash = 1.0


class _TargetMarker extends Node2D:
	var _t := 0.0
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * 12.0)
		draw_arc(Vector2.ZERO, 52.0 + pulse * 6.0, 0.0, TAU, 40, Color(1.0, 0.32, 0.28, 0.9), 5.0)
		draw_arc(Vector2.ZERO, 70.0, 0.0, TAU, 40, Color(1.0, 0.32, 0.28, 0.3), 2.0)


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


# 전제(목표) 칩 — 토글
class _Chip extends Control:
	var label_text := ""
	var idx := 0
	var active := false
	var rect := Rect2()
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var bg := Color(0.15, 0.17, 0.27, 0.92) if not active else Color(0.16, 0.62, 0.55, 0.95)
		draw_rect(Rect2(Vector2.ZERO, size), bg, true)
		var border := COL_PANEL_HI if active else Color(1, 1, 1, 0.08)
		draw_rect(Rect2(Vector2.ZERO, size), border, false, 2.0)
		var c := Color(0.92, 0.94, 1.0) if active else Color(0.7, 0.78, 0.9)
		draw_string(_default_font(), Vector2(14, 26), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, c)
	func _default_font() -> Font:
		return get_theme_default_font()


# 작전안 박스
class _PlanBox extends Control:
	var idx := 0
	var plan: _Plan = null
	var highlighted := false
	var deep := false
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func build() -> void:
		# 자식은 _draw로 그리므로 별도 노드 불필요
		pass
	func refresh() -> void:
		queue_redraw()
	func _draw() -> void:
		if plan == null:
			return
		var bg := Color(0.20, 0.22, 0.36, 0.96) if highlighted else COL_DIM_BOX
		draw_rect(Rect2(Vector2.ZERO, size), bg, true)
		var border: Color = COL_PANEL_HI if highlighted else Color(1, 1, 1, 0.10)
		var bw := 3.0 if highlighted else 1.5
		draw_rect(Rect2(Vector2.ZERO, size), border, false, bw)
		var font := get_theme_default_font()
		# 제목
		var tc := COL_PANEL_HI if highlighted else Color(0.92, 0.94, 1.0)
		draw_string(font, Vector2(10, 22), plan.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, tc)
		# 위험% (색: 높으면 빨)
		var rc: Color = COL_RISK_HI if plan.risk_shown >= 25 else (COL_WARN if plan.risk_shown >= 15 else COL_RISK_LO)
		draw_string(font, Vector2(10, 44), "위험 %d%%" % int(plan.risk_shown), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, rc)
		# 타격
		draw_string(font, Vector2(110, 44), "타격 %d" % plan.dmg, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.85, 0.95))
		# 편향 정정(심층 시)
		if deep and plan.bias_note != "":
			draw_string(font, Vector2(10, 64), plan.bias_note, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COL_WARN)
		elif plan.tag == "B" and not deep:
			draw_string(font, Vector2(10, 64), "(심층 분석 시 정정)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.65, 0.78))
