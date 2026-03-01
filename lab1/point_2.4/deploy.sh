#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-lab1}"
SHA="${2:-}"
REPO_FULL="${3:-}"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_BASE="${DEPLOY_BASE:-"$BASE_DIR/_deploy"}"
REPO_URL="${REPO_URL:-"https://github.com/dmitrievsn/catty-reminders-app"}"

WORKTREE="$DEPLOY_BASE/worktree"
VENV_DIR="$DEPLOY_BASE/venv"
LOCKFILE="$DEPLOY_BASE/deploy.lock"
LOGFILE="$DEPLOY_BASE/deploy.log"
TMP_PORT="${TMP_PORT:-9181}"

mkdir -p "$DEPLOY_BASE"
exec >>"$LOGFILE" 2>&1

post_status() {
  local state="$1" desc="$2"
  if [[ -z "${GITHUB_TOKEN:-}" || -z "$SHA" || -z "$REPO_FULL" ]]; then
    return 0
  fi
  local owner="${REPO_FULL%%/*}"
  local repo="${REPO_FULL##*/}"
  local data
  data=$(printf '{"state":"%s","context":"lab1/autodeploy","description":"%s"}' "$state" "$desc")
  curl -fsS -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${owner}/${repo}/statuses/${SHA}" \
    -d "$data" >/dev/null || true
}

trap 'rc=$?; if [[ $rc -ne 0 ]]; then post_status failure "deploy failed"; fi' EXIT
post_status pending "deploy started"

exec 9>"$LOCKFILE"
flock 9

echo "=== $(date -Is) deploy branch=$BRANCH repo=$REPO_URL sha=$SHA ==="

if [ ! -d "$WORKTREE/.git" ]; then
  git clone "$REPO_URL" "$WORKTREE"
fi

cd "$WORKTREE"
git fetch --prune origin

if ! git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  echo "branch origin/$BRANCH not found"
  git branch -r
  exit 1
fi

git checkout -B "$BRANCH" "origin/$BRANCH"
git reset --hard "origin/$BRANCH"

python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install -U pip wheel >/dev/null
"$VENV_DIR/bin/pip" install -r requirements.txt >/dev/null

"$BASE_DIR/test.sh" "$TMP_PORT" "$VENV_DIR"

systemctl restart catty-app.service
systemctl is-active --quiet catty-app.service

echo "$(date -Is) OK branch=$BRANCH" | tee "$DEPLOY_BASE/last_deploy.txt"
post_status success "deploy succeeded"
trap - EXIT

echo "=== $(date -Is) done ==="
