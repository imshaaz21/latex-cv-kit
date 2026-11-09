# AGENTS.md

LaTeX CV and cover letter repo. Read this before editing.

## Layout

- `config.tex` is all content (name, summary, experience bullets, projects, education,
  skills, references, cover letter body). It is the only file that changes per job, and it
  is gitignored. `config.example.tex` is the tracked template it is copied from.
- `main.tex` is CV layout only. Do not edit it for wording changes.
- `cover_letter.tex` is cover letter layout, sharing `config.tex` for name and contact.
- `run.sh` builds both, exports PDFs named from `\cvName` plus the branch suffix, and opens
  them. It runs `latexmk`, which reruns as needed. It warns if the CV exceeds one page or
  if any overfull boxes appear.
- `mise.toml` pins the TeX toolchain (TinyTeX) and rclone. `run.sh` shells out via
  `mise exec`, so the build does not depend on what happens to be on `PATH`.
- `./run.sh --upload` also mirrors the outputs to a private rclone remote: `CV/` from
  `main`, `CV/<Company_Role>/` from a job branch. Plain `./run.sh` stays offline.
- `email_template.md` is the generic application email. Each job branch copies it to
  `email.md` and fills it in. Same content rules as the CV.
- On a job branch, `run.sh` also copies the PDFs and `email.md` to
  `applications/<Company_Role>/` (gitignored), so branch switches never overwrite an
  earlier application.
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

- `main` is the base CV, kept to one page, with a generic cover letter placeholder.
- Per job: `git checkout -b job-<company>` from `main`, edit `config.tex` only, commit.
- Per job: also add `email.md` from `email_template.md` on the job branch.
- A fix that is not job specific (layout bug, wrong technical fact) belongs on `main` too.
  Do not let it live only on a job branch.

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

- `config.tex`, `email.md` and `applications/` are gitignored. Never add them to a public
  remote, and never move their contents into a tracked file.
- Never put a referee's phone number in the source, including in a `%` comment. Comments
  are invisible in the PDF but readable in the repository and in git history.

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
