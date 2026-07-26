extends SceneTree
## 전술 씬이 순수 코어와 실제 UI 상태를 끝까지 연결하는지 검증한다.

const BattleScene = preload("res://modules/tactics/tactics_battle.tscn")

var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle := BattleScene.instantiate()
	root.add_child(battle)
	await process_frame

	check(battle.director.is_dialogue_active(), "씬 시작 브리핑 대화")
	check(battle.dialogue_speaker.text == "아리아", "브리핑 첫 화자 표시")
	battle.director.skip_briefing_for_test()
	battle.call("_show_dialogue")
	battle.call("_on_fit_map")
	check(battle.camera_zoom < 0.82, "대형 맵 전체 보기 줌")
	battle.call("_focus_active_unit")
	check(battle.camera_zoom >= 0.82, "현재 유닛 추적 줌")
	check(battle.state["phase"] == "move", "씬 시작 이동 단계")
	battle.call("_handle_board_click", Vector2i(3, 13))
	check(battle.state["phase"] == "action", "타일 선택 후 행동 단계")
	battle.call("_on_skill")
	check(battle.state["phase"] == "target", "공명참 대상 단계")
	battle.call("_handle_board_click", Vector2i(5, 12))
	check(battle.state["phase"] == "enemy_ready", "타격 후 적 준비 단계")
	battle.call("_on_enemy_turn")
	check(battle.state["phase"] == "enemy_predict", "MIRA 예측 표시")
	battle.call("_on_prepare")
	check(battle.state["phase"] == "reaction", "패링 입력 단계")
	battle.reaction_elapsed = 1.35
	battle.call("_finish_reaction")
	check(battle.state["last_event"].begins_with("PERFECT"), "퍼펙트 패링 판정")
	check(battle.state["phase"] == "move", "다음 아군 이동 단계")
	check(CoreState.unit_by_id(battle.state, "lancer")["hp"] == 0, "반격으로 흑창병 처치")

	print("godot tactics scene: %d assertions passed" % assertions)
	quit(0)


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("ASSERTION FAILED: %s" % message)
		quit(1)
		return
	assertions += 1


class CoreState:
	static func unit_by_id(state: Dictionary, unit_id: String) -> Dictionary:
		for unit: Dictionary in state["units"]:
			if unit["id"] == unit_id:
				return unit
		return {}
