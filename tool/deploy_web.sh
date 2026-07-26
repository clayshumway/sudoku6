#!/usr/bin/env bash
# Build the Flutter web app and publish it to the gh-pages branch.
#
# Usage: tool/deploy_web.sh
#
# Everything GitHub Pages needs is regenerated here on purpose:
#   CNAME      - custom domain; Pages drops the domain setting without it,
#                and it lives on gh-pages (not main), so it must be rewritten
#                on every deploy or the domain silently reverts.
#   .nojekyll  - stops Pages from running Jekyll, which would strip Flutter's
#                _-prefixed asset directories.
set -euo pipefail

DOMAIN="s6.clayshumway.com"
BRANCH="gh-pages"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKTREE="$(mktemp -d)"

cd "$REPO_ROOT"

echo "==> Building web (base-href /, served at the domain root)"
flutter build web --base-href /

echo "==> Preparing $BRANCH worktree"
git fetch origin "$BRANCH" --quiet 2>/dev/null || true
if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  git worktree add --quiet "$WORKTREE" "$BRANCH"
else
  git worktree add --quiet --orphan -b "$BRANCH" "$WORKTREE"
fi

# Clear tracked files but keep .git plumbing intact.
find "$WORKTREE" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

cp -R "$REPO_ROOT/build/web/." "$WORKTREE/"
printf '%s\n' "$DOMAIN" > "$WORKTREE/CNAME"
touch "$WORKTREE/.nojekyll"

cd "$WORKTREE"
git add -A
if git diff --cached --quiet; then
  echo "==> No changes to deploy"
else
  git commit --quiet -m "Deploy web build"
  git push --quiet origin "$BRANCH"
  echo "==> Deployed to https://$DOMAIN/"
fi

cd "$REPO_ROOT"
git worktree remove --force "$WORKTREE"
