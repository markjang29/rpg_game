class_name BattleDirector
extends RefCounted
## 챕터의 대화·전투·결과 전환만 담당한다.
##
## 실제 전투 판정은 TacticsCore에, 화면 표현은 TacticsBattle에 남겨
## Matrix에서 온 시나리오도 같은 수명주기로 재생할 수 있게 한다.

var scenario: Dictionary = {}
var phase := "idle"
var dialogue_lines: Array = []
var dialogue_index := -1
var return_phase := "battle"
var triggered: Dictionary = {}


func start(next_scenario: Dictionary) -> void:
	scenario = next_scenario.duplicate(true)
	triggered.clear()
	_open_dialogue(scenario.get("briefing", []), "battle")


func is_dialogue_active() -> bool:
	return phase == "dialogue" and dialogue_index >= 0 and dialogue_index < dialogue_lines.size()


func current_line() -> Dictionary:
	if not is_dialogue_active():
		return {}
	return dialogue_lines[dialogue_index]


func advance_dialogue() -> String:
	if not is_dialogue_active():
		return phase
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		return "line"
	dialogue_lines.clear()
	dialogue_index = -1
	phase = return_phase
	return phase


func observe_battle(battle_state: Dictionary) -> bool:
	if phase != "battle":
		return false
	if battle_state.get("battle_ended", false):
		var allies_alive := false
		for unit: Dictionary in battle_state.get("units", []):
			allies_alive = allies_alive or (unit["team"] == "ally" and unit["hp"] > 0)
		var lines: Array = scenario.get("victory", []) if allies_alive else scenario.get("defeat", [])
		_open_dialogue(lines, "complete")
		return true

	for trigger: Dictionary in scenario.get("battle_triggers", []):
		var trigger_id: String = trigger["id"]
		if triggered.has(trigger_id):
			continue
		if _matches_trigger(trigger, battle_state):
			triggered[trigger_id] = true
			_open_dialogue(trigger.get("dialogue", []), "battle")
			return true
	return false


func skip_briefing_for_test() -> void:
	dialogue_lines.clear()
	dialogue_index = -1
	phase = "battle"


func _matches_trigger(trigger: Dictionary, battle_state: Dictionary) -> bool:
	if trigger.get("condition", "") != "unit_hp_at_most":
		return false
	for unit: Dictionary in battle_state.get("units", []):
		if unit["id"] == trigger.get("unit_id", ""):
			return unit["hp"] <= int(trigger.get("value", 0))
	return false


func _open_dialogue(lines: Array, after_phase: String) -> void:
	dialogue_lines = lines.duplicate(true)
	dialogue_index = 0
	return_phase = after_phase
	phase = "dialogue" if not dialogue_lines.is_empty() else after_phase
