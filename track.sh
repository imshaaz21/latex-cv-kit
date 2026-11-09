#!/usr/bin/env bash
# Manage CV versions and job applications. See the Branch strategy section of README.md.
#
#   ./track.sh private              track config.tex in this clone (private repos only)
#   ./track.sh start <name> [base]  branch job-<name> from base, default main
#   ./track.sh sent                 tag the current job branch as sent, then delete it
#   ./track.sh log                  applications sent, newest first
#   ./track.sh sync                 rebase every profile/* branch onto main
#   ./track.sh diff <name>          what you claimed there against your CV today
#   ./track.sh open <name>          restore a sent application to a branch for reuse
set -u
cd "$(dirname "$0")"

die() { echo "$*" >&2; exit 1; }
exists() { git rev-parse -q --verify "$1" >/dev/null; }
branch() { git rev-parse --abbrev-ref HEAD; }
need() { [ -n "${1:-}" ] || die "Usage: ./track.sh $2"; }
clean() { git diff-index --quiet HEAD -- || die "Uncommitted changes. Commit or stash first."; }
tracked() {
  git ls-files --error-unmatch config.tex >/dev/null 2>&1 ||
    die "config.tex is not tracked, so branches would carry no CV content. Run: ./track.sh private"
}
sent_tag() {
  exists "refs/tags/sent/$1" || die "No sent/$1. See ./track.sh log for what exists."
}

case "${1:-}" in

# The template ships with config.tex ignored so nobody publishes their own details by
# accident. Tracking it is what makes the branch workflow work, and it puts personal
# data in the history permanently, so the repository has to stay private.
private)
  if [ "${2:-}" != "-y" ]; then
    echo "This tracks config.tex, putting your name, contact details and CV content"
    echo "into this repository's history permanently. Only continue if the remote is"
    echo "private and will stay private."
    printf 'Continue? [y/N] '
    read -r reply
    case "$reply" in y | Y) ;; *) die "Aborted." ;; esac
  fi
  # Drop the whole marked block, so no orphaned comment is left behind. Written with
  # awk rather than sed -i, which needs an argument on BSD sed.
  awk '/^# BEGIN private$/{skip=1} !skip; /^# END private$/{skip=0}' .gitignore \
    > .gitignore.new && mv .gitignore.new .gitignore
  [ -f config.tex ] || cp config.example.tex config.tex
  git add .gitignore config.tex
  echo "config.tex is now tracked. Commit it, and keep this repository private."
  ;;

# One command for the start of an application, so the ritual is not three commands
# you have to remember in order.
start)
  name=${2:-}
  need "$name" "start <name> [base]"
  base=${3:-main}
  tracked
  clean
  exists "refs/heads/$base" || die "No branch '$base'. See: git branch"
  exists "refs/heads/job-$name" && die "job-$name already exists."
  exists "refs/tags/sent/$name" &&
    die "You already sent sent/$name. Reuse it with: ./track.sh open $name"
  git checkout -q -b "job-$name" "$base"
  echo "On job-$name, branched from $base."
  echo "Next: edit config.tex, ./run.sh, commit, then ./track.sh sent"
  ;;

# A sent application is a record, not a living branch: once it is out the door it must
# never change, or the only evidence of what was claimed is lost. An annotated tag
# freezes the commit and keeps the date, so the branch itself can go.
sent)
  b=$(branch)
  case "$b" in job-*) ;; *) die "Not on a job-* branch (on '$b')." ;; esac
  tracked
  clean
  name=${b#job-}
  exists "refs/tags/sent/$name" && die "sent/$name already exists."
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

# Only profile branches are kept current, and there are a few of them at most, so
# rebasing is cheap. Sent tags are deliberately never touched.
sync)
  tracked
  clean
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
  need "${2:-}" "diff <name>"
  sent_tag "$2"
  git --no-pager diff "sent/$2" main -- config.tex
  ;;

# A sent tag holds that application's config.tex, so checking it out is how you reuse
# the tailoring for a similar role at another company.
open)
  need "${2:-}" "open <name>"
  sent_tag "$2"
  git checkout -q -b "job-$2-reopened" "sent/$2"
  echo "On job-$2-reopened. Rebase onto main before reusing it, so you pick up"
  echo "anything that has changed since:  git rebase main"
  ;;

*)
  # Print the usage block from this file's own header, so the two cannot drift.
  awk 'NR>2 && /^#/ { sub(/^# ?/, ""); if ($0 != "") print; next } NR>2 { exit }' "$0"
  exit 1
  ;;
esac
