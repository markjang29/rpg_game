export const LANES = ["LEFT", "CENTER", "RIGHT"];

export const ENCOUNTERS = [
  {
    title: "첫 번째 파편 · 유리 회랑",
    enemy: "잔향 기사",
    rule: "기사의 어깨가 먼저 내려간 쪽은 미끼다.",
    tell: "오른발에 체중. 검끝은 왼쪽 바닥을 긁는다.",
    trueLane: "RIGHT",
    prediction: "LEFT",
    confidence: 68,
    window: "1.2–1.6초",
    feint: 21,
    evidence: ["오른발 하중", "왼쪽 검선 고정"],
    doubt: "검끝은 공격선이 아니라 시선을 끄는 미끼일 수 있습니다.",
  },
  {
    title: "두 번째 파편 · 침묵의 종루",
    enemy: "무언의 집행자",
    rule: "종이 울리지 않은 공격은 중앙을 지나지 않는다.",
    tell: "종은 침묵. 적의 그림자가 두 갈래로 찢어진다.",
    trueLane: "CENTER",
    prediction: "CENTER",
    confidence: 74,
    window: "0.9–1.3초",
    feint: 14,
    evidence: ["그림자 수렴", "손목 회전"],
    doubt: "침묵 규칙과 자세가 충돌합니다. 규칙 자체가 바뀌었을 가능성 26%.",
  },
  {
    title: "세 번째 파편 · 이름 없는 법정",
    enemy: "증언 포식자",
    rule: "이름을 부른 뒤에는 방금 본 자세의 반대편을 친다.",
    tell: "AI가 당신의 이름을 부른다. 창끝은 오른쪽을 향한다.",
    trueLane: "LEFT",
    prediction: "RIGHT",
    confidence: 81,
    window: "1.0–1.4초",
    feint: 36,
    evidence: ["오른쪽 창끝", "직전 2회 우측 공격"],
    doubt: "문화 규칙을 적용하면 관찰 결과의 반대편이 실제 공격선입니다.",
  },
  {
    title: "최종 파편 · 복원실",
    enemy: "당신이 버린 가능성",
    rule: "복제체는 가장 안전해 보이는 길을 먼저 지운다.",
    tell: "세 개의 문이 동시에 열린다. 중앙의 빛만 흔들리지 않는다.",
    trueLane: "RIGHT",
    prediction: "CENTER",
    confidence: 59,
    window: "0.8–1.1초",
    feint: 43,
    evidence: ["중앙 안정", "양측 소음"],
    doubt: "안정 자체가 표적일 수 있습니다. 안전해 보이는 길을 버리십시오.",
  },
];

export function createGame() {
  return {
    encounterIndex: 0,
    hp: 3,
    enemyHp: 4,
    buffer: 1,
    selectedLane: "CENTER",
    deepRead: false,
    phase: "observe",
    log: [],
    resolved: 0,
  };
}
export function currentEncounter(state) {
  return ENCOUNTERS[state.encounterIndex];
}

export function useBuffer(state) {
  if (state.phase !== "decide" || state.buffer < 1 || state.deepRead) return state;
  return { ...state, buffer: state.buffer - 1, deepRead: true };
}

export function classifyResult(encounter, lane, deepRead) {
  const safe = lane !== encounter.trueLane;
  const followedAI = lane !== encounter.prediction;
  if (safe && !followedAI) return "READ";
  if (safe && followedAI) return "DOUBT";
  if (!safe && followedAI) return deepRead ? "MISREAD" : "DECEIVED";
  return "MISREAD";
}

export function resolveTurn(state) {
  if (state.phase !== "decide") return state;
  const encounter = currentEncounter(state);
  const result = classifyResult(encounter, state.selectedLane, state.deepRead);
  const success = state.selectedLane !== encounter.trueLane;
  return {
    ...state,
    hp: state.hp - (success ? 0 : 1),
    enemyHp: state.enemyHp - (success ? 1 : 0),
    phase: "result",
    resolved: state.resolved + 1,
    log: [...state.log, {
      result,
      success,
      lane: state.selectedLane,
      actual: encounter.trueLane,
      title: encounter.title,
    }],
  };
}

export function nextTurn(state) {
  if (state.phase !== "result") return state;
  if (state.hp <= 0 || state.enemyHp <= 0 || state.encounterIndex >= ENCOUNTERS.length - 1) {
    return { ...state, phase: "ending" };
  }
  return {
    ...state,
    encounterIndex: state.encounterIndex + 1,
    selectedLane: "CENTER",
    deepRead: false,
    phase: "observe",
  };
}

export function chooseLane(state, lane) {
  if (state.phase !== "decide" || !LANES.includes(lane)) return state;
  return { ...state, selectedLane: lane };
}

export function advanceToDecision(state) {
  if (state.phase !== "observe") return state;
  return { ...state, phase: "decide" };
}
