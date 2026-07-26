import {
  LANES, createGame, currentEncounter, advanceToDecision,
  chooseLane, useBuffer, resolveTurn, nextTurn,
} from "./prototype_core.mjs";

const $ = (id) => document.getElementById(id);
let state = createGame();
const laneLabel = { LEFT: "좌측", CENTER: "중앙", RIGHT: "우측" };

function render() {
  const e = currentEncounter(state);
  $("hp").textContent = "●".repeat(Math.max(0, state.hp)) + "○".repeat(Math.max(0, 3 - state.hp));
  $("enemy-hp").textContent = "■".repeat(Math.max(0, state.enemyHp)) + "□".repeat(Math.max(0, 4 - state.enemyHp));
  $("buffer").textContent = state.buffer;
  $("chapter").textContent = e.title;
  $("enemy-name").textContent = e.enemy;
  $("tell").textContent = state.phase === "observe" ? e.tell : `세계 규칙 · ${e.rule}`;
  $("player").style.left = ({ LEFT: "17%", CENTER: "50%", RIGHT: "83%" })[state.selectedLane];
  document.querySelectorAll("[data-phase]").forEach((el) => el.classList.toggle("active", el.dataset.phase === state.phase));
  renderAdvisor(e);
  renderControls(e);
  renderHistory();
}

function renderAdvisor(e) {
  const observing = state.phase === "observe";
  $("prediction-title").textContent = observing ? "관찰을 기다리는 중" : `예측: ${laneLabel[e.prediction]} 공격`;
  $("confidence").textContent = observing ? "--%" : `${e.confidence}%`;
  $("report").innerHTML = observing ? "" : `
    <div>예상 시점<b>${e.window}</b></div>
    <div>페인트 가능성<b>${e.feint}%</b></div>
    <div>근거<b>${e.evidence.join(" · ")}</b></div>`;
  $("deep-report").hidden = !state.deepRead;
  $("deep-report").innerHTML = state.deepRead ? `<b>추가 분석</b><br>${e.doubt}` : "";
}

function renderControls(e) {
  const c = $("controls");
  if (state.phase === "observe") {
    c.innerHTML = `<button class="primary" id="observe-btn">관찰 결과 해석</button>`;
    $("observe-btn").onclick = () => { state = advanceToDecision(state); render(); };
    $("hint").textContent = "숫자가 아니라 근거를 읽으십시오. AI는 때때로 확신에 차서 틀립니다.";
    return;
  }
  if (state.phase === "decide") {
    c.innerHTML = `
      <div class="lane-grid">${LANES.map((lane) =>
        `<button data-lane="${lane}" class="${state.selectedLane === lane ? "selected" : ""}">${laneLabel[lane]}</button>`
      ).join("")}</div>
      <button class="buffer" id="buffer-btn" ${state.buffer < 1 || state.deepRead ? "disabled" : ""}>예측 버퍼 · 추가 분석</button>
      <button class="primary" id="commit-btn">이 위치에서 회피</button>`;
    c.querySelectorAll("[data-lane]").forEach((b) => b.onclick = () => { state = chooseLane(state, b.dataset.lane); render(); });
    $("buffer-btn").onclick = () => { state = useBuffer(state); render(); };
    $("commit-btn").onclick = () => {
      $("enemy").classList.add("strike");
      setTimeout(() => {
        state = resolveTurn(state);
        $("player").classList.add("hit");
        render();
        setTimeout(() => { $("enemy").classList.remove("strike"); $("player").classList.remove("hit"); }, 500);
      }, 430);
    };
    $("hint").textContent = `AI는 ${laneLabel[e.prediction]} 공격을 예상합니다. 공격선과 다른 위치를 선택해야 합니다.`;
    return;
  }
  if (state.phase === "result") {
    const last = state.log.at(-1);
    c.innerHTML = `
      <div class="result-card ${last.success ? "" : "fail"}">
        <b>${last.result}</b><br>
        ${last.success
          ? `${laneLabel[last.actual]} 공격을 피했습니다. 균열에 반격했습니다.`
          : `${laneLabel[last.actual]} 공격선에 남았습니다. 근거를 다시 읽어야 합니다.`}
      </div>
      <button class="primary" id="next-btn">다음 파편으로</button>`;
    $("next-btn").onclick = () => { state = nextTurn(state); if (state.phase === "ending") showEnding(); else render(); };
    $("hint").textContent = resultExplanation(last.result);
  }
}

function resultExplanation(result) {
  return ({
    READ: "AI의 예측과 실제 공격을 함께 읽어 안전한 자리를 찾았습니다.",
    DOUBT: "AI를 의심했고 그 판단이 적중했습니다.",
    MISREAD: "AI를 의심했지만 세계 규칙이나 관찰 근거를 잘못 읽었습니다.",
    DECEIVED: "AI의 높은 확신을 정답으로 받아들여 기만에 걸렸습니다.",
  })[result];
}

function renderHistory() {
  $("history-list").innerHTML = state.log.length ? state.log.map((x) => `
    <div class="history-item ${x.success ? "" : "fail"}">
      <b>${x.result}</b>${x.title.replace(/.*· /, "")}<br>${laneLabel[x.lane]} 선택
    </div>`).join("") : "<span>아직 기록이 없습니다.</span>";
}

function showEnding() {
  const won = state.enemyHp <= 0 && state.hp > 0;
  const reads = state.log.filter((x) => x.success).length;
  $("ending-title").textContent = won ? "하나의 정답 대신, 판단을 복원했다" : "당신은 정답을 빌렸고, 대가를 치렀다";
  $("ending-copy").textContent = won
    ? "MIRA는 완전해지지 않았습니다. 대신 당신과 함께 틀린 이유를 기억합니다."
    : "실패는 기록되었습니다. 같은 확률도 다음에는 다른 의미가 될 수 있습니다.";
  $("ending-stats").innerHTML = `생존 ${state.hp}/3 · 성공한 판독 ${reads}/${state.log.length}<br>남은 예측 버퍼 ${state.buffer}`;
  $("ending").hidden = false;
}

$("restart-btn").onclick = () => {
  state = createGame();
  $("ending").hidden = true;
  render();
};
render();
