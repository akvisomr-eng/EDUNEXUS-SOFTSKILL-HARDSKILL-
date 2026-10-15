import test from "node:test";
import assert from "node:assert/strict";
import { authorizeProjectTool, validateChangedPaths, validateRepositoryUrl, validateWorkBranch } from "../neon/functions/edunexusai/project-tool-policy.mjs";

test("repository policy accepts only plain HTTPS GitHub owner/repo URLs", () => {
  assert.deepEqual(validateRepositoryUrl("https://github.com/acme/demo"), { ok: true, owner: "acme", repo: "demo" });
  for (const value of [
    "http://github.com/acme/demo",
    "https://github.com.evil.example/acme/demo",
    "https://user:pass@github.com/acme/demo",
    "https://github.com/acme/demo/tree/main",
    "https://github.com/acme/demo?token=x",
    "https://gitlab.com/acme/demo",
  ]) assert.equal(validateRepositoryUrl(value).ok, false, value);
});

test("patch branches must be isolated EDUNEXUS branches", () => {
  assert.equal(validateWorkBranch("edunexus/feature/inventory").ok, true);
  for (const branch of ["main", "production", "release", "feature/hello", "edunexus/../main", "edunexus//bad", "edunexus/UPPER"]) {
    assert.equal(validateWorkBranch(branch).ok, false, branch);
  }
});

test("patch policy blocks secrets, workflows, dependency locks and path traversal", () => {
  assert.equal(validateChangedPaths(["src/app.mjs", "README.md"]).ok, true);
  for (const path of [".env", ".env.production", ".github/workflows/deploy.yml", "secrets/token.txt", "src/../package.json", "/etc/passwd", "package-lock.json", "src\\..\\secret"]) {
    assert.equal(validateChangedPaths([path]).ok, false, path);
  }
});

test("project tool gateway defaults to no writes and rejects unknown actions", () => {
  const allowed = authorizeProjectTool({ action: "propose_patch", repositoryUrl: "https://github.com/acme/demo", branch: "edunexus/fix/bug", paths: ["src/app.mjs"] });
  assert.equal(allowed.allowed, true);
  assert.equal(allowed.writesEnabled, false);
  assert.equal(allowed.requiresUserAuthorization, true);
  assert.equal(authorizeProjectTool({ action: "merge", repositoryUrl: "https://github.com/acme/demo" }).allowed, false);
  assert.equal(authorizeProjectTool({ action: "propose_patch", repositoryUrl: "https://github.com/acme/demo", branch: "main", paths: ["src/app.mjs"] }).allowed, false);
});
