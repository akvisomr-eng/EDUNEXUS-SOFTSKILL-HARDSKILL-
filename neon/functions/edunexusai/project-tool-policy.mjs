const ALLOWED_ACTIONS = new Set(["read_repository", "propose_patch", "run_ci"]);
const PROTECTED_BRANCHES = new Set(["main", "master", "production", "prod", "release"]);
const BLOCKED_PATHS = [
  /^\.github\/workflows\//i,
  /(^|\/)\.env(?:\.|$)/i,
  /(^|\/)(?:secrets?|credentials?)(?:\/|$)/i,
  /(^|\/)(?:id_rsa|id_ed25519|.*\.pem|.*\.key)$/i,
  /(^|\/)node_modules\//i,
  /(^|\/)\.git\//i,
  /(^|\/)(?:package-lock\.json|pnpm-lock\.yaml|yarn\.lock)$/i,
];

export function validateRepositoryUrl(value) {
  if (typeof value !== "string" || value.length > 300) return { ok: false, reason: "repository_url_invalid" };
  try {
    const url = new URL(value);
    if (url.protocol !== "https:" || url.hostname !== "github.com" || url.username || url.password || url.search || url.hash) {
      return { ok: false, reason: "repository_url_not_allowed" };
    }
    const parts = url.pathname.split("/").filter(Boolean);
    if (parts.length !== 2 || parts.some((part) => !/^[A-Za-z0-9_.-]{1,100}$/.test(part)) || parts[1].endsWith(".git")) {
      return { ok: false, reason: "repository_url_invalid" };
    }
    return { ok: true, owner: parts[0], repo: parts[1] };
  } catch {
    return { ok: false, reason: "repository_url_invalid" };
  }
}

export function validateWorkBranch(value) {
  if (typeof value !== "string" || value.length > 120 || !/^edunexus\/[a-z0-9][a-z0-9._/-]{0,100}$/.test(value)) {
    return { ok: false, reason: "work_branch_prefix_required" };
  }
  const segments = value.split("/");
  if (segments.some((segment) => !segment || segment === "." || segment === "..") || PROTECTED_BRANCHES.has(value.toLowerCase())) {
    return { ok: false, reason: "work_branch_invalid" };
  }
  return { ok: true, branch: value };
}

export function validateChangedPaths(paths) {
  if (!Array.isArray(paths) || paths.length === 0 || paths.length > 100) {
    return { ok: false, reason: "changed_paths_count_invalid", blocked: [] };
  }
  const blocked = [];
  for (const path of paths) {
    if (typeof path !== "string" || path.length > 300 || path.startsWith("/") || path.includes("\\") ||
        path.split("/").some((segment) => !segment || segment === "." || segment === "..") ||
        BLOCKED_PATHS.some((pattern) => pattern.test(path))) {
      blocked.push(typeof path === "string" ? path.slice(0, 300) : "[invalid path]");
    }
  }
  return blocked.length ? { ok: false, reason: "changed_path_blocked", blocked } : { ok: true, paths: [...new Set(paths)] };
}

export function authorizeProjectTool({ action, repositoryUrl, branch, paths, approved = false }) {
  if (!ALLOWED_ACTIONS.has(action)) return { allowed: false, reason: "action_not_allowed" };
  const repository = validateRepositoryUrl(repositoryUrl);
  if (!repository.ok) return { allowed: false, reason: repository.reason };
  if (action === "propose_patch" || action === "run_ci") {
    const target = validateWorkBranch(branch);
    if (!target.ok) return { allowed: false, reason: target.reason };
    if (action === "propose_patch") {
      const changed = validateChangedPaths(paths);
      if (!changed.ok) return { allowed: false, reason: changed.reason, blocked: changed.blocked };
    }
    if (approved) return { allowed: false, reason: "approval_does_not_enable_implicit_execution" };
  }
  return { allowed: true, action, repository: repository.owner + "/" + repository.repo, branch: branch || null, requiresUserAuthorization: true, writesEnabled: false };
}
