import assert from "node:assert/strict";
import {
  ENCOUNTERS, createGame, advanceToDecision, chooseLane,
  useBuffer, resolveTurn, nextTurn, classifyResult,
} from "../static/prototype_core.mjs";

let state = createGame();
assert.equal(state.phase, "observe");
assert.equal(state.buffer, 1);

state = advanceToDecision(state);
state = chooseLane(state, "CENTER");
state = useBuffer(state);
assert.equal(state.buffer, 0);
assert.equal(state.deepRead, true);

state = resolveTurn(state);
assert.equal(state.phase, "result");
assert.equal(state.enemyHp, 3);
assert.equal(state.log[0].result, "DOUBT");

state = nextTurn(state);
assert.equal(state.encounterIndex, 1);
assert.equal(state.phase, "observe");

assert.equal(classifyResult(ENCOUNTERS[0], "RIGHT", false), "DECEIVED");
assert.equal(classifyResult(ENCOUNTERS[1], "LEFT", false), "DOUBT");
assert.equal(classifyResult(ENCOUNTERS[2], "LEFT", true), "MISREAD");

console.log("prototype core: 10 assertions passed");
