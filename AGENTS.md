# AGENTS.md

LaTeX CV and cover letter repo. Read this before editing.

## Layout

- `config.tex` is all content (name, summary, experience bullets, projects, education,
  skills, references, cover letter body). It is the only file that changes per job.
  `config.example.tex` is the tracked template it is copied from. In a public clone
  `config.tex` is gitignored; `./track.sh private` tracks it, for private repos only.
- `main.tex` is CV layout only. Do not edit it for wording changes.
- `cover_letter.tex` is cover letter layout, sharing `config.tex` for name and contact.
- `run.sh` builds both, exports PDFs named from `\cvName` plus the branch suffix, and opens
  them. It runs `latexmk`, which reruns as needed. It warns if the CV exceeds one page or
  if any overfull boxes appear.
- `track.sh` manages the branch strategy: `private`, `sent`, `log`, `sync`, `diff`, `open`.
- `mise.toml` pins the TeX toolchain (TinyTeX) and rclone. `run.sh` shells out via
  `mise exec`, so the build does not depend on what happens to be on `PATH`.
- `./run.sh --upload` also mirrors the outputs to a private rclone remote: `CV/` from
  `main`, `CV/<Company_Role>/` from a job branch. Plain `./run.sh` stays offline.
- On a job branch, `run.sh` also copies the PDFs to `applications/<Company_Role>/`
  (gitignored), so branch switches never overwrite an earlier application.
- PDFs and aux files are gitignored. Never hand-edit `main.pdf` or `cover_letter.pdf`.

## Toolchain

- TeX is TinyTeX, installed and pinned by mise (`mise install` in this repo). Without
  mise, `run.sh` falls back to `latexmk` on `PATH`.
- Missing LaTeX package: `mise exec -- tlmgr install <pkg>`. No sudo, TinyTeX is a
  user-mode install.
- The rclone remote defaults to `gdrive`, override with `CV_RCLONE_REMOTE`. Configure once
  with `mise exec -- rclone config`, using a scope that only lets it touch files it
  created. `--upload` fails with a clear message if the remote is missing.
- Engine must stay pdfTeX. The ATS lines (`\input{glyphtounicode}`, `\pdfgentounicode=1`)
  are pdfTeX primitives, so xelatex, lualatex and Tectonic will fail.

## Branching

Three tiers, and changes flow upward only. Never downward into something already sent.

- **`main` is the facts.** Honest, complete, one page. The only branch actively
  maintained. New job, corrected date, layout fix: it goes here.
- **`profile/<archetype>` branches are long lived**, two to four of them, one per kind of
  role rather than one per company. They hold presentation only: summary emphasis, skills
  order, which bullets are included. Keep them rebased with `./track.sh sync`.
- **`job-<company>-<role>` branches are disposable.** Branch from the closest profile,
  edit `config.tex` only, build, send, then `./track.sh sent` to tag it `sent/<name>` and
  delete the branch.

Rules:

- A sent application is a record. Never amend, rebase or merge into a `sent/*` tag, or the
  proof of what was actually claimed is lost.
- Anything not job specific found while tailoring must be cherry-picked to `main` before
  the job branch is tagged, or it dies with the branch.
- Do not create a profile per company. If a job branch needs more than cover letter fields
  and a few words changed, the profile is wrong, not the job branch.

## Content rules

- **Never claim anything not verified.** Check the actual repo or source before writing a
  bullet. Ask the user rather than infer or round up.
- **No em dashes** anywhere: CV, cover letter, or replies to the user. Use commas, colons,
  or a plain break instead.
- **No p-values or statistics jargon** in bullets a recruiter reads. Plain numbers only.
- Do not over-explain internal mechanics a recruiter does not need.
- Pick one spelling convention, British or American, and keep it consistent throughout.
- Private repositories do not get a public link in the CV.

## Privacy

- `config.tex` (unless deliberately tracked), `applications/` and any `email*.md` or
  `notes*.md` are gitignored. Never add them to a public remote, and never move their
  contents into a tracked file.
- Never put a referee's phone number in the source, including in a `%` comment. Comments
  are invisible in the PDF but readable in the repository and in git history.
- A repository that tracks `config.tex` must stay private permanently. Making it public
  publishes every past version, and on GitHub rewritten history stays reachable through
  the fork network.

## Build constraints

- `main` must stay one page. If a change pushes it to two, trim wording first, and only
  then touch spacing (`vmargin`, `titlespacing`, the `\setlist` gaps in `main.tex`).
- Job branches may run to two pages if the user says so, but a role or section must never
  visually split across the page break. Wrap it in a `minipage` if it is at risk.
- Always rebuild with `./run.sh` after wording changes before calling it done. Margin
  overflow is a silent, easy-to-miss failure.

## ATS

- Standard section headings (SUMMARY, EXPERIENCE, PROJECTS, EDUCATION, SKILLS, REFERENCES).
- Single column, no tables for skills or references. Side-by-side `minipage` for references
  is fine, that is not a multi-column layout parsers choke on.
- `\pdfgentounicode=1` and `glyphtounicode` stay in the preamble, keeping extracted PDF
  text clean.
- `\hyphenpenalty=10000` and friends stay on, so no parser sees a split word like
  "microser-vices".
