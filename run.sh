#!/usr/bin/env bash
# Build main.tex and cover_letter.tex, export named PDF copies, open both.
# main.tex and cover_letter.tex are the fixed build sources; the named copies
# below are what you actually send out, e.g. Your_Name_CV_Acme_Backend.pdf.
# With --upload, also copies the outputs to private cloud storage via rclone.
set -e
cd "$(dirname "$0")"

upload=0
[ "${1:-}" = "--upload" ] && upload=1

[ -f config.tex ] || {
  echo "config.tex is missing. Create it from the template:" >&2
  echo "  cp config.example.tex config.tex" >&2
  exit 1
}

# TeX and rclone come from the versions pinned in mise.toml so builds match
# across machines. Without mise, whatever is on PATH is used instead.
if command -v mise >/dev/null 2>&1; then
  tool() { mise exec -- "$@"; }
else
  tool() { "$@"; }
fi
tool latexmk --version >/dev/null 2>&1 || {
  echo "No LaTeX toolchain found. Run: mise install" >&2
  exit 1
}

# Output filenames follow \cvName from config.tex, so nothing here is hardcoded
# to one person. Non-alphanumerics collapse to underscores.
cvname=$(sed -n 's/^\\newcommand{\\cvName}{\(.*\)}[[:space:]]*$/\1/p' config.tex | head -1)
slug=$(printf '%s' "${cvname:-CV}" | tr -d '\\' | sed -E 's/[^A-Za-z0-9]+/_/g; s/^_+|_+$//g')
slug=${slug:-CV}

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)
suffix=$(echo "${branch#job-}" | sed -E 's/[-_]+/_/g; s/(^|_)([a-z])/\1\U\2/g')

# Job branches also copy their outputs to applications/<Company_Role>/ (gitignored),
# so switching branches never overwrites a previous application's files.
dir="applications/$suffix"
[ "$branch" != "main" ] && mkdir -p "$dir"

outputs=()

build() {
  src="$1" pdf="$2" base="$3" label="$4"
  # latexmk reruns as needed; cross-references settle on the second pass.
  tool latexmk -pdf -interaction=nonstopmode -halt-on-error "$src" >/dev/null || { tail -20 "${src%.tex}.log"; exit 1; }
  # Overfull boxes mean text past the margin: silent in the PDF, easy to miss.
  grep -q 'Overfull' "${src%.tex}.log" && echo "WARNING: $label has overfull boxes, check margins"
  tool latexmk -c "$src" >/dev/null 2>&1
  pages=$(pdfinfo "$pdf" | awk '/^Pages:/{print $2}')
  [ "$label" = "CV" ] && [ "$pages" != 1 ] && echo "WARNING: CV is $pages pages, trim to 1"
  name="${base}.pdf"
  [ "$branch" != "main" ] && name="${base}_${suffix}.pdf"
  cp "$pdf" "$name"
  [ "$branch" != "main" ] && cp "$name" "$dir/"
  outputs+=("$name")
  echo "Built $name ($pages page)"
  xdg-open "$name" >/dev/null 2>&1 &
}

build main.tex main.pdf "${slug}_CV" CV
build cover_letter.tex cover_letter.pdf "${slug}_Cover_Letter" "Cover Letter"
# Plain if, not an && chain: on main the chain short-circuits and its non-zero
# status becomes the script's exit code, making a clean build look like a failure.
if [ "$branch" != "main" ] && [ -f email.md ]; then
  cp email.md "$dir/"
  echo "Saved to $dir/"
fi

# --upload mirrors the outputs to cloud storage so they can be fetched from any
# device. The remote is private to whoever authorised it; nothing is shared.
if [ "$upload" = 1 ]; then
  remote="${CV_RCLONE_REMOTE:-gdrive}"
  tool rclone listremotes 2>/dev/null | grep -qx "$remote:" || {
    echo "rclone remote '$remote' is not configured. Set it up with:" >&2
    echo "  mise exec -- rclone config" >&2
    exit 1
  }
  gdest="CV"
  [ "$branch" != "main" ] && gdest="CV/$suffix"
  for f in "${outputs[@]}"; do
    tool rclone copy "$f" "$remote:$gdest/"
  done
  if [ "$branch" != "main" ] && [ -f email.md ]; then
    tool rclone copy email.md "$remote:$gdest/"
  fi
  echo "Uploaded to $remote:$gdest/"
fi
