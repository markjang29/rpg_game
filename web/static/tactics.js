import {
  BOARD_SIZE, TERRAIN, TURN_ORDER, createTacticsGame, activeUnit, unitById,
  reachableCells, moveActiveUnit, targetableEnemies, selectAction,
  resolvePlayerAttack, beginEnemyTurn, beginReaction, resolveReaction, enemyIntent,
} from "./tactics_core.mjs";

const $ = (id) => document.getElementById(id);
let state = createTacticsGame();
let reactionStart = 0;
let reactionTimer = null;
const X_STEP = 4.55;
const Y_STEP = 2.78;
const ORIGIN_X = 49.5;
const ORIGIN_Y = 30.5;

function cellPosition(x, y) {
  const height = TERRAIN[y][x];
  return {
    left: ORIGIN_X + (x - y) * X_STEP,
    top: ORIGIN_Y + (x + y) * Y_STEP - height * 3.2,
  };
}

function spriteClass(index) { return `sprite-${index}`; }

function render() {
  const actor = activeUnit(state);
  $("round").textContent = state.round;
  $("battle-log").textContent = state.lastEvent;
  renderGrid();
  renderUnits();
  renderActive(actor);
  renderCommands(actor);
  renderTimeline();
  if (state.battleEnded) showEnding();
}

function renderGrid() {
  const layer = $("grid-layer");
  const reachable = state.phase === "move" ? reachableCells(state) : [];
  const targets = state.phase === "target" ? targetableEnemies(state) : [];
  layer.innerHTML = "";
  for (let y = 0; y < BOARD_SIZE; y += 1) {
    for (let x = 0; x < BOARD_SIZE; x += 1) {
      const position = cellPosition(x, y);
      const cell = document.createElement("button");
      cell.className = "iso-cell";
      cell.style.left = `${position.left}%`;
      cell.style.top = `${position.top}%`;
      cell.style.zIndex = String(20 + x + y + TERRAIN[y][x]);
      cell.dataset.x = x;
      cell.dataset.y = y;
      const move = reachable.some((item) => item.x === x && item.y === y);
      const target = targets.find((unit) => unit.x === x && unit.y === y);
      if (move) cell.classList.add("reachable");
      if (target) cell.classList.add("targetable");
      const actor = activeUnit(state);
      if (actor && actor.x === x && actor.y === y) cell.classList.add("current");
      cell.disabled = !(move || target);
      cell.setAttribute("aria-label", target ? `${target.name} 대상` : `${x + 1}, ${y + 1} 이동`);
      cell.onclick = () => {
        if (target) {
          animateAttack(actor.id, target.id, state.selectedAction === "skill");
          const beforeHp = target.hp;
          state = resolvePlayerAttack(state, target.id);
          floatDamage(target.x, target.y, beforeHp - unitById(state, target.id).hp);
          scheduleTurn();
        } else if (move) {
          state = moveActiveUnit(state, x, y);
          render();
        }
      };
      layer.appendChild(cell);
    }
  }
}

function renderUnits() {
  const layer = $("unit-layer");
  layer.innerHTML = "";
  [...state.units].sort((a, b) => (a.x + a.y) - (b.x + b.y)).forEach((unit) => {
    if (unit.hp <= 0) return;
    const position = cellPosition(unit.x, unit.y);
    const el = document.createElement("div");
    el.id = `unit-${unit.id}`;
    el.className = `unit ${unit.team} ${activeUnit(state)?.id === unit.id ? "active" : ""}`;
    el.style.left = `${position.left}%`;
    el.style.top = `${position.top}%`;
    el.style.zIndex = String(60 + unit.x + unit.y + TERRAIN[unit.y][unit.x] * 3);
    el.innerHTML = `<div class="unit-art ${spriteClass(unit.sprite)}"></div><i class="unit-ring"></i><div class="unit-hp"><i style="width:${unit.hp / unit.maxHp * 100}%"></i></div>`;
    layer.appendChild(el);
  });
}

function renderActive(actor) {
  if (!actor) return;
  $("active-name").textContent = actor.name;
  $("active-job").textContent = actor.job;
  $("active-hp").textContent = `HP ${actor.hp} / ${actor.maxHp}`;
  $("active-hp-bar").style.width = `${actor.hp / actor.maxHp * 100}%`;
  $("active-portrait").className = `portrait ${spriteClass(actor.sprite)}`;
}

function renderCommands(actor) {
  const box = $("commands");
  const hint = $("command-hint");
  box.innerHTML = "";
  if (state.phase === "move") {
    hint.textContent = `청록색 타일 중 이동할 위치를 선택하세요. 이동력 ${actor.move}.`;
  } else if (state.phase === "action") {
    box.innerHTML = `<button data-action="attack">공격</button><button data-action="skill" class="primary">기술 · 공명참</button><button data-action="wait">대기</button>`;
    box.querySelectorAll("[data-action]").forEach((button) => button.onclick = () => {
      state = selectAction(state, button.dataset.action);
      scheduleTurn();
    });
    hint.textContent = "행동을 고르세요. 기술은 더 멀리 닿지만 이번 체감판에서는 자원 제한이 없습니다.";
  } else if (state.phase === "target") {
    const targets = targetableEnemies(state);
    hint.textContent = targets.length ? "붉은 타일의 적을 선택하세요." : "범위 안에 적이 없습니다.";
    box.innerHTML = `<button id="cancel-action">이동 후 대기</button>`;
    $("cancel-action").onclick = () => { state = selectAction({ ...state, phase: "action" }, "wait"); scheduleTurn(); };
  } else if (state.phase === "enemy_ready") {
    box.innerHTML = `<button id="enemy-start" class="danger">적의 턴 진행</button>`;
    hint.textContent = "적이 움직이기 전에 MIRA의 예측을 확인합니다.";
    $("enemy-start").onclick = () => { state = beginEnemyTurn(state); render(); };
  } else if (state.phase === "enemy_predict") {
    const intent = enemyIntent(state);
    const target = unitById(state, intent.targetId);
    $("advisor-copy").textContent = `${target.name} 대상 ${intent.direction} 공격 ${intent.confidence}% · 근거: ${intent.evidence}`;
    box.innerHTML = `<button id="accept-prediction" class="primary">예측을 읽고 대비</button>`;
    hint.textContent = "정답이 아니라 반응할 준비를 얻습니다.";
    $("accept-prediction").onclick = startReaction;
  } else if (state.phase === "reaction") {
    hint.textContent = "흰 표식이 청록 구간에 들어올 때 패링!";
  } else if (state.phase === "ending") {
    hint.textContent = "전투가 종료됐습니다.";
  }
}

function renderTimeline() {
  $("timeline").innerHTML = TURN_ORDER.map((id) => {
    const unit = unitById(state, id);
    return `<div class="timeline-unit ${activeUnit(state)?.id === id ? "active" : ""} ${unit.hp <= 0 ? "dead" : ""}">
      <i class="timeline-icon ${spriteClass(unit.sprite)}"></i><span>${unit.name}</span>
    </div>`;
  }).join("");
}

function scheduleTurn() {
  render();
  if (state.phase === "enemy_ready") {
    $("advisor-copy").textContent = `${activeUnit(state).name}의 공격 징후를 분석 중입니다.`;
  } else if (state.phase === "move") {
    $("advisor-copy").textContent = `${activeUnit(state).name}의 이동 경로를 표시했습니다. 고저차는 이동력을 더 소모합니다.`;
  }
}

function startReaction() {
  state = beginReaction(state);
  reactionStart = performance.now();
  $("parry-button").hidden = false;
  $("reaction-meter").hidden = false;
  reactionTimer = window.setTimeout(() => finishReaction("miss"), 3050);
  render();
}

function finishReaction(forcedGrade = null) {
  if (state.phase !== "reaction") return;
  clearTimeout(reactionTimer);
  const elapsed = performance.now() - reactionStart;
  const grade = forcedGrade || (elapsed >= 1050 && elapsed <= 1850 ? "perfect" : elapsed < 2500 ? "good" : "miss");
  $("parry-button").hidden = true;
  $("reaction-meter").hidden = true;
  const intent = enemyIntent(state);
  const target = unitById(state, intent.targetId);
  animateReaction(intent.enemyId, target.id, grade);
  state = resolveReaction(state, grade);
  scheduleTurn();
}

function animateAttack(actorId, targetId, skill) {
  document.getElementById(`unit-${actorId}`)?.classList.add(skill ? "cast" : "active");
  document.getElementById(`unit-${targetId}`)?.classList.add("hit");
}

function animateReaction(enemyId, targetId, grade) {
  document.getElementById(`unit-${enemyId}`)?.classList.add("cast");
  if (grade !== "perfect") document.getElementById(`unit-${targetId}`)?.classList.add("hit");
}

function floatDamage(x, y, amount) {
  const position = cellPosition(x, y);
  const el = document.createElement("span");
  el.className = "damage-float";
  el.style.left = `${position.left}%`;
  el.style.top = `${position.top - 6}%`;
  el.textContent = `-${amount}`;
  $("effect-layer").appendChild(el);
  setTimeout(() => el.remove(), 850);
}

function showEnding() {
  const alliesAlive = state.units.some((unit) => unit.team === "ally" && unit.hp > 0);
  $("ending-heading").textContent = alliesAlive ? "부유 유적의 봉인이 해제됐다" : "파편이 다시 어둠 속으로 가라앉았다";
  $("ending-layer").hidden = false;
}

function restart() {
  clearTimeout(reactionTimer);
  state = createTacticsGame();
  $("ending-layer").hidden = true;
  $("parry-button").hidden = true;
  $("reaction-meter").hidden = true;
  $("advisor-copy").textContent = "석조 바닥의 높이와 적의 시선을 함께 읽으세요.";
  render();
}

$("parry-button").onclick = () => finishReaction();
$("restart-tactics").onclick = restart;
$("ending-restart").onclick = restart;
render();
