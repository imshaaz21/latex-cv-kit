# Guide

Detail that does not belong in the README. Start there if you have not read it.

## Requirements

git, bash, and a TeX distribution providing `pdflatex` and `latexmk`.
[mise](https://mise.jdx.dev) is optional and recommended: `mise.toml` pins TinyTeX, so the
PDF renders identically on any machine. `pdfinfo` from poppler enables the page-count
check and `rclone` enables `--upload`. The build works without either.

The engine must be pdfTeX. `\input{glyphtounicode}` and `\pdfgentounicode=1` are pdfTeX
primitives, so xelatex, lualatex and Tectonic will fail on this preamble.

Missing a LaTeX package under TinyTeX: `mise exec -- tlmgr install <package>`. No sudo
needed, TinyTeX installs in user space.

## Platforms

| Platform | Notes |
| :--- | :--- |
| Linux | Native |
| macOS | Native. The scripts avoid GNU-only `sed` so they work with BSD userland |
| Windows | Git Bash, which ships with Git for Windows, or WSL. `.gitattributes` pins LF endings so the scripts stay executable |

CI runs the workflow test suite on all three on every push.

## No local TeX install

Overleaf compiles this unmodified:

1. Download the repository as a zip and upload it with **New Project**, **Upload Project**.
2. Rename `config.example.tex` to `config.tex`.
3. In **Menu**, set **Compiler** to **pdfLaTeX** and **Main document** to `main.tex`.

You lose the branch workflow, since that is local git, but the documents build.

## Why a sent application becomes a tag

Once an application is out the door it is a record, and a record that can still be edited
is not evidence of anything. `./track.sh sent` freezes the commit as an annotated tag
carrying the date, then deletes the branch. The branch list stays at three or four while
the history stays complete, and you keep a permanent answer to what a particular employer
actually read.

Two rules follow. Never merge `main` into a sent application, because backporting a later
fix into something already submitted falsifies it. And cherry-pick anything that was not
job specific onto `main` before retiring the branch, or it dies with the branch.

## Keeping profiles current

Run `./track.sh sync` after any change to `main`. Only the handful of profile branches are
kept current, which is what makes this survive a real job search. Conflicts are reported
per profile and the rebase is aborted rather than left half-applied, and a dirty working
tree is refused.

Comparing two applications is plain git:

```bash
git diff sent/acme-backend sent/globex-sre -- config.tex
```

## Privacy

`config.tex` is gitignored, so cloning this repository and filling it in cannot publish
your details by accident. Built PDFs and `applications/` are ignored too.

The branch workflow needs `config.tex` tracked, and tracking it puts your name, contact
details and employment history into the history permanently. That is only safe in a
**private** repository:

```bash
./track.sh private      # un-ignores and stages config.tex, after confirming
git commit -m "Track my CV content"
```

Keep that repository private. Making it public later publishes every past version, and on
GitHub a rewritten history remains reachable through the fork network. If you want to
share your layout, publish a separate repository rather than changing the visibility of
this one.

Never put a referee's phone number in the source, not even in a `%` comment. LaTeX
comments are invisible in the PDF and perfectly readable in the repository, and they
survive in git history long after you delete them. Ask each referee before listing them.

## ATS

Applicant tracking systems parse PDFs, and what breaks them is layout rather than wording.

| Known failure mode | What this does about it |
| :--- | :--- |
| Columns are read across the page and interleave | Single column. The side-by-side referees use `minipage`, read in order |
| Tables are skipped or flattened | No tables anywhere |
| Contact details in a page header are dropped as boilerplate | `\pagestyle{empty}`, contact line in the body |
| Icon fonts extract as `□`, `?` or a glyph name | No icons. Text and `\|` separators only |
| Ligatures and custom encodings mangle extracted text | `glyphtounicode` with `\pdfgentounicode=1` |
| Hyphenated line breaks parse as two words | Hyphenation disabled, body text ragged right so the spacing still looks right |
| Invented headings hide your Experience section | Standard headings only |

No template can promise to pass a specific system, and anyone saying otherwise is
guessing. Read your own output the way a parser does:

```bash
pdftotext main.pdf -
```

If the headings are in order and no word is split, the layout is doing its job. CI runs
that same check on every push.

## Adding a section

Define the content in `config.tex`:

```latex
\newcommand{\cvCertifications}{%
  \textbf{CKA: Certified Kubernetes Administrator}, The Linux Foundation \hfill {\color{muted}2025}\\
  \textbf{AWS Solutions Architect, Associate}, Amazon Web Services \hfill {\color{muted}2024}
}
```

and place it in `main.tex` where you want it to appear:

```latex
\section{Certifications}
\cvCertifications
```

Publications, talks, languages and volunteering follow the same pattern. Keep the heading
conventional if an ATS will read the document.

## Repository layout

```text
config.example.tex    sample content, fictional and complete
config.tex            your content (gitignored by default)
main.tex              CV layout
cover_letter.tex      cover letter layout, sharing config.tex
run.sh                build, name the PDFs, check pages and margins
track.sh              start, send, log, sync, diff and reopen applications
mise.toml             pinned TeX toolchain
AGENTS.md             instructions for coding agents
docs/                 preview images and this guide
tests/workflow.sh     end-to-end test of the branch workflow
.github/workflows/    CI: three platforms, lint, build, parser check
```

There is deliberately no Makefile or task runner. The two scripts are the interface, and a
third file wrapping them would be indirection rather than convenience.

On a job branch the build also copies its outputs to `applications/<Company_Role>/`, which
is gitignored, so switching branches never overwrites an earlier application's files.
`./run.sh --upload` mirrors them to your own rclone remote, defaulting to one named
`gdrive` and overridable with `CV_RCLONE_REMOTE`. Plain `./run.sh` is entirely offline.

## Tests

```bash
./tests/workflow.sh
```

Nineteen assertions against a throwaway clone: that a fresh clone will not leak personal
data, that `private` opts in cleanly, that an application can be started, sent, logged,
diffed and reopened, that `sync` brings profiles forward without rewriting a sent tag, and
that a dirty tree is refused without leaving a rebase half-applied. It needs only git and
bash, which is why it runs on all three platforms. It clones the committed state, so
commit before running it.

## What this is not

- Not a resume builder. No interface, no service, no account. If you would rather fill in
  a form than edit a text file, this is the wrong tool.
- Not a guarantee about any applicant tracking system.
- Not restylable without reading some LaTeX. The content split spares you that for
  ordinary use, but changing the design means editing `main.tex`.
- Not safe as a public repository once you track your own `config.tex`.
- Opinionated about length. One page is the default because it is right for most
  engineers. Remove the check in `run.sh` if you disagree.
