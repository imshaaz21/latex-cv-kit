# latex-cv-kit

**An ATS-friendly LaTeX CV and cover letter you version control with git. One file of
content, one command to build, one git branch per job application.**

If you apply for more than a handful of jobs, you end up with `CV_final_v3_acme.pdf`
somewhere in Downloads and no idea which version you actually sent. This repo fixes that
with tools you already have: LaTeX for the layout, git branches for the per-job versions,
and a build script that names every PDF after the job it was tailored for.

```
main                    base CV, one page, generic cover letter
├── job-acme-backend    tailored summary, reordered skills, real cover letter
├── job-globex-platform tailored for a different post
└── job-initech-sre     ...
```

`git diff main job-acme-backend -- config.tex` shows you exactly what you claimed to
whom. That is the whole idea.

## What you get

- **One content file.** `config.tex` holds every word a human reads: name, contact,
  summary, experience bullets, projects, education, skills, references and the cover
  letter body. `main.tex` and `cover_letter.tex` are layout only, so tailoring a CV for
  a job never means touching LaTeX internals.
- **A CV and a matching cover letter** from the same source, so the name and contact
  line can never drift apart between the two documents.
- **ATS-friendly output by design.** Single column, standard section headings
  (Summary, Experience, Projects, Education, Skills, References), no tables for skills,
  `glyphtounicode` plus `\pdfgentounicode=1` so text extracted from the PDF is clean, and
  hyphenation disabled so no parser ever reads `microser-vices` as two words.
- **Build guardrails.** `./run.sh` warns if the CV spills past one page and if LaTeX
  reports an overfull box, which is text past the margin and otherwise silent.
- **Per-job output folders.** On a `job-*` branch the build also drops the PDFs and your
  application email into `applications/<Company_Role>/`, which is gitignored, so switching
  branches never overwrites a previous application's files.
- **A pinned toolchain.** `mise.toml` pins TinyTeX, and the build shells out through
  `mise exec`, so the PDF renders the same on any machine rather than depending on what
  happens to be on `PATH`.
- **Optional private cloud mirror.** `./run.sh --upload` copies the outputs to your own
  rclone remote. Plain `./run.sh` is fully offline.

## Quick start

```bash
git clone https://github.com/imshaaz21/latex-cv-kit.git
cd latex-cv-kit
cp config.example.tex config.tex   # your content goes here, and it is gitignored
mise install                       # installs the pinned TinyTeX
./run.sh
```

That writes `Your_Name_CV.pdf` and `Your_Name_Cover_Letter.pdf`, named from `\cvName` in
your `config.tex`, and opens both.

No `mise`? The script falls back to whatever `latexmk` and `pdflatex` are on your `PATH`.
Any TeX Live or MacTeX install works. The engine must stay **pdflatex**: the ATS lines in
the preamble are pdfTeX primitives, so xelatex, lualatex and Tectonic will fail on them.

Missing a LaTeX package under TinyTeX: `mise exec -- tlmgr install <package>`. No sudo
needed, TinyTeX installs in user space.

## Applying for a job

```bash
git checkout main
git checkout -b job-acme-backend

# edit config.tex only: tailor the summary, reorder the skills lines,
# pick the experience bullets that match the post, write the cover letter body
cp email_template.md email.md      # fill in for this company, also gitignored

./run.sh
```

You get `Your_Name_CV_Acme_Backend.pdf` and `Your_Name_Cover_Letter_Acme_Backend.pdf`,
plus a copy of everything in `applications/Acme_Backend/`. The branch name becomes the
filename suffix, so the PDF in your sent mail always tells you which branch produced it.

Keep `main` as the honest, one-page base CV. A fix that is not job specific, a layout bug
or a wrong technical fact, belongs on `main` too, so it reaches every future application
instead of living on one branch.

## Privacy

Your CV is personal data, and a referee's contact details are someone else's personal
data. This repo is set up so neither leaks:

- **`config.tex` is gitignored.** Only `config.example.tex`, which contains nothing but
  placeholders, is tracked. Clone this repo, fill in `config.tex`, and a careless
  `git add -A` followed by a push to a public fork still publishes nothing about you.
- **`email.md` and `applications/` are gitignored** for the same reason. A filled-in
  application email contains a named hiring contact's address.
- **Never put a referee's phone number in the source**, not even in a LaTeX `%` comment.
  Comments are invisible in the PDF but perfectly readable in the repository, and they
  survive in git history after you delete them. Ask each referee before listing them, and
  keep phone numbers out of the file entirely.

**If you want your own CV in git**, which is the point of this repo, use a **private**
repository and track `config.tex` there:

```bash
# in your own private repo, opt into tracking your content
git rm --cached -r --ignore-unmatch .          # if needed
sed -i '/^config\.tex$/d;/^email\.md$/d' .gitignore
git add .gitignore config.tex && git commit -m "Track my CV content"
```

Keep that repository private permanently. Once your content is in the history of a
repository, making it public publishes every past version, and on GitHub a rewritten
history is still reachable through the fork network. The safe order is private first,
and a separate public repository if you ever want to share the layout.

## Repository layout

| Path | What it is |
| :--- | :--- |
| `config.example.tex` | Template content. Copy to `config.tex` and edit. |
| `config.tex` | Your content. Gitignored. The only file you edit per job. |
| `main.tex` | CV layout. Edit to change how it looks, never what it says. |
| `cover_letter.tex` | Cover letter layout. Shares `config.tex` with the CV. |
| `run.sh` | Builds both, names the PDFs, warns on page count and margins. |
| `email_template.md` | Generic application email. Copy to `email.md` per job. |
| `mise.toml` | Pins the TeX toolchain and rclone. |
| `AGENTS.md` | Conventions for coding agents working in this repo. |

## Working with an AI coding agent

`AGENTS.md` carries the rules an agent needs to edit a CV without doing damage: content
lives in `config.tex`, never claim anything unverified, keep `main` to one page, rebuild
before calling it done. Claude Code, Devin, Cursor and Antigravity all read `AGENTS.md`,
and Claude Code also reads it through a `CLAUDE.md` symlink.

## FAQ

**Is this a CV template or a resume template?** Both. The layout is a single-column
reverse-chronological document that suits a technical CV in the UK, Europe, Asia and
Australia, and a one-page resume in the US. Rename the output if you like; nothing in the
build depends on the word.

**Why LaTeX instead of a resume builder?** Because plain text diffs. You can see what
changed between two versions of your CV, revert a bad edit, and keep the typography
stable while the words change. No builder gives you `git diff`.

**Will this pass an ATS?** No template can promise that, since every applicant tracking
system parses differently. What this does is remove the known failure modes: multi-column
layouts, skills in tables, text as graphics, ligature-mangled extracted text and
hyphenated words. Check your own output with `pdftotext main.pdf -` and read what the
parser reads.

**Can I make it two pages?** Yes, drop the one-page warning in `run.sh`. Wrap any role at
risk of splitting across the page break in a `minipage`, so a job and its bullets never
end up visually separated.

**How do I keep the PDFs out of git?** They already are. `*.pdf` is gitignored, so the
only copies are the local build outputs and whatever you attach to an application.

## Licence

[MIT](LICENSE) for the templates and the build script. The placeholder text in
`config.example.tex` is there to be replaced; what you write in your own `config.tex` is
yours.
