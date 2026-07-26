extends SceneTree
## CLI: godot --headless --path demo --script res://tests/tactics_core_test.gd

const Core = preload("res://modules/tactics/tactics_core.gd")

var assertions := 0


func _init() -> void:
	var state: Dictionary = Core.create_game()
	check(Core.active_unit(state)["id"] == "aria", "첫 행동자는 아리아")
	check(state["phase"] == "move", "첫 단계는 이동")

	var cells: Array[Vector2i] = Core.reachable_cells(state)
	check(Vector2i(2, 5) in cells, "고저차를 반영한 이동 가능 칸")
	check(Vector2i(6, 1) not in cells, "원거리 칸 이동 불가")

	state = Core.move_active_unit(state, Vector2i(2, 5))
	check(Core.active_unit(state)["x"] == 2, "아리아 x 이동")
	check(state["phase"] == "action", "이동 후 행동 선택")

	state = Core.select_action(state, "skill")
	check(state["phase"] == "target", "기술 대상 선택")
	check(has_target(Core.targetable_enemies(state), "lancer"), "공명참 사거리 안 흑창병")

	var lancer_hp: int = Core.unit_by_id(state, "lancer")["hp"]
	state = Core.resolve_player_attack(state, "lancer")
	check(Core.unit_by_id(state, "lancer")["hp"] == lancer_hp - 5, "공명참 피해 5")
	check(Core.active_unit(state)["id"] == "lancer", "적 턴으로 진행")
	check(state["phase"] == "enemy_ready", "적 준비 단계")

	state = Core.begin_enemy_turn(state)
	check(state["phase"] == "enemy_predict", "MIRA 예측 단계")
	state = Core.begin_reaction(state)
	state = Core.resolve_reaction(state, "perfect")
	check(Core.unit_by_id(state, "aria")["hp"] == 8, "퍼펙트 패링 피해 0")
	check(Core.unit_by_id(state, "lancer")["hp"] == 0, "퍼펙트 반격으로 처치")
	check(Core.active_unit(state)["id"] == "kael", "다음 생존 유닛 카엘")
	check(state["advisor_trust"] == 1, "MIRA 신뢰 증가")

	print("godot tactics core: %d assertions passed" % assertions)
	quit(0)


func has_target(targets: Array[Dictionary], target_id: String) -> bool:
	for target in targets:
		if target["id"] == target_id:
			return true
	return false


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("ASSERTION FAILED: %s" % message)
		quit(1)
		return
	assertions += 1
