---
name: plan-dispatch
description: Send an approved plan to an agent — create the worktree off an updated main, build the change, run the repo's checks, and open the PR whose body is the plan. Use when the user says to dispatch, go, build, or start a plan in next/.
---

# plan-dispatch

Turn a plan in `next/` into a worktree and a PR. Read `plan-spec` first.

## Refuse to start if

- The plan is not in `next/`. A draft is not approved.
- The user has not approved it in this conversation or an earlier one.
- `blocked-by:` names a PR that has not merged. Say which, and stop.

## Update main

Not optional, and not once per session — once per dispatch.

```bash
git fetch origin
git -C <repo root> checkout main && git pull --ff-only origin main
```

## Worktree

```bash
git worktree add .claude/worktrees/<slug> -b <type>/<slug> origin/main
```

`<slug>` matches the plan filename minus the scope prefix; `<type>` is the conventional
commit type the change will carry. Main stays clean — you never build on it.

For a stacked plan, branch off the branch below instead of `origin/main`:

```bash
git worktree add .claude/worktrees/<slug> -b <type>/<slug> <branch-below>
```

## Before touching a branch that already exists

```bash
git log --format='%an' origin/<branch> | sort -u
```

If anyone else appears, do not force-push. Rebase and ask. You have lost a teammate's
work this way once.

## Build

Work the `## Change` bullets in order. Follow the repo's `AGENTS.md` or `CLAUDE.md`.

Run the suite **once, at the end** — not between edits. Then the full gate from the
plan's `## Checks`, exactly as written there. A suite that needs Docker, a cluster, or
cloud credentials runs only if the plan lists it.

## Verify live

Do what `## Verify live` says, with the commands it names. Record the actual output in
the plan's `## Log`, not the word "verified".

If you cannot run it — no cluster, no credentials — say so plainly and leave the box
unchecked in the PR. An honest unchecked box is worth more than a claimed one.

## Commit and PR

Commit in the repo's format (`plan-spec`). Then:

```bash
gh pr create --title "<the plan's H1>" --body-file <plan body> --draft
```

Open it as a draft when live verification is still outstanding; otherwise open it ready.
The PR body **is** the plan body — Problem, Change, Checks as a `- [x]`/`- [ ]` list,
Verify live, Not in this PR — plus the ordering line at the top when there is one
("Stacked on #N."). The harness adds its own attribution trailer; do not write one.

Use `gh stack` for anything stacked.

## Update the plan

Move `next/ → open/`, set `status: open`, and fill `worktree:`, `branch:`, `pr:`.
Append to `## Log`: the date, the PR number, what the checks said.

## Report

The PR URL, whether checks passed, and what is still unverified. One paragraph.

## Do not

- Do not build on main.
- Do not run the test suite between every edit.
- Do not widen the plan. If you find more to fix, add it to `## Not in this PR`.
- Do not merge. `plan-sync` handles what happens after review.
