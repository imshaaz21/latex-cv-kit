# AGENTS.md

Instructions for coding agents working in this repository. Read this before editing any
file. It covers both maintaining the repository and the task most people will ask for,
which is tailoring the CV and cover letter for a specific job post.

A CV is a factual claim made by a named person to an employer. The cost of a mistake here
is not a failed build, it is a candidate who has to explain in an interview why their CV
says something they cannot back up. Accuracy matters more than polish, and asking matters
more than guessing.

## The one structural rule

Content lives in `config.tex`. Layout lives in `main.tex` and `cover_letter.tex`.

Every word a human reads is a `\newcommand` in `config.tex`: name, contact details,
summary, experience bullets, projects, education, skills, referees and the cover letter
body. Tailoring a CV therefore means editing exactly one file, and never touching LaTeX
internals. If you find yourself editing `main.tex` to change what the CV says, the content
belongs in `config.tex` instead.

`config.tex` is gitignored by default so that nobody publishes their personal details by
accident. `config.example.tex` is the tracked template it is copied from. In a repository
where the user has run `./track.sh private`, `config.tex` is tracked and the repository is
private. Check which situation you are in with `git ls-files --error-unmatch config.tex`
before assuming your edits are under version control.

## Before you change anything

1. Run `git rev-parse --abbrev-ref HEAD`. The branch tells you what you are allowed to do:
   - `main`: facts only. Corrections, new roles, layout fixes. No job-specific wording.
   - `profile/*`: presentation for a category of role. No company names.
   - `job-*`: tailoring for one specific post. Anything goes, within the honesty rules.
2. Never check out, amend or rebase a `sent/*` tag. Those are records of applications
   already sent, and changing one destroys the only evidence of what was claimed.
3. If the working tree is dirty, ask before committing or switching branches. Uncommitted
   wording may be something the user is still deciding about.

## Tailoring the CV for a job post

### 1. Read before writing

Read the job post in full, then read the current `config.tex` in full. Identify what the
post actually requires, separating hard requirements from the usual list of nice-to-haves.
Then work out which of those the user can genuinely evidence. That intersection is your
material. Nothing outside it may appear in the CV.

### 2. Establish what is true

You may only write a claim you can trace to a source. Acceptable sources are the existing
`config.tex`, a repository or file the user points you at, or the user telling you
directly. A job title is not evidence of a skill, and neither is a technology appearing in
the same sentence as a project the user worked on.

When you cannot source something, ask. One short, specific question is always better than
a plausible sentence. If the user is not available, leave it out and say which claims you
dropped and why.

### 3. Tailor by selection and emphasis, not invention

These are the legitimate moves:

- Reorder the skills lines so what the post asks for comes first.
- Select which existing bullets appear, and drop ones irrelevant to this post.
- Rewrite a bullet to lead with the aspect this employer cares about, keeping the facts
  identical.
- Rewrite the summary to emphasise the relevant part of a true history.
- Use the post's own vocabulary where it describes the same thing the user did. Prefer the
  employer's term over a synonym, but only when they genuinely mean the same work.

These are not:

- Adding a technology, tool, framework or responsibility the user has not confirmed.
- Changing dates, job titles, degree classifications, grades or employer names.
- Inflating scope, team size, user numbers, percentages or any other figure.
- Turning exposure into experience, or a tutorial into a project.
- Keyword stuffing a skills line with things the rest of the CV does not support.

### 4. Write bullets that survive scrutiny

- Lead with a verb. Name the technology. End with the outcome rather than the activity.
- Two lines maximum. A bullet longer than that stops being read.
- Plain numbers only. No statistical notation, no p-values, no methodology jargon in a
  document a recruiter reads before an engineer does.
- Do not explain internal mechanics the reader does not need. Say what a thing does, not
  how its lifecycle hooks are ordered.
- Describe each system at the level of someone outside the company. Expand an acronym on
  first use or drop it.
- No em dashes, anywhere, including in replies to the user. Use a comma, a colon or a
  full stop.
- Keep one spelling convention throughout, British or American, matching whatever the
  existing `config.tex` uses.

### 5. The cover letter

`\cvCoverJobTitle`, `\cvCoverCompany`, `\cvCoverCity` and `\cvCoverRef` are the header
fields. `\cvCoverBody` is the letter.

Three paragraphs. Who the user is, in one sentence. Then two or three specific things from
their CV that match this post, explained in their own words rather than restated as
bullets. Then a plain closing. Do not flatter the company, do not claim passion for its
mission, and do not use a phrase the user would be embarrassed to be asked about.

### 6. Build and verify

```bash
./run.sh
```

Always build before reporting the work as finished. The script warns on two failures that
are otherwise silent:

- `WARNING: the CV is N pages, trim it to 1`
- `WARNING: ... has overfull boxes, check the margins`, meaning text runs past the margin

Both must be resolved, not reported and left. Trim wording first. Only touch spacing
(`vmargin`, `titlespacing` or the `\setlist` gaps in `main.tex`) when the wording is
already as tight as it can get.

Then read what a parser reads:

```bash
pdftotext main.pdf - | less
```

Check the section order is intact, no word is hyphenated across a line, and the contact
line survived as text.

### 7. Commit and report

Commit on the job branch with a message naming the company and role. Then, before the
branch is retired, cherry-pick anything that was not job specific onto `main`: a corrected
fact, a layout fix, a better phrasing of a permanent bullet. A fix left only on a job
branch dies with it.

Report to the user: what you changed, which claims you could not source, and anything you
deliberately left out. Do not describe a tailored CV as finished without that list.

## Privacy

- `config.tex` (unless the user has deliberately tracked it), `applications/` and any
  `email*.md` or `notes*.md` are gitignored. Never add them to a public remote, and never
  copy their contents into a tracked file.
- Never put a referee's phone number in the source, including inside a `%` comment. LaTeX
  comments are invisible in the PDF and perfectly readable in the repository, and they
  remain in git history long after they are deleted.
- A referee's name, employer and email are someone else's personal data. Do not add,
  change or move a referee without the user saying so explicitly.
- A repository that tracks `config.tex` must stay private permanently. Making it public
  publishes every past version, and on GitHub rewritten history remains reachable through
  the fork network. Never suggest making such a repository public.

## Branching

Three tiers. Changes flow upward only, never down into something already sent.

| Branch | Lifetime | Holds |
| :--- | :--- | :--- |
| `main` | permanent | the user's facts, honest and complete, one page |
| `profile/<archetype>` | long lived, two to four | presentation for one category of role |
| `job-<company>-<role>` | days | one application, then tagged and deleted |

```bash
./track.sh start <name> [base]   # branch job-<name> from base, default main
./track.sh sent                  # tag the current job branch, then delete it
./track.sh log                   # applications sent, newest first
./track.sh sync                  # rebase every profile/* onto main
./track.sh diff <name>           # what was claimed there against the CV today
./track.sh open <name>           # restore a sent application to a branch for reuse
```

Start an application with `./track.sh start`, not with `git checkout -b`. It refuses a
name already used, checks that `config.tex` is tracked, and branches from the profile you
name rather than from whatever happens to be checked out.

Do not create a profile per company. If a job branch needs more than the cover letter
fields and a few words changed, the profile it came from is wrong, not the job branch.

## Changing the repository itself

Separate from editing someone's CV, if you are changing the scripts, the layout or the
template:

- `config.example.tex` is sample content and must stay fictional. It uses reserved
  example domains and a reserved fictional phone number. Never put a real person's
  details in it, and keep it building to one page, since the preview images in `docs/`
  are rendered from it.
- Run `./tests/workflow.sh` after any change to `run.sh` or `track.sh`. It clones the
  committed state, so commit first. CI runs it on Linux, macOS and Windows.
- Keep the scripts portable. No `sed -i` without an argument, no GNU-only `\U`, nothing
  that assumes GNU coreutils. Contributors run macOS and Git Bash.
- Under `bash -e`, a failing `a && b` list exits the script even when the failure is the
  expected outcome. Write those as `if`, which is why `run.sh` does.
- Do not add a task runner, Makefile or justfile. The two scripts are the interface, and
  a third file wrapping them is indirection rather than convenience.

## Build constraints

- `main` stays one page.
- Body text is ragged right on purpose: with hyphenation disabled for ATS, justified text
  stretches the word spacing badly. Do not reinstate justification, and do not reinstate
  hyphenation to make justification work.
- A job branch may run to two pages if the user asks for it, but a role or section must
  never split across the page break. Wrap it in a `minipage` if it is at risk.
- The engine must stay pdfTeX. `\input{glyphtounicode}` and `\pdfgentounicode=1` are
  pdfTeX primitives, so xelatex, lualatex and Tectonic will fail on this preamble. Do not
  "modernise" the toolchain.
- TeX comes from mise (`mise install`). A missing package installs with
  `mise exec -- tlmgr install <pkg>`, no sudo required.
- Keep the scripts portable: POSIX-compatible `sed` usage, no `sed -i` without an
  argument, no GNU-only `\U`. Contributors run macOS.

## ATS constraints

The preamble and layout exist to survive automated parsing. Do not change these without
being asked:

- Standard section headings: SUMMARY, EXPERIENCE, PROJECTS, EDUCATION, SKILLS, REFERENCES.
- Single column. No tables for skills. The side-by-side `minipage` for referees is fine,
  it is read in order and is not a multi-column layout.
- `\input{glyphtounicode}` and `\pdfgentounicode=1` stay, so extracted text is clean.
- `\hyphenpenalty=10000` and its companions stay, so no parser sees `microser-vices`.
- No text inside graphics, no icon fonts for the contact line, no columns for experience.

## When to ask rather than decide

Ask the user when:

- A claim cannot be sourced from the repository or something they have shown you.
- The post asks for a technology that is absent from the CV, and you cannot tell whether
  that is an omission or a gap.
- Trimming to one page means cutting something substantive rather than tightening wording.
- A referee's details would need to change.
- The work would require editing `main.tex` for a reason you cannot explain in one line.

Everything else is an ordinary editing decision. Make it, build it, and say what you did.
