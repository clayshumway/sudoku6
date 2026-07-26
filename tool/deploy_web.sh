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
# flutter build web does not prune the output dir, so files from an older
# build (e.g. a service worker from before --pwa-strategy=none) would
# otherwise be redeployed forever.
rm -rf "$REPO_ROOT/build/web"
# --pwa-strategy=none: Flutter's service worker is deprecated, and on GitHub
# Pages it stacks a second cache layer on top of the 600s max-age Pages already
# sends -- which meant a deploy could stay invisible until a manual hard
# refresh. Dropping it costs offline asset caching (the game itself still runs
# entirely client-side) and buys deploys that actually show up.
flutter build web --base-href / --pwa-strategy=none

# Give main.dart.js a per-build URL. Pages caches by URL and we can't set
# headers on it, so a changed query string is the only reliable way to stop a
# browser serving yesterday's bundle from disk.
BUILD_ID="$(git rev-parse --short HEAD)-$(date +%s)"
BOOTSTRAP="$REPO_ROOT/build/web/flutter_bootstrap.js"
INDEX="$REPO_ROOT/build/web/index.html"

# Version the whole load chain, not just the last link. index.html ->
# flutter_bootstrap.js -> main.dart.js: leaving the bootstrap unversioned
# meant a cached bootstrap kept requesting the *previous* build's
# main.dart.js, so deploys still looked stale even with a busted bundle URL.
if [ -f "$BOOTSTRAP" ]; then
  perl -pi -e "s{\"mainJsPath\":\"main\.dart\.js\"}{\"mainJsPath\":\"main.dart.js?v=$BUILD_ID\"}g" "$BOOTSTRAP"
fi
if [ -f "$INDEX" ]; then
  perl -pi -e "s{flutter_bootstrap\.js(\?v=[^\"']*)?}{flutter_bootstrap.js?v=$BUILD_ID}g" "$INDEX"
fi
echo "==> Cache-busted bootstrap + bundle as v=$BUILD_ID"

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
