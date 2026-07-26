extends Node2D
## 파랜드풍 등각 전술 전투 Godot 세로 조각.
##
## TacticsCore는 규칙만 소유하고, 이 노드는 표시와 입력만 담당한다.

const Core = preload("res://modules/tactics/tactics_core.gd")

const VIEW_SIZE := Vector2(1280, 720)
const BOARD_RIGHT := 952.0
const TILE_WIDTH := 88.0
const TILE_HEIGHT := 44.0
const HEIGHT_STEP := 20.0
const BOARD_ORIGIN := Vector2(470, 135)
const REACTION_DURATION := 3.0
const PERFECT_START := 1.05
const PERFECT_END := 1.85
const GOOD_END := 2.5

const COLOR_BG := Color("#090b12")
const COLOR_PANEL := Color("#171a26")
const COLOR_GOLD := Color("#d5b56d")
const COLOR_TEXT := Color("#e9e4d8")
const COLOR_MUTED := Color("#9397a7")
const COLOR_CYAN := Color("#62d9e8")
const COLOR_RED := Color("#e06368")

var state: Dictionary = Core.create_game()
var reaction_elapsed := 0.0
var hovered_cell := Vector2i(-1, -1)

var round_label: Label
var actor_label: Label
var actor_job_label: Label
var hp_label: Label
var command_hint: Label
var battle_log: Label
var advisor_copy: Label
var timeline_label: Label
var attack_button: Button
var skill_button: Button
var wait_button: Button
var enemy_button: Button
var prepare_button: Button
var parry_button: Button
var restart_button: Button
var reaction_meter: ProgressBar


func _ready() -> void:
	get_window().title = "RPG GAME 01 · 파랜드풍 전술 코어"
	_build_interface()
	_refresh()


func _process(delta: float) -> void:
	if state["phase"] != "reaction":
		return
	reaction_elapsed += delta
	reaction_meter.value = reaction_elapsed
	queue_redraw()
	if reaction_elapsed >= REACTION_DURATION:
		_finish_reaction("miss")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hovered_cell = _cell_at_screen(event.position)
		queue_redraw()
		return
	if event.is_action_pressed("parry") and state["phase"] == "reaction":
		_finish_reaction()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := _cell_at_screen(event.position)
		if cell.x >= 0:
			_handle_board_click(cell)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(BOARD_RIGHT, VIEW_SIZE.y)), COLOR_BG)
	_draw_atmosphere()
	_draw_board()
	_draw_units()
	if state["phase"] == "reaction":
		_draw_reaction_focus()


func _draw_atmosphere() -> void:
	for i in 18:
		var seed_x := float((i * 137) % 900)
		var seed_y := float((i * 79) % 620)
		var alpha := 0.12 + float(i % 4) * 0.04
		draw_circle(Vector2(seed_x, seed_y), 1.2 + float(i % 2), Color(0.62, 0.76, 0.92, alpha))
	draw_circle(Vector2(120, 205), 150, Color(0.23, 0.18, 0.25, 0.18))
	draw_circle(Vector2(790, 145), 210, Color(0.12, 0.22, 0.30, 0.16))
	draw_string(ThemeDB.fallback_font, Vector2(28, 32), "CHAPTER 01", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_GOLD)
	draw_string(ThemeDB.fallback_font, Vector2(28, 60), "하늘에 남은 문", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, COLOR_TEXT)


func _draw_board() -> void:
	var move_cells: Array[Vector2i] = []
	if state["phase"] == "move" and Core.active_unit(state).get("team", "") == "ally":
		move_cells = Core.reachable_cells(state)
	var target_ids: Array[String] = []
	if state["phase"] == "target":
		for unit: Dictionary in Core.targetable_enemies(state):
			target_ids.append(unit["id"])

	for depth in range((Core.BOARD_SIZE - 1) * 2 + 1):
		for y in Core.BOARD_SIZE:
			var x := depth - y
			if x < 0 or x >= Core.BOARD_SIZE:
				continue
			var cell := Vector2i(x, y)
			var height: int = Core.TERRAIN[y][x]
			var center := _cell_to_screen(cell)
			var extrusion := float(height) * HEIGHT_STEP
			var left := center + Vector2(-TILE_WIDTH * 0.5, 0)
			var right := center + Vector2(TILE_WIDTH * 0.5, 0)
			var bottom := center + Vector2(0, TILE_HEIGHT * 0.5)
			if extrusion > 0:
				draw_colored_polygon(PackedVector2Array([
					left, bottom, bottom + Vector2(0, extrusion), left + Vector2(0, extrusion)
				]), Color("#252a32"))
				draw_colored_polygon(PackedVector2Array([
					right, bottom, bottom + Vector2(0, extrusion), right + Vector2(0, extrusion)
				]), Color("#343943"))
			var top_color: Color = [Color("#5b5d59"), Color("#68665d"), Color("#777064")][height]
			if cell in move_cells:
				top_color = top_color.lerp(COLOR_CYAN, 0.48)
			elif _unit_id_at(cell) in target_ids:
				top_color = top_color.lerp(COLOR_RED, 0.55)
			elif cell == hovered_cell:
				top_color = top_color.lightened(0.14)
			var diamond := _diamond(center)
			draw_colored_polygon(diamond, top_color)
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(1, 1, 1, 0.15), 1.0)
			if height >= 1:
				draw_circle(center, 2.2, Color(COLOR_GOLD, 0.55))


func _draw_units() -> void:
	var units: Array[Dictionary] = []
	for unit: Dictionary in state["units"]:
		if unit["hp"] > 0:
			units.append(unit)
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var depth_a: int = a["x"] + a["y"]
		var depth_b: int = b["x"] + b["y"]
		return depth_a < depth_b if depth_a != depth_b else a["x"] < b["x"]
	)
	var active_id: String = Core.active_unit(state).get("id", "")
	var target_ids: Array[String] = []
	if state["phase"] == "target":
		for target: Dictionary in Core.targetable_enemies(state):
			target_ids.append(target["id"])
	for unit in units:
		var cell := Vector2i(unit["x"], unit["y"])
		var base := _cell_to_screen(cell) + Vector2(0, -8)
		var is_active: bool = unit["id"] == active_id
		var is_target: bool = unit["id"] in target_ids
		draw_set_transform(base + Vector2(0, 8), 0.0, Vector2(1.4, 0.42))
		draw_circle(Vector2.ZERO, 17, Color(0, 0, 0, 0.45))
		draw_set_transform(Vector2.ZERO)
		if is_active:
			draw_arc(base + Vector2(0, 5), 28, 0, TAU, 40, COLOR_GOLD, 3)
		if is_target:
			draw_arc(base + Vector2(0, 5), 31, 0, TAU, 40, COLOR_RED, 4)
		var unit_color: Color = unit["color"]
		var cape := PackedVector2Array([
			base + Vector2(-17, 2), base + Vector2(17, 2),
			base + Vector2(13, 33), base + Vector2(-15, 33)
		])
		draw_colored_polygon(cape, unit_color.darkened(0.22))
		draw_circle(base + Vector2(0, -7), 13, unit_color.lightened(0.18))
		draw_rect(Rect2(base + Vector2(-19, 33), Vector2(38, 5)), Color("#090a0e"))
		var hp_ratio: float = float(unit["hp"]) / float(unit["max_hp"])
		draw_rect(Rect2(base + Vector2(-18, 34), Vector2(36 * hp_ratio, 3)), Color("#6ee18a") if unit["team"] == "ally" else COLOR_RED)
		var name_color := COLOR_CYAN if unit["team"] == "ally" else Color("#f2a2a2")
		draw_string(ThemeDB.fallback_font, base + Vector2(-36, -29), unit["name"], HORIZONTAL_ALIGNMENT_CENTER, 72, 12, name_color)


func _draw_reaction_focus() -> void:
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	var color := Color(COLOR_CYAN, 0.12 + pulse * 0.08)
	draw_circle(Vector2(470, 360), 150 + pulse * 18, color)


func _build_interface() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var side := ColorRect.new()
	side.position = Vector2(BOARD_RIGHT, 0)
	side.size = Vector2(VIEW_SIZE.x - BOARD_RIGHT, VIEW_SIZE.y)
	side.color = COLOR_PANEL
	layer.add_child(side)

	var divider := ColorRect.new()
	divider.position = Vector2(BOARD_RIGHT, 0)
	divider.size = Vector2(1, VIEW_SIZE.y)
	divider.color = Color(COLOR_GOLD, 0.35)
	layer.add_child(divider)

	round_label = _label(layer, Vector2(980, 24), Vector2(270, 24), 13, COLOR_GOLD)
	actor_label = _label(layer, Vector2(980, 64), Vector2(270, 42), 29, COLOR_TEXT)
	actor_job_label = _label(layer, Vector2(980, 106), Vector2(270, 24), 14, COLOR_MUTED)
	hp_label = _label(layer, Vector2(980, 142), Vector2(270, 28), 15, Color("#aee9b5"))

	var line_one := ColorRect.new()
	line_one.position = Vector2(976, 183)
	line_one.size = Vector2(280, 1)
	line_one.color = Color(1, 1, 1, 0.13)
	layer.add_child(line_one)

	_label(layer, Vector2(980, 202), Vector2(270, 20), 12, COLOR_GOLD).text = "명령"
	command_hint = _label(layer, Vector2(980, 230), Vector2(270, 54), 14, COLOR_MUTED)
	command_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	attack_button = _button(layer, "공격", Vector2(980, 298), Vector2(128, 42), _on_attack)
	skill_button = _button(layer, "기술 · 공명참", Vector2(1118, 298), Vector2(136, 42), _on_skill)
	wait_button = _button(layer, "대기", Vector2(980, 349), Vector2(274, 40), _on_wait)
	enemy_button = _button(layer, "적의 턴 진행", Vector2(980, 298), Vector2(274, 46), _on_enemy_turn)
	prepare_button = _button(layer, "예측을 읽고 대비", Vector2(980, 298), Vector2(274, 46), _on_prepare)

	reaction_meter = ProgressBar.new()
	reaction_meter.position = Vector2(980, 296)
	reaction_meter.size = Vector2(274, 16)
	reaction_meter.min_value = 0
	reaction_meter.max_value = REACTION_DURATION
	reaction_meter.show_percentage = false
	layer.add_child(reaction_meter)
	parry_button = _button(layer, "지금!  패링", Vector2(1010, 329), Vector2(214, 62), _on_parry)

	var line_two := ColorRect.new()
	line_two.position = Vector2(976, 420)
	line_two.size = Vector2(280, 1)
	line_two.color = Color(1, 1, 1, 0.13)
	layer.add_child(line_two)
	_label(layer, Vector2(980, 438), Vector2(270, 20), 12, COLOR_GOLD).text = "전황"
	battle_log = _label(layer, Vector2(980, 466), Vector2(270, 78), 14, COLOR_TEXT)
	battle_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(layer, Vector2(980, 560), Vector2(270, 20), 12, COLOR_GOLD).text = "TURN ORDER"
	timeline_label = _label(layer, Vector2(980, 587), Vector2(270, 58), 12, COLOR_MUTED)
	timeline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restart_button = _button(layer, "전투 재시작", Vector2(980, 661), Vector2(274, 36), _on_restart)

	var advisor_panel := ColorRect.new()
	advisor_panel.position = Vector2(28, 612)
	advisor_panel.size = Vector2(890, 82)
	advisor_panel.color = Color("#111621")
	layer.add_child(advisor_panel)
	var advisor_accent := ColorRect.new()
	advisor_accent.position = Vector2(28, 612)
	advisor_accent.size = Vector2(4, 82)
	advisor_accent.color = COLOR_CYAN
	layer.add_child(advisor_accent)
	_label(layer, Vector2(50, 623), Vector2(850, 18), 11, COLOR_CYAN).text = "전술 안내자 MIRA"
	advisor_copy = _label(layer, Vector2(50, 648), Vector2(840, 38), 15, COLOR_TEXT)
	advisor_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _refresh() -> void:
	var actor := Core.active_unit(state)
	round_label.text = "ROUND %d  ·  목표: 검은 성좌 격파" % state["round"]
	actor_label.text = actor.get("name", "전투 종료")
	actor_job_label.text = actor.get("job", "")
	hp_label.text = "HP %d / %d" % [actor.get("hp", 0), actor.get("max_hp", 0)]
	battle_log.text = state["last_event"]

	var order_names: Array[String] = []
	for unit_id in Core.TURN_ORDER:
		var unit := Core.unit_by_id(state, unit_id)
		if unit["hp"] <= 0:
			continue
		order_names.append("▶ %s" % unit["name"] if unit_id == actor.get("id", "") else unit["name"])
	timeline_label.text = "  ·  ".join(order_names)

	var phase: String = state["phase"]
	attack_button.visible = phase == "action"
	skill_button.visible = phase == "action"
	wait_button.visible = phase == "action"
	enemy_button.visible = phase == "enemy_ready"
	prepare_button.visible = phase == "enemy_predict"
	parry_button.visible = phase == "reaction"
	reaction_meter.visible = phase == "reaction"
	attack_button.disabled = phase == "action" and Core.targetable_enemies(state, "attack").is_empty()
	skill_button.disabled = phase == "action" and Core.targetable_enemies(state, "skill").is_empty()

	match phase:
		"move":
			command_hint.text = "청록색 타일 중 이동할 위치를 선택하세요. 고저차는 이동력을 더 소모합니다."
			advisor_copy.text = "%s의 이동 경로를 표시했습니다." % actor["name"]
		"action":
			command_hint.text = "공격, 기술 또는 대기를 선택하세요."
			advisor_copy.text = "높은 지형과 적의 사거리를 함께 읽으세요."
		"target":
			command_hint.text = "붉게 표시된 적을 전장에서 선택하세요."
			advisor_copy.text = "선택한 행동의 유효 대상만 표시했습니다."
		"enemy_ready":
			command_hint.text = "적이 움직이기 전에 MIRA의 예측을 확인합니다."
			advisor_copy.text = "%s의 공격 징후를 분석 중입니다." % actor["name"]
		"enemy_predict":
			var intent := Core.enemy_intent(state)
			var target := Core.unit_by_id(state, intent["target_id"])
			command_hint.text = "예측은 정답이 아니라 반응할 준비를 줍니다."
			advisor_copy.text = "%s 대상 %s 공격 %d%% · 근거: %s" % [target["name"], intent["direction"], intent["confidence"], intent["evidence"]]
		"reaction":
			command_hint.text = "흰 표식이 청록 구간에 들어올 때 패링!"
			advisor_copy.text = "Space 또는 패링 버튼으로 반응하세요."
		"ending":
			command_hint.text = "전투가 끝났습니다."
			advisor_copy.text = state["last_event"]
	queue_redraw()


func _handle_board_click(cell: Vector2i) -> void:
	match state["phase"]:
		"move":
			var next := Core.move_active_unit(state, cell)
			if next != state:
				state = next
				_refresh()
		"target":
			var target_id := _unit_id_at(cell)
			if target_id != "":
				var next := Core.resolve_player_attack(state, target_id)
				if next != state:
					state = next
					_refresh()


func _on_attack() -> void:
	state = Core.select_action(state, "attack")
	_refresh()


func _on_skill() -> void:
	state = Core.select_action(state, "skill")
	_refresh()


func _on_wait() -> void:
	state = Core.select_action(state, "wait")
	_refresh()


func _on_enemy_turn() -> void:
	state = Core.begin_enemy_turn(state)
	_refresh()


func _on_prepare() -> void:
	state = Core.begin_reaction(state)
	reaction_elapsed = 0.0
	reaction_meter.value = 0
	_refresh()


func _on_parry() -> void:
	_finish_reaction()


func _finish_reaction(forced_grade := "") -> void:
	if state["phase"] != "reaction":
		return
	var grade: String = forced_grade
	if grade == "":
		grade = "perfect" if reaction_elapsed >= PERFECT_START and reaction_elapsed <= PERFECT_END else ("good" if reaction_elapsed < GOOD_END else "miss")
	state = Core.resolve_reaction(state, grade)
	_refresh()


func _on_restart() -> void:
	state = Core.create_game()
	reaction_elapsed = 0.0
	_refresh()


func _cell_to_screen(cell: Vector2i) -> Vector2:
	var height: int = Core.TERRAIN[cell.y][cell.x]
	return BOARD_ORIGIN + Vector2(
		float(cell.x - cell.y) * TILE_WIDTH * 0.5,
		float(cell.x + cell.y) * TILE_HEIGHT * 0.5 - float(height) * HEIGHT_STEP
	)


func _cell_at_screen(screen_point: Vector2) -> Vector2i:
	for depth in range((Core.BOARD_SIZE - 1) * 2, -1, -1):
		for y in range(Core.BOARD_SIZE - 1, -1, -1):
			var x := depth - y
			if x < 0 or x >= Core.BOARD_SIZE:
				continue
			var cell := Vector2i(x, y)
			if Geometry2D.is_point_in_polygon(screen_point, _diamond(_cell_to_screen(cell))):
				return cell
	return Vector2i(-1, -1)


func _diamond(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0, -TILE_HEIGHT * 0.5),
		center + Vector2(TILE_WIDTH * 0.5, 0),
		center + Vector2(0, TILE_HEIGHT * 0.5),
		center + Vector2(-TILE_WIDTH * 0.5, 0),
	])


func _unit_id_at(cell: Vector2i) -> String:
	for unit: Dictionary in state["units"]:
		if unit["hp"] > 0 and unit["x"] == cell.x and unit["y"] == cell.y:
			return unit["id"]
	return ""


func _label(parent: Node, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, position: Vector2, size: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
