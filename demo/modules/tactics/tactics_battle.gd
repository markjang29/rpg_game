extends Node2D
## 파랜드풍 등각 전술 전투 Godot 세로 조각.
##
## TacticsCore는 규칙만 소유하고, 이 노드는 표시와 입력만 담당한다.

const Core = preload("res://modules/tactics/tactics_core.gd")
const Director = preload("res://modules/tactics/battle_director.gd")
const Scenario = preload("res://modules/tactics/battle_scenario.gd")
const FONT_SOURCE = preload("res://assets/fonts/NotoSansKR-Variable.ttf")
const PORTRAIT_TEXTURES := {
	"aria": preload("res://assets/tactics/chapter01/aria-portrait.png"),
	"kael": preload("res://assets/tactics/chapter01/kael-portrait.png"),
	"sena": preload("res://assets/tactics/chapter01/sena-portrait.png"),
}
const UNIT_TEXTURES := {
	"aria": preload("res://assets/tactics/chapter01/aria-unit.png"),
	"kael": preload("res://assets/tactics/chapter01/kael-unit.png"),
	"sena": preload("res://assets/tactics/chapter01/sena-unit.png"),
	"lancer": preload("res://assets/tactics/chapter01/lancer-unit.png"),
	"rogue": preload("res://assets/tactics/chapter01/rogue-unit.png"),
	"archer": preload("res://assets/tactics/chapter01/archer-unit.png"),
	"boss": preload("res://assets/tactics/chapter01/boss-unit.png"),
}

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

const COLOR_BG := Color("#173153")
const COLOR_PANEL := Color("#15243d")
const COLOR_GOLD := Color("#f2ce68")
const COLOR_TEXT := Color("#fff8e7")
const COLOR_MUTED := Color("#b7c7dc")
const COLOR_CYAN := Color("#65e4ee")
const COLOR_RED := Color("#f26c6f")

var state: Dictionary = Core.create_game()
var director = Director.new()
var reaction_elapsed := 0.0
var hovered_cell := Vector2i(-1, -1)
var ui_font: FontVariation
var visual_offsets: Dictionary = {}
var damage_popup := ""
var damage_popup_position := Vector2.ZERO
var damage_popup_alpha := 0.0
var impact_flash := 0.0

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
var dialogue_shade: ColorRect
var dialogue_panel: ColorRect
var dialogue_portrait: TextureRect
var dialogue_speaker: Label
var dialogue_role: Label
var dialogue_text: Label
var dialogue_next_button: Button


func _ready() -> void:
	get_window().title = "RPG GAME 01 · 파랜드풍 전술 코어"
	ui_font = FontVariation.new()
	ui_font.base_font = FONT_SOURCE
	ui_font.variation_opentype = {"wght": 520}
	_build_interface()
	director.start(Scenario.chapter_01())
	_show_dialogue()
	_refresh()


func _process(delta: float) -> void:
	if impact_flash > 0.0:
		impact_flash = maxf(0.0, impact_flash - delta * 5.0)
		queue_redraw()
	if state["phase"] != "reaction":
		return
	reaction_elapsed += delta
	reaction_meter.value = reaction_elapsed
	queue_redraw()
	if reaction_elapsed >= REACTION_DURATION:
		_finish_reaction("miss")


func _unhandled_input(event: InputEvent) -> void:
	if director.is_dialogue_active():
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			_on_dialogue_next()
			get_viewport().set_input_as_handled()
		return
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
	_draw_damage_popup()
	if impact_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(BOARD_RIGHT, VIEW_SIZE.y)), Color(1.0, 0.94, 0.67, impact_flash * 0.18))
	if state["phase"] == "reaction":
		_draw_reaction_focus()


func _draw_atmosphere() -> void:
	for i in 24:
		var seed_x := float((i * 137) % 900)
		var seed_y := float((i * 79) % 620)
		var alpha := 0.15 + float(i % 4) * 0.04
		draw_circle(Vector2(seed_x, seed_y), 1.5 + float(i % 2), Color(0.92, 0.96, 1.0, alpha))
	draw_circle(Vector2(120, 205), 170, Color(0.50, 0.72, 0.92, 0.12))
	draw_circle(Vector2(790, 145), 230, Color(0.31, 0.62, 0.76, 0.10))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 520), Vector2(220, 390), Vector2(430, 520),
		Vector2(650, 380), Vector2(952, 535), Vector2(952, 720), Vector2(0, 720),
	]), Color("#11243c"))
	draw_string(ui_font, Vector2(28, 32), "CHAPTER 01", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_GOLD)
	draw_string(ui_font, Vector2(28, 60), "하늘에 남은 문", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, COLOR_TEXT)


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
				]), Color("#40545b"))
				draw_colored_polygon(PackedVector2Array([
					right, bottom, bottom + Vector2(0, extrusion), right + Vector2(0, extrusion)
				]), Color("#566c68"))
			var top_color: Color = [Color("#789477"), Color("#91a57e"), Color("#b6aa7f")][height]
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
		var offset: Vector2 = visual_offsets.get(unit["id"], Vector2.ZERO)
		var base := _cell_to_screen(cell) + Vector2(0, -8) + offset
		var is_active: bool = unit["id"] == active_id
		var is_target: bool = unit["id"] in target_ids
		draw_set_transform(base + Vector2(0, 8), 0.0, Vector2(1.4, 0.42))
		draw_circle(Vector2.ZERO, 17, Color(0, 0, 0, 0.45))
		draw_set_transform(Vector2.ZERO)
		if is_active:
			draw_arc(base + Vector2(0, 5), 28, 0, TAU, 40, COLOR_GOLD, 3)
		if is_target:
			draw_arc(base + Vector2(0, 5), 31, 0, TAU, 40, COLOR_RED, 4)
		var unit_texture: Texture2D = UNIT_TEXTURES.get(unit["id"])
		if unit_texture:
			var sprite_size := 128.0 if unit["id"] == "boss" else 112.0
			draw_texture_rect(
				unit_texture,
				Rect2(base + Vector2(-sprite_size * 0.5, 34.0 - sprite_size), Vector2(sprite_size, sprite_size)),
				false
			)
		draw_rect(Rect2(base + Vector2(-19, 33), Vector2(38, 5)), Color("#090a0e"))
		var hp_ratio: float = float(unit["hp"]) / float(unit["max_hp"])
		draw_rect(Rect2(base + Vector2(-18, 34), Vector2(36 * hp_ratio, 3)), Color("#6ee18a") if unit["team"] == "ally" else COLOR_RED)
		var name_color := COLOR_CYAN if unit["team"] == "ally" else Color("#f2a2a2")
		draw_string(ui_font, base + Vector2(-36, -29), unit["name"], HORIZONTAL_ALIGNMENT_CENTER, 72, 12, name_color)


func _draw_damage_popup() -> void:
	if damage_popup == "" or damage_popup_alpha <= 0.0:
		return
	var color := Color(1.0, 0.91, 0.48, damage_popup_alpha)
	draw_string(
		ui_font,
		damage_popup_position,
		damage_popup,
		HORIZONTAL_ALIGNMENT_CENTER,
		120,
		24,
		color
	)


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

	dialogue_shade = ColorRect.new()
	dialogue_shade.position = Vector2.ZERO
	dialogue_shade.size = VIEW_SIZE
	dialogue_shade.color = Color(0.03, 0.07, 0.14, 0.42)
	dialogue_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dialogue_shade)

	dialogue_panel = ColorRect.new()
	dialogue_panel.position = Vector2(38, 438)
	dialogue_panel.size = Vector2(1204, 238)
	dialogue_panel.color = Color("#101b32e8")
	dialogue_shade.add_child(dialogue_panel)

	var dialogue_border := ColorRect.new()
	dialogue_border.position = Vector2(0, 0)
	dialogue_border.size = Vector2(8, 238)
	dialogue_border.color = COLOR_GOLD
	dialogue_panel.add_child(dialogue_border)

	dialogue_portrait = TextureRect.new()
	dialogue_portrait.position = Vector2(30, -242)
	dialogue_portrait.size = Vector2(300, 460)
	dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_panel.add_child(dialogue_portrait)

	dialogue_speaker = _label(dialogue_panel, Vector2(338, 24), Vector2(530, 42), 27, COLOR_TEXT)
	dialogue_role = _label(dialogue_panel, Vector2(340, 66), Vector2(520, 24), 13, COLOR_GOLD)
	dialogue_text = _label(dialogue_panel, Vector2(340, 104), Vector2(790, 84), 18, COLOR_TEXT)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_next_button = _button(dialogue_panel, "계속  ▶", Vector2(966, 174), Vector2(200, 42), _on_dialogue_next)


func _refresh() -> void:
	var actor := Core.active_unit(state)
	var objective: String = director.scenario.get("objective", "검은 성좌 격파")
	round_label.text = "ROUND %d  ·  목표: %s" % [state["round"], objective]
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
			var actor_before := Core.active_unit(state).duplicate(true)
			var next := Core.move_active_unit(state, cell)
			if next != state:
				state = next
				var actor_after := Core.active_unit(state)
				var from_position := _cell_to_screen(Vector2i(actor_before["x"], actor_before["y"]))
				var to_position := _cell_to_screen(Vector2i(actor_after["x"], actor_after["y"]))
				_animate_movement(actor_after["id"], from_position - to_position)
				_refresh()
		"target":
			var target_id := _unit_id_at(cell)
			if target_id != "":
				var hp_before: int = Core.unit_by_id(state, target_id).get("hp", 0)
				var next := Core.resolve_player_attack(state, target_id)
				if next != state:
					state = next
					var hp_after: int = Core.unit_by_id(state, target_id).get("hp", 0)
					_animate_hit(target_id, hp_before - hp_after)
					_refresh()
					_observe_story()


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
	_observe_story()


func _on_restart() -> void:
	state = Core.create_game()
	reaction_elapsed = 0.0
	visual_offsets.clear()
	damage_popup = ""
	director.start(Scenario.chapter_01())
	_show_dialogue()
	_refresh()


func _on_dialogue_next() -> void:
	var result := director.advance_dialogue()
	if result == "line":
		_show_dialogue()
		return
	dialogue_shade.visible = director.is_dialogue_active()
	if result == "battle":
		_refresh()


func _show_dialogue() -> void:
	var line := director.current_line()
	dialogue_shade.visible = not line.is_empty()
	if line.is_empty():
		return
	var speaker_id: String = line.get("speaker_id", "")
	dialogue_portrait.texture = PORTRAIT_TEXTURES.get(speaker_id)
	dialogue_speaker.text = line.get("speaker", "")
	dialogue_role.text = line.get("role", "")
	dialogue_text.text = line.get("text", "")
	var is_last_line: bool = director.dialogue_index == director.dialogue_lines.size() - 1
	if is_last_line and director.return_phase == "battle":
		dialogue_next_button.text = "전투 시작  ▶" if director.triggered.is_empty() else "전투 복귀  ▶"
	elif is_last_line and director.return_phase == "complete":
		dialogue_next_button.text = "챕터 완료  ◆"
	else:
		dialogue_next_button.text = "계속  ▶"


func _observe_story() -> void:
	if director.observe_battle(state):
		_show_dialogue()


func _animate_movement(unit_id: String, starting_offset: Vector2) -> void:
	visual_offsets[unit_id] = starting_offset
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(weight: float) -> void:
			visual_offsets[unit_id] = starting_offset.lerp(Vector2.ZERO, weight)
			queue_redraw(),
		0.0,
		1.0,
		0.34
	)
	tween.finished.connect(func() -> void:
		visual_offsets.erase(unit_id)
		queue_redraw()
	)


func _animate_hit(target_id: String, damage: int) -> void:
	if damage <= 0:
		return
	var target := Core.unit_by_id(state, target_id)
	if target.is_empty():
		return
	var popup_start := _cell_to_screen(Vector2i(target["x"], target["y"])) + Vector2(-60, -68)
	damage_popup = "-%d" % damage
	damage_popup_position = popup_start
	damage_popup_alpha = 1.0
	impact_flash = 1.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(weight: float) -> void:
			damage_popup_alpha = 1.0 - weight
			damage_popup_position = popup_start + Vector2(0, -34.0 * weight)
			queue_redraw(),
		0.0,
		1.0,
		0.72
	)
	tween.finished.connect(func() -> void:
		damage_popup = ""
		queue_redraw()
	)


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
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, position: Vector2, size: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.add_theme_font_override("font", ui_font)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
