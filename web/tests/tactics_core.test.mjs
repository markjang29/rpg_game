import assert from "node:assert/strict";
import {
  createTacticsGame, activeUnit, reachableCells, moveActiveUnit,
  selectAction, targetableEnemies, resolvePlayerAttack, beginEnemyTurn,
  beginReaction, resolveReaction, unitById,
} from "../static/tactics_core.mjs";

let state = createTacticsGame();
assert.equal(activeUnit(state).id, "aria");
assert.equal(state.phase, "move");

const cells = reachableCells(state);
assert.ok(cells.some((cell) => cell.x === 2 && cell.y === 5));
assert.ok(!cells.some((cell) => cell.x === 6 && cell.y === 1));

state = moveActiveUnit(state, 2, 5);
assert.equal(activeUnit(state).x, 2);
assert.equal(state.phase, "action");

state = selectAction(state, "skill");
assert.equal(state.phase, "target");
assert.ok(targetableEnemies(state).some((unit) => unit.id === "lancer"));

const lancerHp = unitById(state, "lancer").hp;
state = resolvePlayerAttack(state, "lancer");
assert.equal(unitById(state, "lancer").hp, lancerHp - 5);
assert.equal(activeUnit(state).id, "lancer");
assert.equal(state.phase, "enemy_ready");

state = beginEnemyTurn(state);
assert.equal(state.phase, "enemy_predict");
state = beginReaction(state);
state = resolveReaction(state, "perfect");
assert.equal(unitById(state, "aria").hp, 8);
assert.equal(unitById(state, "lancer").hp, 0);
assert.equal(activeUnit(state).id, "kael");
assert.equal(state.advisorTrust, 1);

console.log("tactics core: 15 assertions passed");
