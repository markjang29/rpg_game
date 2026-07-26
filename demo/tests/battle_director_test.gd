extends SceneTree
## 챕터 대화와 전투 이벤트가 규칙 코어와 독립적으로 전환되는지 검증한다.

const Director = preload("res://modules/tactics/battle_director.gd")
const Scenario = preload("res://modules/tactics/battle_scenario.gd")
const Core = preload("res://modules/tactics/tactics_core.gd")

var assertions := 0


func _init() -> void:
	var director := Director.new()
	director.start(Scenario.chapter_01())
	check(director.is_dialogue_active(), "브리핑 대화 시작")
	check(director.current_line()["speaker_id"] == "aria", "첫 화자 아리아")
	director.advance_dialogue()
	director.advance_dialogue()
	check(director.current_line()["speaker_id"] == "sena", "세 번째 화자 세나")
	check(director.advance_dialogue() == "battle", "브리핑 뒤 전투 전환")

	var state := Core.create_game()
	Core.unit_by_id(state, "lancer")["hp"] = 1
	check(director.observe_battle(state), "전투 중 정체 공개 트리거")
	check(director.current_line()["speaker_id"] == "sena", "정체 공개 화자 세나")
	for _line in 3:
		director.advance_dialogue()
	check(director.phase == "battle", "정체 공개 뒤 전투 복귀")
	check(not director.observe_battle(state), "동일 트리거 중복 방지")

	state["battle_ended"] = true
	for unit: Dictionary in state["units"]:
		if unit["team"] == "enemy":
			unit["hp"] = 0
	check(director.observe_battle(state), "승리 대화 시작")
	check(director.current_line()["speaker_id"] == "kael", "승리 첫 화자 카엘")

	print("battle director: %d assertions passed" % assertions)
	quit(0)


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("ASSERTION FAILED: %s" % message)
		quit(1)
		return
	assertions += 1
