export const BOARD_SIZE = 8;

export const TERRAIN = [
  [0, 0, 0, 0, 1, 1, 2, 2],
  [0, 0, 0, 0, 1, 1, 2, 2],
  [0, 0, 0, 1, 1, 1, 1, 1],
  [0, 0, 0, 1, 1, 1, 1, 1],
  [0, 0, 0, 0, 1, 1, 1, 0],
  [0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0],
];

const UNIT_BLUEPRINTS = [
  { id: "aria", name: "아리아", job: "검사", team: "ally", sprite: 0, x: 1, y: 6, hp: 8, maxHp: 8, move: 3, range: 1, power: 3 },
  { id: "kael", name: "카엘", job: "수호기사", team: "ally", sprite: 1, x: 2, y: 7, hp: 11, maxHp: 11, move: 2, range: 1, power: 2 },
  { id: "sena", name: "세나", job: "마도사", team: "ally", sprite: 2, x: 0, y: 7, hp: 6, maxHp: 6, move: 2, range: 4, power: 4 },
  { id: "lancer", name: "흑창병", job: "창병", team: "enemy", sprite: 3, x: 4, y: 4, hp: 6, maxHp: 6, move: 2, range: 2, power: 2 },
  { id: "rogue", name: "회색 가면", job: "척후", team: "enemy", sprite: 4, x: 5, y: 3, hp: 5, maxHp: 5, move: 3, range: 1, power: 2 },
  { id: "archer", name: "석궁병", job: "사수", team: "enemy", sprite: 5, x: 6, y: 4, hp: 5, maxHp: 5, move: 2, range: 4, power: 2 },
  { id: "boss", name: "검은 성좌", job: "집행자", team: "enemy", sprite: 6, x: 6, y: 1, hp: 12, maxHp: 12, move: 2, range: 2, power: 3 },
];

export const TURN_ORDER = ["aria", "lancer", "kael", "rogue", "sena", "archer", "boss"];

export function createTacticsGame() {
  return {
    units: UNIT_BLUEPRINTS.map((unit) => ({ ...unit, acted: false })),
    turnCursor: 0,
    round: 1,
    phase: "move",
    selectedAction: null,
    lastEvent: "부유 유적에 진입했다.",
    advisorTrust: 0,
    battleEnded: false,
  };
}
export function unitById(state, id) {
  return state.units.find((unit) => unit.id === id);
}

export function activeUnit(state) {
  return unitById(state, TURN_ORDER[state.turnCursor]);
}

export function isInside(x, y) {
  return x >= 0 && y >= 0 && x < BOARD_SIZE && y < BOARD_SIZE;
}

export function distance(a, b) {
  return Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
}

export function occupied(state, x, y, exceptId = "") {
  return state.units.some((unit) => unit.hp > 0 && unit.id !== exceptId && unit.x === x && unit.y === y);
}

export function reachableCells(state, unit = activeUnit(state)) {
  if (!unit || unit.hp <= 0) return [];
  const start = `${unit.x},${unit.y}`;
  const queue = [{ x: unit.x, y: unit.y, cost: 0 }];
  const best = new Map([[start, 0]]);
  const out = [];
  while (queue.length) {
    const cell = queue.shift();
    out.push(cell);
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const x = cell.x + dx;
      const y = cell.y + dy;
      if (!isInside(x, y) || occupied(state, x, y, unit.id)) continue;
      const heightCost = Math.abs(TERRAIN[y][x] - TERRAIN[cell.y][cell.x]);
      if (heightCost > 1) continue;
      const cost = cell.cost + 1 + heightCost;
      const key = `${x},${y}`;
      if (cost <= unit.move && (!best.has(key) || cost < best.get(key))) {
        best.set(key, cost);
        queue.push({ x, y, cost });
      }
    }
  }
  return out;
}

export function moveActiveUnit(state, x, y) {
  if (state.phase !== "move") return state;
  const valid = reachableCells(state).some((cell) => cell.x === x && cell.y === y);
  if (!valid) return state;
  const id = activeUnit(state).id;
  return {
    ...state,
    units: state.units.map((unit) => unit.id === id ? { ...unit, x, y } : unit),
    phase: "action",
    lastEvent: `${activeUnit(state).name} 이동 완료.`,
  };
}

export function targetableEnemies(state, action = state.selectedAction) {
  const actor = activeUnit(state);
  if (!actor) return [];
  const range = action === "skill" ? Math.max(3, actor.range) : actor.range;
  return state.units.filter((unit) =>
    unit.hp > 0 && unit.team !== actor.team && distance(actor, unit) <= range
  );
}

export function selectAction(state, action) {
  if (state.phase !== "action" || !["attack", "skill", "wait"].includes(action)) return state;
  if (action === "wait") return endTurn({ ...state, lastEvent: `${activeUnit(state).name} 대기.` });
  return { ...state, phase: "target", selectedAction: action };
}

export function resolvePlayerAttack(state, targetId) {
  if (state.phase !== "target") return state;
  const target = targetableEnemies(state).find((unit) => unit.id === targetId);
  if (!target) return state;
  const actor = activeUnit(state);
  const damage = state.selectedAction === "skill" ? actor.power + 2 : actor.power;
  const skillName = state.selectedAction === "skill" ? "공명참" : "공격";
  const next = {
    ...state,
    units: state.units.map((unit) => unit.id === target.id ? { ...unit, hp: Math.max(0, unit.hp - damage) } : unit),
    lastEvent: `${actor.name}의 ${skillName}! ${target.name}에게 ${damage} 피해.`,
    selectedAction: null,
  };
  return endTurn(checkBattleEnd(next));
}

export function enemyIntent(state) {
  const enemy = activeUnit(state);
  if (!enemy || enemy.team !== "enemy") return null;
  const allies = state.units.filter((unit) => unit.team === "ally" && unit.hp > 0);
  const target = [...allies].sort((a, b) => distance(enemy, a) - distance(enemy, b))[0];
  return {
    enemyId: enemy.id,
    targetId: target.id,
    confidence: enemy.id === "boss" ? 57 : 72,
    direction: target.x < enemy.x ? "좌측" : target.x > enemy.x ? "우측" : "정면",
    evidence: enemy.id === "boss" ? "검끝 고정 · 마력 역류" : "체중 이동 · 시선 고정",
  };
}

export function beginEnemyTurn(state) {
  if (activeUnit(state)?.team !== "enemy") return state;
  return { ...state, phase: "enemy_predict", lastEvent: `${activeUnit(state).name}이 자세를 낮춘다.` };
}

export function beginReaction(state) {
  if (state.phase !== "enemy_predict") return state;
  return { ...state, phase: "reaction" };
}

export function resolveReaction(state, grade) {
  if (state.phase !== "reaction") return state;
  const intent = enemyIntent(state);
  const enemy = unitById(state, intent.enemyId);
  const damage = grade === "perfect" ? 0 : grade === "good" ? 1 : enemy.power;
  const label = grade === "perfect" ? "PERFECT · 반격" : grade === "good" ? "GUARD · 피해 경감" : "HIT · 예측 실패";
  let units = state.units.map((unit) => unit.id === intent.targetId ? { ...unit, hp: Math.max(0, unit.hp - damage) } : unit);
  if (grade === "perfect") {
    units = units.map((unit) => unit.id === enemy.id ? { ...unit, hp: Math.max(0, unit.hp - 1) } : unit);
  }
  const next = {
    ...state,
    units,
    advisorTrust: state.advisorTrust + (grade === "perfect" ? 1 : grade === "miss" ? -1 : 0),
    lastEvent: `${label}. ${unitById(state, intent.targetId).name} 피해 ${damage}.`,
  };
  return endTurn(checkBattleEnd(next));
}

export function endTurn(state) {
  if (state.battleEnded) return state;
  let cursor = state.turnCursor;
  let round = state.round;
  for (let i = 0; i < TURN_ORDER.length; i += 1) {
    cursor = (cursor + 1) % TURN_ORDER.length;
    if (cursor === 0) round += 1;
    const candidate = unitById(state, TURN_ORDER[cursor]);
    if (candidate?.hp > 0) {
      const phase = candidate.team === "enemy" ? "enemy_ready" : "move";
      return { ...state, turnCursor: cursor, round, phase, selectedAction: null };
    }
  }
  return checkBattleEnd(state);
}

export function checkBattleEnd(state) {
  const alliesAlive = state.units.some((unit) => unit.team === "ally" && unit.hp > 0);
  const enemiesAlive = state.units.some((unit) => unit.team === "enemy" && unit.hp > 0);
  if (alliesAlive && enemiesAlive) return state;
  return {
    ...state,
    battleEnded: true,
    phase: "ending",
    lastEvent: alliesAlive ? "부유 유적의 봉인이 해제됐다." : "파편이 다시 어둠 속으로 가라앉았다.",
  };
}
