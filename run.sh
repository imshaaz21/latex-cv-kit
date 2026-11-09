#!/usr/bin/env bash
# Build the CV and cover letter, export PDFs named for the current job branch.
#
#   ./run.sh            build and open both documents
#   ./run.sh --upload    also mirror the outputs to your rclone remote
set -e
cd "$(dirname "$0")"

upload=0
[ "${1:-}" = "--upload" ] && upload=1

[ -f config.tex ] || {
  echo "config.tex is missing. Create it from the template:" >&2
  echo "  cp config.example.tex config.tex" >&2
  exit 1
}

# TeX and rclone come from the versions pinned in mise.toml, so the PDF renders
# identically on any machine. Without mise, whatever is on PATH is used.
if command -v mise >/dev/null 2>&1; then
  tool() { mise exec -- "$@"; }
else
  tool() { "$@"; }
fi
tool latexmk --version >/dev/null 2>&1 || {
  echo "No LaTeX toolchain found. Run 'mise install', or install TeX Live or MacTeX." >&2
  exit 1
}

# Optional: the page-count check needs pdfinfo (poppler), the preview needs an opener.
have_pdfinfo=0
command -v pdfinfo >/dev/null 2>&1 && have_pdfinfo=1
opener=""
for o in xdg-open open; do
  command -v "$o" >/dev/null 2>&1 && { opener="$o"; break; }
done

# Output filenames follow \cvName from config.tex, so nothing is hardcoded to one
# person. Non-alphanumerics collapse to underscores.
cvname=$(sed -n 's/^\\newcommand{\\cvName}{\(.*\)}[[:space:]]*$/\1/p' config.tex | head -1)
slug=$(printf '%s' "${cvname:-CV}" | tr -d '\\' | sed -E 's/[^A-Za-z0-9]+/_/g; s/^_+|_+$//g')
slug=${slug:-CV}
[ "$cvname" = "Jane Doe" ] &&
  echo "WARNING: config.tex still has the sample content, replace it before sending"

# job-acme-backend becomes the suffix Acme_Backend. Done in bash rather than with
# sed's \U, which is a GNU extension and fails on BSD sed.
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)
suffix=""
if [ "$branch" != "main" ]; then
  rest=${branch#job-}
  old_ifs=$IFS; IFS='-_'; read -ra parts <<<"$rest"; IFS=$old_ifs
  for p in "${parts[@]}"; do
    [ -n "$p" ] || continue
    head_char=$(printf '%s' "${p%"${p#?}"}" | tr '[:lower:]' '[:upper:]')
    suffix="${suffix:+${suffix}_}${head_char}${p#?}"
  done
  : "${suffix:=Job}"
fi

# Job branches copy their outputs to applications/<Company_Role>/ (gitignored), so
# switching branches never overwrites an earlier application's files.
dir="applications/$suffix"
[ -n "$suffix" ] && mkdir -p "$dir"

outputs=()

build() {
  src="$1" pdf="$2" base="$3" label="$4"
  # latexmk reruns pdflatex as needed for cross-references to settle.
  tool latexmk -pdf -interaction=nonstopmode -halt-on-error "$src" >/dev/null ||
    { tail -20 "${src%.tex}.log"; exit 1; }
  # An overfull box is text past the margin: invisible in the log unless you look.
  grep -q 'Overfull' "${src%.tex}.log" && echo "WARNING: $label has overfull boxes, check the margins"
  tool latexmk -c "$src" >/dev/null 2>&1

  name="${base}.pdf"
  [ -n "$suffix" ] && name="${base}_${suffix}.pdf"
  cp "$pdf" "$name"
  [ -n "$suffix" ] && cp "$name" "$dir/"
  outputs+=("$name")

  if [ "$have_pdfinfo" = 1 ]; then
    pages=$(pdfinfo "$pdf" | awk '/^Pages:/{print $2}')
    [ "$label" = "CV" ] && [ "$pages" != 1 ] &&
      echo "WARNING: the CV is $pages pages, trim it to 1"
    echo "Built $name ($pages page)"
  else
    echo "Built $name (install poppler for the page-count check)"
  fi
  [ -n "$opener" ] && "$opener" "$name" >/dev/null 2>&1 &
}

build main.tex main.pdf "${slug}_CV" CV
build cover_letter.tex cover_letter.pdf "${slug}_Cover_Letter" "Cover Letter"
# A plain if, not an && chain: on main the chain short-circuits and its non-zero
# status becomes the script's exit code, making a clean build look like a failure.
if [ -n "$suffix" ]; then
  echo "Copied to $dir/"
fi

# --upload mirrors the outputs to cloud storage so they can be fetched from another
# device. The remote is private to whoever authorised it; nothing is shared.
if [ "$upload" = 1 ]; then
  remote="${CV_RCLONE_REMOTE:-gdrive}"
  tool rclone listremotes 2>/dev/null | grep -qx "$remote:" || {
    echo "The rclone remote '$remote' is not configured. Set it up with:" >&2
    echo "  mise exec -- rclone config" >&2
    exit 1
  }
  dest="CV"
  [ -n "$suffix" ] && dest="CV/$suffix"
  for f in "${outputs[@]}"; do
    tool rclone copy "$f" "$remote:$dest/"
  done
  echo "Uploaded to $remote:$dest/"
fi
