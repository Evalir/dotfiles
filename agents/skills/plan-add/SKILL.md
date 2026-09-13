---
name: plan-add
description: Capture a raw idea as a draft plan under .claude/plans/drafts/, enriched with the context that already exists — recent commits, open PRs, related issues, linked chat threads. Use when the user says to note, capture, jot down, or remember a piece of work for later.
---

# plan-add

Capture fast, so the idea is not lost. Do not think the work through here —
that is `plan-write`. Read `plan-spec` first.

## Capture

Take the user's words. One or two sentences is enough. Do not interview them.

Pick the scope from their words against the repo's crate or component names, and the
slug from the thing that is wrong. Filename `<scope>-<slug>.md`, per `plan-spec`.

## Enrich — from what exists, not from invention

Spend a minute, no more. You are attaching context, not designing.

```bash
git log --oneline -15 -- <the paths the idea touches>
gh pr list --state open --limit 20 --json number,title,headRefName
gh issue list --search "<keywords>" --limit 10
ls .claude/plans/done .claude/plans/open
```

Record what you find. Specifically look for:

- An **issue** that already tracks this → put its number in `issue:`.
- An **open PR** that touches the same files → note it; it may become `stacked-on:`.
- A **plan in `done/`** that did the same thing → say so in the body. You may be about
  to redo work.
- A **chat thread** the user pasted → put the permalink in `slack:`.

If a chat link is in the conversation, keep it. Do not try to fetch the thread unless
a tool for that is wired up; the link is the record.

## Write

`.claude/plans` must be the mount into `Evalir/plans` (`plan-spec`, "Where you are");
if it is missing, run `plan-init` first. Then write
`.claude/plans/drafts/<scope>-<slug>.md`, frontmatter per `plan-spec` with
`status: draft`. Fill only what you know. Blank beats guessed.

The body at draft stage is short:

```markdown
# <what to do, in the user's words>

## Problem
Their sentences, tightened. Not yours.

## Context
- Related: #NNN, #NNN
- Touches: <paths>
- Prior art: .claude/plans/done/<file>

## Open questions
- The things that must be answered before this can be written.
```

Leave `## Change`, `## Checks`, `## Verify live` out entirely. An empty section invites
someone to fill it in with a guess.

## If the repo has its own way to file this kind of work

Some repos want an issue from a template before work of a certain size starts. If this
repo does, say so in one line and offer to file it. Then still write the draft; the two
are not exclusive.

## Report

One line: the path, and anything you found that the user may not know — a done plan that
already did this, or an open PR in the way.

## Do not

- Do not interview. Capture is supposed to be cheap.
- Do not design the change, name files to edit, or write commands.
- Do not open a worktree, branch, or PR.
- Do not invent an `issue:`, `pr:` or `slack:` value you did not verify.
