class_name TacticsCore
extends RefCounted
## RPG GAME 01 등각 전술 전투의 순수 상태 코어.
##
## 화면 노드와 입력 장치에 의존하지 않는다. 웹 체감판과 같은 전투 규칙을
## Godot에서 재현하고, 이후 Matrix 어댑터가 주입할 데이터 경계를 만든다.

const BOARD_WIDTH := 20
const BOARD_HEIGHT := 16

const TURN_ORDER := ["aria", "lancer", "kael", "rogue", "sena", "archer", "boss"]

const UNIT_BLUEPRINTS := [
	{"id": "aria", "name": "아리아", "job": "검사", "team": "ally", "x": 2, "y": 14, "hp": 8, "max_hp": 8, "move": 4, "range": 1, "power": 3, "color": Color("#55d9ef")},
	{"id": "kael", "name": "카엘", "job": "수호기사", "team": "ally", "x": 1, "y": 15, "hp": 11, "max_hp": 11, "move": 3, "range": 1, "power": 2, "color": Color("#e8c75b")},
	{"id": "sena", "name": "세나", "job": "마도사", "team": "ally", "x": 0, "y": 14, "hp": 6, "max_hp": 6, "move": 3, "range": 4, "power": 4, "color": Color("#ec6a79")},
	{"id": "lancer", "name": "흑창병", "job": "창병", "team": "enemy", "x": 5, "y": 12, "hp": 6, "max_hp": 6, "move": 3, "range": 2, "power": 2, "color": Color("#87576b")},
	{"id": "rogue", "name": "회색 가면", "job": "척후", "team": "enemy", "x": 9, "y": 10, "hp": 5, "max_hp": 5, "move": 4, "range": 1, "power": 2, "color": Color("#9a8f99")},
	{"id": "archer", "name": "석궁병", "job": "사수", "team": "enemy", "x": 13, "y": 7, "hp": 5, "max_hp": 5, "move": 3, "range": 4, "power": 2, "color": Color("#b7635e")},
	{"id": "boss", "name": "검은 성좌", "job": "집행자", "team": "enemy", "x": 17, "y": 3, "hp": 12, "max_hp": 12, "move": 3, "range": 2, "power": 3, "color": Color("#d39b38")},
]


static func create_game() -> Dictionary:
	return {
		"units": UNIT_BLUEPRINTS.duplicate(true),
		"turn_cursor": 0,
		"round": 1,
		"phase": "move",
		"selected_action": "",
		"last_event": "부유 유적에 진입했다.",
		"advisor_trust": 0,
		"battle_ended": false,
	}


static func unit_by_id(state: Dictionary, unit_id: String) -> Dictionary:
	for unit: Dictionary in state["units"]:
		if unit["id"] == unit_id:
			return unit
	return {}


static func active_unit(state: Dictionary) -> Dictionary:
	return unit_by_id(state, TURN_ORDER[state["turn_cursor"]])


static func is_inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < BOARD_WIDTH and y < BOARD_HEIGHT


static func terrain_height(x: int, y: int) -> int:
	if x >= 14 and y <= 5:
		return 2
	if x >= 7 and y <= 12:
		return 1
	if (x == 4 or x == 5) and y >= 10 and y <= 12:
		return 1
	return 0


static func distance(a: Dictionary, b: Dictionary) -> int:
	return absi(int(a["x"]) - int(b["x"])) + absi(int(a["y"]) - int(b["y"]))


static func occupied(state: Dictionary, x: int, y: int, except_id := "") -> bool:
	for unit: Dictionary in state["units"]:
		if unit["hp"] > 0 and unit["id"] != except_id and unit["x"] == x and unit["y"] == y:
			return true
	return false


static func reachable_cells(state: Dictionary, requested_unit: Dictionary = {}) -> Array[Vector2i]:
	var unit := requested_unit if not requested_unit.is_empty() else active_unit(state)
	var out: Array[Vector2i] = []
	if unit.is_empty() or unit["hp"] <= 0:
		return out
	var start := Vector2i(unit["x"], unit["y"])
	var queue: Array[Dictionary] = [{"cell": start, "cost": 0}]
	var best := {start: 0}
	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var cell: Vector2i = current["cell"]
		out.append(cell)
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var next_cell: Vector2i = cell + direction
			if not is_inside(next_cell.x, next_cell.y):
				continue
			if occupied(state, next_cell.x, next_cell.y, unit["id"]):
				continue
			var height_cost: int = absi(terrain_height(next_cell.x, next_cell.y) - terrain_height(cell.x, cell.y))
			if height_cost > 1:
				continue
			var cost: int = current["cost"] + 1 + height_cost
			if cost <= unit["move"] and (not best.has(next_cell) or cost < best[next_cell]):
				best[next_cell] = cost
				queue.append({"cell": next_cell, "cost": cost})
	return out


static func move_active_unit(state: Dictionary, destination: Vector2i) -> Dictionary:
	if state["phase"] != "move" or destination not in reachable_cells(state):
		return state
	var next := state.duplicate(true)
	var actor := active_unit(next)
	actor["x"] = destination.x
	actor["y"] = destination.y
	next["phase"] = "action"
	next["last_event"] = "%s 이동 완료." % actor["name"]
	return next


static func targetable_enemies(state: Dictionary, requested_action := "") -> Array[Dictionary]:
	var actor := active_unit(state)
	var action: String = requested_action if requested_action != "" else state["selected_action"]
	var attack_range: int = maxi(3, actor["range"]) if action == "skill" else actor["range"]
	var targets: Array[Dictionary] = []
	for unit: Dictionary in state["units"]:
		if unit["hp"] > 0 and unit["team"] != actor["team"] and distance(actor, unit) <= attack_range:
			targets.append(unit)
	return targets


static func select_action(state: Dictionary, action: String) -> Dictionary:
	if state["phase"] != "action" or action not in ["attack", "skill", "wait"]:
		return state
	var next := state.duplicate(true)
	if action == "wait":
		next["last_event"] = "%s 대기." % active_unit(next)["name"]
		return end_turn(next)
	next["phase"] = "target"
	next["selected_action"] = action
	return next


static func resolve_player_attack(state: Dictionary, target_id: String) -> Dictionary:
	if state["phase"] != "target":
		return state
	var target: Dictionary = {}
	for candidate: Dictionary in targetable_enemies(state):
		if candidate["id"] == target_id:
			target = candidate
			break
	if target.is_empty():
		return state
	var next := state.duplicate(true)
	var actor := active_unit(next)
	var next_target := unit_by_id(next, target_id)
	var damage: int = actor["power"] + 2 if next["selected_action"] == "skill" else actor["power"]
	var action_name := "공명참" if next["selected_action"] == "skill" else "공격"
	next_target["hp"] = maxi(0, next_target["hp"] - damage)
	next["last_event"] = "%s의 %s! %s에게 %d 피해." % [actor["name"], action_name, next_target["name"], damage]
	next["selected_action"] = ""
	return end_turn(check_battle_end(next))


static func enemy_intent(state: Dictionary) -> Dictionary:
	var enemy := active_unit(state)
	if enemy.is_empty() or enemy["team"] != "enemy":
		return {}
	var allies: Array[Dictionary] = []
	for unit: Dictionary in state["units"]:
		if unit["team"] == "ally" and unit["hp"] > 0:
			allies.append(unit)
	allies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return distance(enemy, a) < distance(enemy, b))
	var target: Dictionary = allies[0]
	var direction := "좌측" if target["x"] < enemy["x"] else ("우측" if target["x"] > enemy["x"] else "정면")
	return {
		"enemy_id": enemy["id"],
		"target_id": target["id"],
		"confidence": 57 if enemy["id"] == "boss" else 72,
		"direction": direction,
		"evidence": "검끝 고정 · 마력 역류" if enemy["id"] == "boss" else "체중 이동 · 시선 고정",
	}


static func begin_enemy_turn(state: Dictionary) -> Dictionary:
	if active_unit(state).get("team", "") != "enemy":
		return state
	var next := state.duplicate(true)
	_move_enemy_toward_nearest(next)
	var enemy := active_unit(next)
	var targets := targetable_enemies(next, "attack")
	if targets.is_empty():
		next["last_event"] = "%s이 전장을 가로질러 전진했다." % enemy["name"]
		return end_turn(next)
	next["phase"] = "enemy_predict"
	next["last_event"] = "%s이 자세를 낮춘다." % enemy["name"]
	return next


static func _move_enemy_toward_nearest(state: Dictionary) -> void:
	var enemy := active_unit(state)
	var allies: Array[Dictionary] = []
	for unit: Dictionary in state["units"]:
		if unit["team"] == "ally" and unit["hp"] > 0:
			allies.append(unit)
	if allies.is_empty():
		return
	allies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return distance(enemy, a) < distance(enemy, b))
	var target := allies[0]
	if distance(enemy, target) <= enemy["range"]:
		return
	var candidates := reachable_cells(state, enemy)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var distance_a := absi(a.x - int(target["x"])) + absi(a.y - int(target["y"]))
		var distance_b := absi(b.x - int(target["x"])) + absi(b.y - int(target["y"]))
		return distance_a < distance_b
	)
	if candidates.is_empty():
		return
	var destination: Vector2i = candidates[0]
	enemy["x"] = destination.x
	enemy["y"] = destination.y


static func begin_reaction(state: Dictionary) -> Dictionary:
	if state["phase"] != "enemy_predict":
		return state
	var next := state.duplicate(true)
	next["phase"] = "reaction"
	return next


static func resolve_reaction(state: Dictionary, grade: String) -> Dictionary:
	if state["phase"] != "reaction" or grade not in ["perfect", "good", "miss"]:
		return state
	var next := state.duplicate(true)
	var intent := enemy_intent(next)
	var enemy := unit_by_id(next, intent["enemy_id"])
	var target := unit_by_id(next, intent["target_id"])
	var damage: int = 0 if grade == "perfect" else (1 if grade == "good" else enemy["power"])
	var label := "PERFECT · 반격" if grade == "perfect" else ("GUARD · 피해 경감" if grade == "good" else "HIT · 예측 실패")
	target["hp"] = maxi(0, target["hp"] - damage)
	if grade == "perfect":
		enemy["hp"] = maxi(0, enemy["hp"] - 1)
	next["advisor_trust"] += 1 if grade == "perfect" else (-1 if grade == "miss" else 0)
	next["last_event"] = "%s. %s 피해 %d." % [label, target["name"], damage]
	return end_turn(check_battle_end(next))


static func end_turn(state: Dictionary) -> Dictionary:
	if state["battle_ended"]:
		return state
	var next := state.duplicate(true)
	var cursor: int = next["turn_cursor"]
	var round_number: int = next["round"]
	for _step in TURN_ORDER.size():
		cursor = (cursor + 1) % TURN_ORDER.size()
		if cursor == 0:
			round_number += 1
		var candidate := unit_by_id(next, TURN_ORDER[cursor])
		if not candidate.is_empty() and candidate["hp"] > 0:
			next["turn_cursor"] = cursor
			next["round"] = round_number
			next["phase"] = "enemy_ready" if candidate["team"] == "enemy" else "move"
			next["selected_action"] = ""
			return next
	return check_battle_end(next)


static func check_battle_end(state: Dictionary) -> Dictionary:
	var allies_alive := false
	var enemies_alive := false
	for unit: Dictionary in state["units"]:
		if unit["hp"] <= 0:
			continue
		allies_alive = allies_alive or unit["team"] == "ally"
		enemies_alive = enemies_alive or unit["team"] == "enemy"
	if allies_alive and enemies_alive:
		return state
	var next := state.duplicate(true)
	next["battle_ended"] = true
	next["phase"] = "ending"
	next["last_event"] = "부유 유적의 봉인이 해제됐다." if allies_alive else "파편이 다시 어둠 속으로 가라앉았다."
	return next
