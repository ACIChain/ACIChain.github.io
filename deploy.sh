#!/bin/zsh
# Deploy demo site to the anonymous account's GitHub Pages.
# Usage: ./deploy.sh <anonymous-username>
# Prereq: `gh auth login -h github.com` done for the anonymous account, and it is
# the active account (`gh auth status` shows it as active).
set -e
USER="${1:?usage: ./deploy.sh <anonymous-username>}"
cd "$(dirname "$0")"

gh auth status >/dev/null 2>&1 || { echo "gh not authenticated"; exit 1; }
ACTIVE=$(gh api user --jq .login)
if [[ "$ACTIVE" != "$USER" ]]; then
  echo "Active gh account is '$ACTIVE', not '$USER'. Switch first:"
  echo "  gh auth switch -h github.com -u $USER"
  exit 1
fi

REPO="$USER.github.io"
gh repo view "$USER/$REPO" >/dev/null 2>&1 || gh repo create "$REPO" --public --description "ACIChain demo website"
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$USER/$REPO.git"
git push -u origin main
gh api -X PATCH "/repos/$USER/$REPO" -f has_pages=true >/dev/null 2>&1 || true
gh api -X POST "/repos/$USER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 || true
echo "Deployed. Site will be at https://$USER.github.io/ (Pages may take ~1 min)"
