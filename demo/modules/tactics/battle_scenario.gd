class_name BattleScenario
extends RefCounted
## 전투 규칙과 분리된 챕터 데이터 계약.
##
## 이후 MatrixScenarioAdapter가 동일한 형태의 Dictionary를 생성하면
## BattleDirector와 전투 씬은 출처와 무관하게 같은 방식으로 재생한다.

const CHAPTER_01 := {
	"id": "chapter-01-sky-gate",
	"title": "하늘에 남은 문",
	"objective": "검은 성좌 격파",
	"landmarks": [
		{"id": "south-camp", "name": "남쪽 야영지", "x": 1, "y": 14, "color": "#65e4ee"},
		{"id": "echo-bridge", "name": "메아리 다리", "x": 9, "y": 10, "color": "#f2ce68"},
		{"id": "star-altar", "name": "별의 제단", "x": 17, "y": 3, "color": "#f26c6f"},
	],
	"matrix_contract": {
		"world_id": "rpg-game-01",
		"scene_id": "sky-ruins-gate",
		"required_cast": ["aria", "kael", "sena", "boss"],
		"event_slots": ["briefing", "battle_reveal", "victory"],
	},
	"briefing": [
		{
			"speaker_id": "aria",
			"speaker": "아리아",
			"role": "검사",
			"text": "저 문 너머에서 마력이 새고 있어. 봉인이 완전히 열리기 전에 끝내자.",
		},
		{
			"speaker_id": "kael",
			"speaker": "카엘",
			"role": "수호기사",
			"text": "내가 길을 열겠다. 아리아, 높은 지형을 먼저 차지해.",
		},
		{
			"speaker_id": "sena",
			"speaker": "세나",
			"role": "마도사",
			"text": "잠깐… 저 집행자의 문양, 내가 아는 별자리와 같아.",
		},
	],
	"battle_triggers": [
		{
			"id": "sena-constellation-reveal",
			"condition": "unit_hp_at_most",
			"unit_id": "lancer",
			"value": 1,
			"dialogue": [
				{
					"speaker_id": "sena",
					"speaker": "세나",
					"role": "마도사",
					"text": "확실해. 저들은 나를 쫓던 별의 교단이야.",
				},
				{
					"speaker_id": "aria",
					"speaker": "아리아",
					"role": "검사",
					"text": "왜 지금까지 말하지 않았지?",
				},
				{
					"speaker_id": "sena",
					"speaker": "세나",
					"role": "마도사",
					"text": "내가 그들의 열쇠였으니까. 살아서 나가면 전부 설명할게.",
				},
			],
		},
	],
	"victory": [
		{
			"speaker_id": "kael",
			"speaker": "카엘",
			"role": "수호기사",
			"text": "봉인은 멎었다. 하지만 문 안쪽에서 누군가 우리를 기다리고 있다.",
		},
		{
			"speaker_id": "sena",
			"speaker": "세나",
			"role": "마도사",
			"text": "다음 문이 열리기 전에, 내가 기억하는 ‘원래 세계’를 이야기할게.",
		},
		{
			"speaker_id": "aria",
			"speaker": "아리아",
			"role": "검사",
			"text": "좋아. 이번에는 누구도 혼자 비밀을 짊어지지 않는 거야.",
		},
	],
	"defeat": [
		{
			"speaker_id": "aria",
			"speaker": "아리아",
			"role": "검사",
			"text": "아직 끝낼 수 없어… 전열을 다시 세우자.",
		},
	],
}


static func chapter_01() -> Dictionary:
	return CHAPTER_01.duplicate(true)
