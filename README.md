# latex-cv-kit

**An ATS-friendly LaTeX CV and cover letter you version control with git. One content
file, one build command, one branch per job application.**

If you apply for more than a handful of jobs, you end up with `CV_final_v3_acme.pdf`
somewhere in Downloads and no idea which version you actually sent. This fixes that with
tools you already have: LaTeX for the layout, git branches and tags for the per-job
versions, and a build script that names every PDF after the job it was tailored for.

```
main                          your facts: honest, complete, one page
├── profile/backend           long lived: how you present for backend roles
│   └── job-acme-backend      short lived: tailored, sent, then tagged sent/acme-backend
└── profile/platform          long lived: how you present for platform and SRE roles
    └── job-globex-sre        short lived
```

Before an interview, `./track.sh diff acme-backend` shows you exactly what that company
read, compared with your CV today. That is the whole idea.

## What you get

- **One content file.** `config.tex` holds every word a human reads: name, contact,
  summary, experience bullets, projects, education, skills, references and the cover
  letter body. `main.tex` and `cover_letter.tex` are layout only, so tailoring a CV for a
  job never means touching LaTeX internals.
- **A CV and a matching cover letter** from the same source, so the name and contact line
  can never drift apart between the two documents.
- **ATS-friendly output by design.** Single column, standard section headings (Summary,
  Experience, Projects, Education, Skills, References), no tables for skills,
  `glyphtounicode` plus `\pdfgentounicode=1` so text extracted from the PDF is clean, and
  hyphenation disabled so no parser ever reads `microser-vices` as two words.
- **A branch strategy that scales**, with `./track.sh` to keep it aligned. See below.
- **Build guardrails.** `./run.sh` warns if the CV spills past one page and if LaTeX
  reports an overfull box, which is text past the margin and otherwise silent.
- **Per-job output folders.** On a `job-*` branch the build also drops the PDFs into
  `applications/<Company_Role>/`, which is gitignored, so switching branches never
  overwrites a previous application's files.
- **A pinned toolchain.** `mise.toml` pins TinyTeX and the build shells out through
  `mise exec`, so the PDF renders the same on any machine rather than depending on what
  happens to be on `PATH`.
- **Optional private cloud mirror.** `./run.sh --upload` copies the outputs to your own
  rclone remote. Plain `./run.sh` is fully offline.

## Quick start

```bash
git clone https://github.com/imshaaz21/latex-cv-kit.git my-cv
cd my-cv
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

## Branch strategy

This is the part that matters, and the part most people get wrong by keeping forty
near-identical branches alive forever. Three tiers, and changes only ever flow upward.

**1. `main` is your facts.** Everything true about you, honest and complete, kept to one
page. It is the only branch you actively maintain. A new job, a corrected date, a layout
fix: it goes here, and every future application inherits it.

**2. `profile/*` branches are how you present, not what you did.** Most people apply to
two or three kinds of role, not forty different ones. A profile holds only the differences
for one archetype: a summary that leads with that stack, the skills lines reordered, a
different selection of experience bullets. Keep two to four, never one per company.

```bash
git checkout main
git checkout -b profile/backend   # edit config.tex, commit
```

**3. `job-*` branches are disposable.** Branch from the closest profile, tailor for that
specific post, build, send, and then retire the branch:

```bash
git checkout profile/backend
git checkout -b job-acme-backend
# edit config.tex: the cover letter fields, and any wording the post calls for
./run.sh                          # Your_Name_CV_Acme_Backend.pdf
git commit -am "Acme backend application"
./track.sh sent                   # tags sent/acme-backend, deletes the branch
```

### The rules that make it work

- **A sent application is a record, not a living branch.** Once it is out the door it must
  never change, or you lose the only proof of what you actually claimed. `./track.sh sent`
  freezes it as an annotated tag and deletes the branch, so your branch list stays short
  while the history stays complete.
- **Never merge `main` into a sent application.** Backporting a later fix into the record
  of something you already sent falsifies it.
- **Anything not job specific goes up to `main` immediately.** If you fix a wrong
  technical fact or a layout bug while tailoring, cherry-pick it to `main` before you tag,
  or it dies with the branch.
- **Only profiles get kept current.** There are a handful of them, so this is cheap.

### Staying aligned

```bash
./track.sh sync                  # rebase every profile/* onto main, report conflicts
./track.sh log                   # every application you sent, newest first
./track.sh diff acme-backend     # what you claimed there vs your CV today
./track.sh open acme-backend     # reuse that tailoring for a similar role elsewhere
```

Run `./track.sh sync` after any change to `main`. Conflicts are reported per profile
rather than left half-applied, and it refuses to run with a dirty tree. Comparing two
applications is plain git: `git diff sent/acme-backend sent/globex-sre -- config.tex`.

### Tracking your own content

The template ships with `config.tex` gitignored, so nobody publishes their own phone
number by accident. The branch workflow needs it tracked, and that puts your personal data
in the history permanently, so it is only safe in a **private** repository:

```bash
./track.sh private               # un-ignores and stages config.tex, after confirming
git commit -m "Track my CV content"
```

## Privacy

Your CV is personal data, and a referee's contact details are someone else's personal
data. This repo is set up so neither leaks:

- **`config.tex` is gitignored by default.** Only `config.example.tex`, which contains
  nothing but placeholders, is tracked. Clone this, fill in `config.tex`, and a careless
  `git add -A` followed by a push to a public fork still publishes nothing about you.
- **`applications/` is gitignored** for the same reason, along with every built PDF.
- **Never put a referee's phone number in the source**, not even in a LaTeX `%` comment.
  Comments are invisible in the PDF but perfectly readable in the repository, and they
  survive in git history long after you delete them. Ask each referee before listing them,
  and keep phone numbers out of the file entirely.

Once your content is in a repository's history, making that repository public publishes
every past version, and on GitHub a rewritten history is still reachable through the fork
network. The safe order is private first, and a separate public repository if you ever
want to share the layout.

## Repository layout

| Path | What it is |
| :--- | :--- |
| `config.example.tex` | Template content. Copy to `config.tex` and edit. |
| `config.tex` | Your content. Gitignored by default. The only file you edit per job. |
| `main.tex` | CV layout. Edit to change how it looks, never what it says. |
| `cover_letter.tex` | Cover letter layout. Shares `config.tex` with the CV. |
| `run.sh` | Builds both, names the PDFs, warns on page count and margins. |
| `track.sh` | Tags sent applications, keeps profiles rebased, diffs what you sent. |
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
Australia, and a one-page resume in the US. Rename the output if you like, nothing in the
build depends on the word.

**Why LaTeX instead of a resume builder?** Because plain text diffs. You can see what
changed between two versions of your CV, revert a bad edit, and keep the typography stable
while the words change. No builder gives you `git diff`.

**Will this pass an ATS?** No template can promise that, since every applicant tracking
system parses differently. What this does is remove the known failure modes: multi-column
layouts, skills in tables, text as graphics, ligature-mangled extracted text and
hyphenated words. Check your own output with `pdftotext main.pdf -` and read what the
parser reads.

**Can I make it two pages?** Yes, drop the one-page warning in `run.sh`. Wrap any role at
risk of splitting across the page break in a `minipage`, so a job and its bullets never
end up visually separated.

**Do I need the profile tier?** No. For a handful of applications, branch `job-*` straight
off `main` and ignore profiles entirely. Add them when you notice you are making the same
three edits every time.

## Licence

[MIT](LICENSE) for the templates and the scripts. The placeholder text in
`config.example.tex` is there to be replaced. What you write in your own `config.tex` is
yours.
