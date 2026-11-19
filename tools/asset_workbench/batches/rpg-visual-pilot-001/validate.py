"""Offline contract check only; never calls NAI or imports the running app."""
import ast
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
app = ROOT.parent.parent / "app.py"
module = ast.parse(app.read_text(encoding="utf-8"))
values = {}
for node in module.body:
    if isinstance(node, ast.Assign):
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id in {"MODEL", "TYPES", "STYLES"}:
                values[target.id] = ast.literal_eval(node.value)
batch = json.loads((ROOT / "batch.json").read_text(encoding="utf-8"))
assert batch["status"] == "prepared_not_generated"
assert values["MODEL"] == batch["source_contract"]["model"] == "nai-diffusion-4-5-full"
assert batch["budget"]["concurrency"] == 1
assert batch["budget"]["paid_anlas_allowed"] is False
assert len(batch["jobs"]) == batch["budget"]["initial_requests"] == 12
assert len({j["job_id"] for j in batch["jobs"]}) == 12
assert len({j["request"]["seed"] for j in batch["jobs"]}) == 12
for job in batch["jobs"]:
    request = job["request"]
    assert set(request) == {"type", "style", "extra", "seed"}
    assert request["type"] in values["TYPES"]
    assert request["style"] in values["STYLES"]
    assert 0 < request["seed"] < 2**31
    assert 0 < len(request["extra"]) <= 500
    width, height = values["TYPES"][request["type"]]["size"]
    assert width * height <= 1024 * 1024
    assert job["status"] == "prepared"
    assert job["artifact_ref"] is None and job["review_ref"] is None
print(json.dumps({"contract_checks": "passed", "prepared_requests": 12,
                  "generated_images": 0, "live_tests": "not_run"}, ensure_ascii=False))
