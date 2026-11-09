#!/usr/bin/env bash
# Exercises the branch workflow end to end in a throwaway clone. Needs git and bash,
# but no TeX, so it runs identically on Linux, macOS and Windows under Git Bash.
#
# It clones the committed state of the repository, so commit before running it.
set -eu

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0

check() {
  if [ "$2" = 0 ]; then
    printf '  ok    %s\n' "$1"; pass=$((pass + 1))
  else
    printf '  FAIL  %s\n' "$1"; fail=$((fail + 1))
  fi
}
ok() { "$@" >/dev/null 2>&1 && echo 0 || echo 1; }
refuses() { "$@" >/dev/null 2>&1 && echo 1 || echo 0; }

git clone -q "$repo" "$tmp/work"
cd "$tmp/work"
git config user.email test@example.com
git config user.name "Workflow Test"

echo "A fresh clone protects personal data"
check "config.tex is ignored by default" "$(ok git check-ignore -q config.tex)"
check "track.sh refuses to start without tracked content" "$(refuses ./track.sh start acme)"
check "config.example.tex is tracked" "$(ok git ls-files --error-unmatch config.example.tex)"

echo "Opting a private clone in"
./track.sh private -y >/dev/null
check "config.tex is no longer ignored" "$(refuses git check-ignore -q config.tex)"
check "config.tex is staged" "$(ok git ls-files --error-unmatch config.tex)"
check ".gitignore still protects applications/" "$(ok grep -qx 'applications/' .gitignore)"
git commit -q -m "Track CV content"

echo "Starting and sending an application"
./track.sh start acme-backend >/dev/null
check "job-acme-backend is checked out" "$([ "$(git rev-parse --abbrev-ref HEAD)" = job-acme-backend ] && echo 0 || echo 1)"
printf '\n%% tailored for Acme\n' >> config.tex
git commit -q -am "Acme application"
./track.sh sent >/dev/null
check "sent/acme-backend tag exists" "$(ok git rev-parse -q --verify refs/tags/sent/acme-backend)"
check "the job branch is gone" "$(refuses git rev-parse -q --verify refs/heads/job-acme-backend)"
check "back on main" "$([ "$(git rev-parse --abbrev-ref HEAD)" = main ] && echo 0 || echo 1)"
check "log lists the application" "$(ok sh -c './track.sh log | grep -q acme-backend')"
check "a second start under the same name is refused" "$(refuses ./track.sh start acme-backend)"

echo "Keeping profiles current"
git checkout -q -b profile/backend
printf '%% backend profile\n' >> config.tex
git commit -q -am "Backend profile"
git checkout -q main
printf '%% new role on main\n' >> config.tex
git commit -q -am "New role"
./track.sh sync >/dev/null
check "profile/backend picked up the change to main" \
  "$(ok sh -c 'git show profile/backend:config.tex | grep -q "new role on main"')"
check "the sent tag was not rewritten" \
  "$(refuses sh -c 'git show sent/acme-backend:config.tex | grep -q "new role on main"')"
check "back on the original branch after sync" "$([ "$(git rev-parse --abbrev-ref HEAD)" = main ] && echo 0 || echo 1)"

echo "Reading and reusing what was sent"
check "diff reports what changed since" "$(ok sh -c './track.sh diff acme-backend | grep -q "new role on main"')"
./track.sh open acme-backend >/dev/null
check "the sent application reopens on a branch" \
  "$([ "$(git rev-parse --abbrev-ref HEAD)" = job-acme-backend-reopened ] && echo 0 || echo 1)"

echo "Refusing to work on a dirty tree"
printf '%% uncommitted\n' >> config.tex
check "sync refuses uncommitted changes" "$(refuses ./track.sh sync)"
check "no rebase was left in progress" \
  "$([ ! -d .git/rebase-merge ] && [ ! -d .git/rebase-apply ] && echo 0 || echo 1)"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
