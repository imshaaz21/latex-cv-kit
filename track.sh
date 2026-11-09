#!/usr/bin/env bash
# Track CV versions and applications across branches.
# See the Branch strategy section of README.md.
#
#   ./track.sh private       track config.tex in this clone (private repos only)
#   ./track.sh sent          tag the current job branch as sent, then delete it
#   ./track.sh log           every application you have sent, newest first
#   ./track.sh sync          rebase every profile/* branch onto main
#   ./track.sh diff <name>   what you claimed there vs your CV today
#   ./track.sh open <name>   restore a sent application to a branch to reuse it
set -u
cd "$(dirname "$0")"

die() { echo "$*" >&2; exit 1; }
clean() { git diff-index --quiet HEAD -- || die "Uncommitted changes. Commit or stash first."; }
branch() { git rev-parse --abbrev-ref HEAD; }
tracked() {
  git ls-files --error-unmatch config.tex >/dev/null 2>&1 ||
    die "config.tex is not tracked, so branches carry no CV content. Run: ./track.sh private"
}

case "${1:-}" in

# The template ships with config.tex ignored so nobody publishes their own details
# by accident. Tracking it is what makes the branch workflow work, and it puts your
# personal data in the history permanently, so the repo has to stay private.
private)
  if [ "${2:-}" != "-y" ]; then
    echo "This tracks config.tex, putting your name, contact details and CV content"
    echo "into this repository's history permanently. Only do this if the remote is"
    echo "private and will stay private."
    printf 'Continue? [y/N] '
    read -r a
    case "$a" in y|Y) ;; *) die "Aborted." ;; esac
  fi
  # Drop the whole marked block, so no orphaned comment is left behind. Written
  # with awk rather than sed -i, which needs an argument on BSD sed.
  awk '/^# BEGIN private$/{skip=1} !skip; /^# END private$/{skip=0}' .gitignore \
    > .gitignore.new && mv .gitignore.new .gitignore
  [ -f config.tex ] || cp config.example.tex config.tex
  git add .gitignore config.tex
  echo "config.tex is now tracked. Commit it, and keep this repository private."
  ;;

# A sent application is a record, not a living branch: once it is out the door it
# must never change, or you lose the only proof of what you actually claimed.
# An annotated tag freezes the commit and keeps the date, so the branch can go.
sent)
  b=$(branch)
  case "$b" in job-*) ;; *) die "Not on a job-* branch (on '$b')." ;; esac
  tracked; clean
  name=${b#job-}
  git rev-parse -q --verify "refs/tags/sent/$name" >/dev/null && die "sent/$name already exists."
  git tag -a "sent/$name" -m "Sent $(date +%Y-%m-%d)"
  git checkout -q main
  git branch -q -D "$b"
  echo "Tagged sent/$name and deleted $b. The commit is kept by the tag."
  echo "Anything in it that was not job specific belongs on main: ./track.sh diff $name"
  ;;

log)
  echo "SENT        APPLICATION"
  git for-each-ref refs/tags/sent --sort=-creatordate \
    --format='%(creatordate:short)  %(refname:lstrip=3)'
  ;;

# Only profile branches are kept current, and there are only a few of them, so
# rebasing is cheap. Sent tags are deliberately never touched.
sync)
  tracked; clean
  here=$(branch)
  profiles=$(git for-each-ref refs/heads/profile --format='%(refname:strip=2)')
  [ -n "$profiles" ] || { echo "No profile/* branches yet. See README.md."; exit 0; }
  failed=""
  for p in $profiles; do
    if git rebase -q main "$p" >/dev/null 2>&1; then
      echo "ok        $p"
    else
      git rebase --abort >/dev/null 2>&1 || true
      failed="$failed $p"
      echo "CONFLICT  $p"
    fi
  done
  git checkout -q "$here"
  [ -z "$failed" ] || {
    echo
    echo "Rebase these by hand and resolve:"
    for p in $failed; do echo "  git rebase main $p"; done
    exit 1
  }
  ;;

diff)
  name=${2:-}
  [ -n "$name" ] || die "Usage: ./track.sh diff <name>"
  git rev-parse -q --verify "refs/tags/sent/$name" >/dev/null || die "No sent/$name. Try ./track.sh log"
  git --no-pager diff "sent/$name" main -- config.tex
  ;;

# A sent tag holds that application's config.tex, so checking it out is how you
# reuse the tailoring for a similar role at another company.
open)
  name=${2:-}
  [ -n "$name" ] || die "Usage: ./track.sh open <name>"
  git rev-parse -q --verify "refs/tags/sent/$name" >/dev/null || die "No sent/$name. Try ./track.sh log"
  git checkout -q -b "job-$name-reopened" "sent/$name"
  echo "On job-$name-reopened. Rebase onto main before reusing it, so you pick up"
  echo "anything that has changed since:  git rebase main"
  ;;

*)
  sed -n '3,10p' "$0" | sed 's/^#\{1\} \{0,1\}//'
  exit 1
  ;;
esac
