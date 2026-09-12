---
name: plan-spec
description: The folder layout, plan file format, and house rules every other plan-* skill reads first. Load before plan-init, plan-add, plan-write, plan-dispatch, plan-status, plan-sync, or plan-retro. Not a command on its own.
---

# plan-spec

The shared contract. Every `plan-*` skill loads this before doing anything.

## Layout

Plans live in one private repo, `Evalir/plans`, cloned at `~/dev/evalir/plans`. One
directory per code repo, named after it:

```
~/dev/evalir/plans/
  README.md            # what this repo is; hand-written
  spellbook/
    README.md          # this repo's index; plan-status regenerates it
    drafts/            # captured, not yet thought through
    next/              # written and approved by you; ready to dispatch
    open/              # a worktree exists; PR open or being built
    done/              # PR merged
    discarded/         # killed, with the reason kept
  baseline/ …
```

Each code repo reaches its own tree through a symlink, ignored per clone, so every
command in these skills works from inside the code repo unchanged:

```
<code repo>/.claude/plans  ->  ~/dev/evalir/plans/<repo>
```

Worktrees stay in the code repo at `.claude/worktrees/<slug>/`. A plan in `open/` owns
exactly one worktree with the same slug.

The plans repo is committed and pushed — that is what lets another machine or a cloud
session read it. `plan-status` and `plan-sync` end by committing and pushing it.

## Where you are

- **Inside a code repo**: paths are `.claude/plans/…`; `gh` infers the repo.
- **Inside the plans repo** — a cloud session, or a machine without the code checked out:
  paths are `<repo>/…`, and every `gh` call takes `-R <owner/repo>` from the plan's
  `repo:` field. `plan-status` and `plan-sync` work here in full. `plan-write` and
  `plan-dispatch` need the code; run them from the code repo.

## Filename

`<scope>-<slug>.md`, where `<scope>` is the conventional-commit scope you would put on
the commit — a crate, component, or surface name. No scope for a repo-wide change.
Example: `auth-token-refresh.md`.

## Plan file

Frontmatter is machine-read by `plan-status` and `plan-sync`. Leave a field blank
rather than guessing.

```markdown
---
repo: owner/name         # the code repo this plan changes
scope: auth
status: draft | next | open | done | discarded
appetite: hours | days | a week | longer
worktree:                # .claude/worktrees/<slug>; blank for a cloud dispatch
branch:                  # fix/<slug>, feat/<slug>, refactor/<slug>, ci/<slug>, chore/<slug>
pr:                      # 123
issue:                   # the tracking issue, when there is one
stacked-on:              # PR number below this one in the stack
blocked-by:              # owner/repo#N that must merge first, or a person
slack:                   # thread permalink
---

# <the commit subject this plan will produce>

## Problem
What is wrong, observed. Name where you saw it — a client, a log line, a host.

## Change
What you will do. Bullets, one per moving part, each naming the file or type it lands in.

## Checks
The exact commands, copied from the repo's own gate — see below.

## Verify live
How you will see it work outside the test suite. A green suite is not done.

## Not in this PR
The follow-ups you are deliberately leaving. Keeps scope from creeping.

## Log
Appended as work happens. Dates, PR numbers, what a review found.
```

The body sections are the PR body. `plan-dispatch` hands them over almost verbatim —
and for a cloud agent, the body *is* the task, so it must stand on its own.

## Checks come from the repo

Never write a check from memory. In order: the repo's `AGENTS.md` or `CLAUDE.md`; its
`Makefile` or `justfile` (`check`, `verify`, `lint`); the CI workflow files, copying what
the jobs run; and only then the toolchain default — for Rust, `cargo +nightly fmt --all
--check`, `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings`,
`cargo test --workspace`. A suite that needs Docker, a cluster, or cloud credentials runs
only when the plan names it in `## Checks`.

## House rules

- **Always start from an updated main.** `git fetch origin` and rebase before any
  worktree, and again before every dispatch. This is the correction you have made most
  often; do not make it again.
- **Never force-push a branch you did not create.** Teammates push to shared branches.
  Check `git log --format='%an' origin/<branch> | sort -u` first.
- **Plan before code.** A plan is read and approved before a worktree exists. No skill
  writes code during `plan-write`.
- **Stack, don't pile.** `gh stack` is installed; use it wherever the host has stacked
  PRs enabled. Split anything over ~400 lines into a stack.
- **Tests earn their place.** No test that exercises a dependency, the language, or
  coverage another test already has.
- **Run the suite once, at the end.** Not between every edit.
- **Fan out only when the work is genuinely parallel**, and cap it: at most 3 subagents,
  1 per PR. Serial work with parallel agents wastes tokens.
- **Shell snippets are fish-compatible.** Use `env VAR=x cmd`, not `VAR=x cmd`.
- **Succinct.** Short sentences. No paragraph where a bullet works.
- **Delete nothing you were not asked to delete.**

## Commit and PR format

- **Match the repo's own log**: `git log --oneline -20` before the first commit. Work
  repos (the init4tech org) and some personal ones use conventional commits with a
  lowercase subject — `fix(auth): refresh the token before it expires, not after`;
  squash-merge appends ` (#NNN)`. Other personal repos use a plain imperative sentence,
  capitalized, no prefix — `Refresh the token before it expires`. The log decides.
- Branch: `<type>/<slug>`. PR bodies open with the ordering constraint when one exists
  ("Stacked on #N.", "Follow-up to #N.", "Merge only after …").
- Let the harness append its own attribution trailer, if it has one. Never hand-write
  a trailer naming a tool that did not do the work.
