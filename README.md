# latex-cv-kit

A LaTeX CV and cover letter kept under version control, with one git branch per job
application.

Applying for jobs tends to produce a folder of files called `CV_final_v2_acme.pdf` and no
reliable record of which one went where. This repository treats a CV the way you would
treat code. The content is a single plain-text file, the wording is separate from the
layout, each tailored version is a branch, and each application you actually send becomes
a tag you can diff against your CV as it stands today.

It is a template to copy rather than a dependency to install. What it adds to git and
`latexmk` is a little over 200 lines of shell and a set of conventions that stop the
branches getting out of hand.

```
main                          your facts: honest, complete, one page
├── profile/backend           long lived: how you present for backend roles
│   └── job-acme-backend      short lived: tailored, sent, then tagged sent/acme-backend
└── profile/platform          long lived: how you present for platform and SRE roles
    └── job-globex-sre        short lived
```

## Requirements

- git and bash.
- A TeX distribution providing `pdflatex` and `latexmk`. TeX Live and MacTeX both work.
  [mise](https://mise.jdx.dev) is optional and recommended: `mise.toml` pins TinyTeX, and
  `run.sh` shells out through `mise exec` so the PDF renders identically on any machine.
- Optional: `pdfinfo` from poppler, for the page-count check. `rclone`, if you want
  `--upload`. The build works without either.

The engine must be pdfTeX. The two ATS lines in the preamble are pdfTeX primitives, so
xelatex, lualatex and Tectonic will fail on this preamble.

## Getting started

```bash
git clone https://github.com/imshaaz21/latex-cv-kit.git my-cv
cd my-cv
cp config.example.tex config.tex
mise install
./run.sh
```

`config.tex` is the only file you edit. It holds your name, contact details, summary,
experience bullets, projects, education, skills, referees and the cover letter body.
`main.tex` and `cover_letter.tex` are layout, and you can ignore them until you want to
change how the page looks.

The build writes `Your_Name_CV.pdf` and `Your_Name_Cover_Letter.pdf`, named from
`\cvName`, and opens both. It warns about two things that are otherwise easy to miss: a CV
that has spilled onto a second page, and an overfull box, which means text running past
the margin without any visible error.

## Branch strategy

The reason most attempts at this collapse is that every application becomes a branch,
nothing is ever deleted, and after thirty applications there is no way to tell which
branches are current. The convention here is three tiers, with changes flowing upward
only.

**`main` is your facts.** Everything true about you, honest and complete, kept to one
page. It is the only branch you actively maintain. A new role, a corrected date, a layout
fix: it goes here, and every future application inherits it.

**`profile/*` branches are how you present, not what you did.** Most people apply for two
or three kinds of role rather than thirty different ones. A profile holds only the
differences for one category: a summary that leads with the relevant stack, the skills
lines reordered, a different selection of bullets. Keep two to four of them, never one per
company.

```bash
git checkout main
git checkout -b profile/backend   # edit config.tex, commit
```

**`job-*` branches are disposable.** Branch from the closest profile, tailor for the
specific post, build, send, and then retire the branch.

```bash
git checkout profile/backend
git checkout -b job-acme-backend
# edit config.tex: the cover letter fields, and whatever wording the post calls for
./run.sh                          # Your_Name_CV_Acme_Backend.pdf
git commit -am "Acme backend application"
./track.sh sent                   # tags sent/acme-backend, deletes the branch
```

### Why a sent application is a tag

Once an application is out the door it is a record, and a record that can still be edited
is not evidence of anything. `./track.sh sent` freezes the commit as an annotated tag
carrying the date, then deletes the branch. Your branch list stays at three or four while
the history stays complete, and you keep a permanent answer to the question of what a
particular employer actually read.

Two rules follow from that. Never merge `main` into a sent application, because
backporting a later fix into something already submitted falsifies it. And cherry-pick
anything that was not job specific onto `main` before you retire the branch, or it dies
with the branch.

### Keeping it aligned

```bash
./track.sh sync                  # rebase every profile/* onto main
./track.sh log                   # applications sent, newest first
./track.sh diff acme-backend     # what you claimed there against your CV today
./track.sh open acme-backend     # restore that tailoring to reuse it elsewhere
```

Run `sync` after any change to `main`. Only the handful of profile branches are kept
current, which is what makes the strategy survive contact with a real job search. Sent
tags are deliberately never touched. Conflicts are reported per profile and the rebase is
aborted rather than left half-applied, and a dirty working tree is refused.

`diff` is the one worth remembering. Run it the morning of an interview and you can see
exactly what the people across the table are holding. Comparing two applications is plain
git:

```bash
git diff sent/acme-backend sent/globex-sre -- config.tex
```

### Tracking your own content

The template ships with `config.tex` gitignored, so cloning it and filling it in cannot
publish your details by accident. The branch workflow needs that file tracked, and
tracking it puts your name, contact details and employment history into the repository's
history permanently. That is only safe in a **private** repository:

```bash
./track.sh private               # un-ignores and stages config.tex, after confirming
git commit -m "Track my CV content"
```

Keep that repository private. Making it public afterwards publishes every past version,
and on GitHub a rewritten history remains reachable through the fork network. If you later
want to share your layout, publish a separate repository rather than changing the
visibility of this one.

## Working with an AI coding agent

Tailoring a CV is a task coding agents are genuinely good at and also a task where they
fail badly by default: asked to match a job post, a model will cheerfully add a framework
you have never used. [`AGENTS.md`](AGENTS.md) is written to prevent that. It sets out the
structural rule that content only ever goes in `config.tex`, the evidence rule that no
claim may be written unless it can be traced to the repository or to something you have
confirmed, the list of edits that count as legitimate tailoring as against invention, the
build checks that must pass before work is reported as done, and the cases where the agent
should stop and ask you instead of deciding.

`AGENTS.md` is the convention most coding agents now read. If yours expects a different
filename, link it rather than keeping two copies:

```bash
ln -s AGENTS.md CLAUDE.md
```

A prompt that works well, with the job post saved alongside the repo:

```
Tailor my CV for the role in jd.txt. Read AGENTS.md first.
Work on a new job-acme-backend branch, edit config.tex only, and list every
claim you could not source from this repo so I can confirm or drop it.
```

The last clause is the important one. The useful output of an agent here is not the
rewritten bullets, it is the list of things it wanted to claim on your behalf and could
not justify.

## ATS

Applicant tracking systems parse PDFs, and most of what breaks them is layout rather than
wording. This template avoids the known failure modes: it is single column, uses the
standard section headings, keeps skills as text rather than in a table, maps glyphs to
Unicode with `glyphtounicode` and `\pdfgentounicode=1` so extracted text is clean, and
disables hyphenation so no parser reads `microser-vices` as two words.

No template can promise to pass a specific system, and anyone claiming otherwise is
guessing. Read your own output the way a parser does:

```bash
pdftotext main.pdf -
```

If the section headings are in order and no word is split, the layout is doing its job.

## Repository layout

| Path | Purpose |
| :--- | :--- |
| `config.example.tex` | Template content. Copy to `config.tex` and edit. |
| `config.tex` | Your content. Gitignored by default. The only file you edit per job. |
| `main.tex` | CV layout. Change how it looks, never what it says. |
| `cover_letter.tex` | Cover letter layout. Shares `config.tex` with the CV. |
| `run.sh` | Builds both documents, names the PDFs, checks pages and margins. |
| `track.sh` | Tags sent applications, rebases profiles, diffs what you sent. |
| `AGENTS.md` | Instructions for coding agents working in the repository. |
| `mise.toml` | Pins the TeX toolchain and rclone. |

On a job branch the build also copies its outputs to `applications/<Company_Role>/`, which
is gitignored, so switching branches never overwrites an earlier application's files.
`./run.sh --upload` additionally mirrors them to your own rclone remote, defaulting to one
named `gdrive` and overridable with `CV_RCLONE_REMOTE`. Plain `./run.sh` is entirely
offline.

## What this is not

- Not a resume builder. There is no interface, no hosted service and no account. If you
  would rather fill in a form than edit a text file, this is the wrong tool.
- Not a guarantee of anything about applicant tracking systems. See above.
- Not a layout you can restyle without reading some LaTeX. The content split means you can
  avoid that for ordinary use, but changing the design means editing `main.tex`.
- Not safe to use as a public repository once you track your own `config.tex`.
- Opinionated about length. `main` is checked for one page because a one-page CV is the
  right default for most engineers. Remove that check in `run.sh` if you disagree.

## Contributing

Issues and pull requests are welcome, particularly for portability problems on macOS and
other TeX distributions. Two things to keep in mind: no change may make it easier to
publish personal data by accident, and the scripts stay POSIX-compatible in their use of
`sed` so they work with BSD userland.

## Licence

[MIT](LICENSE). The placeholder text in `config.example.tex` exists to be replaced. What
you write in your own `config.tex` is yours.
