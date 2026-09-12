---
name: plan-sync
description: Reconcile plans with what actually happened on GitHub — check each open plan's PR against what the plan promised, move merged plans to done/, killed ones to discarded/, and clean up the worktrees left behind. Use when the user says to sync, reconcile, tidy, or clean up plans.
---

# plan-sync

Make the tree match reality, and check that what merged is what was planned.
Read `plan-spec` first.

## Gather

```bash
git fetch origin --prune
gh pr list --author @me --state all --limit 40 --json number,headRefName,state,mergedAt,closedAt,title
git worktree list
```

## For each plan in `open/`

Look up its `pr:`.

**Merged** → verify before you file it away:

```bash
gh pr diff <pr> --name-only
```

Compare against the plan's `## Change`. Three outcomes, and you must say which:

- The diff does what the plan said → move to `done/`.
- The diff does **more** than the plan said → move to `done/`, and note the extra in
  `## Log`. Scope crept; that is worth seeing.
- The diff does **less** → move to `done/`, and write what was dropped into a new draft
  in `drafts/` so it is not lost.

Also check the plan's `## Not in this PR` — each item there is a candidate draft. Ask
before creating them; do not silently fill `drafts/` with five new files.

**Closed without merging** → move to `discarded/`, set `status: discarded`, and record
**why** in `## Log`. A discard with no reason is how the same idea gets planned twice.
If the user has not said why, ask.

**Still open** → leave it. Update `## Log` if CI state or review comments changed since
the last sync.

**No PR, no worktree, and older than two weeks** → the dispatch never happened. Move it
back to `next/` and say so.

## Worktrees

For every worktree whose branch has merged or whose plan is now in `done/` or
`discarded/`:

```bash
git worktree remove .claude/worktrees/<slug>
git branch -d <type>/<slug>
```

If `worktree remove` refuses because the tree is dirty, **stop and show the user the
diff**. Uncommitted work in a worktree for a merged branch is usually something worth
keeping. Never `--force`.

Then:

```bash
git worktree prune
```

## Stacks

When the bottom of a stack merges, the ones above it need rebasing:

```bash
gh stack sync
```

Run it, then say which branches moved. If a rebase conflicts, stop and report — do not
resolve conflicts unattended in a stack.

## Main

```bash
git checkout main && git pull --ff-only origin main
```

## Update the index

Regenerate `.claude/plans/README.md` tables.

## Commit the plans repo

The tree lives in a repo so other machines and cloud sessions can read it. Push what
changed; skip when nothing did.

```bash
PLANS=$(git -C "$(readlink .claude/plans 2>/dev/null || pwd)" rev-parse --show-toplevel)
git -C "$PLANS" add -A
git -C "$PLANS" diff --quiet --cached || { git -C "$PLANS" commit -q -m "sync: <repo> — <what moved>"; git -C "$PLANS" push -q; }
```

## Report

What moved, what was cleaned, and anything that did not match its plan. The mismatches
are the point of this skill — lead with them.

## Do not

- Do not force-remove a dirty worktree.
- Do not delete a branch that has unpushed commits.
- Do not move a plan to `done/` without reading its diff.
- Do not create drafts from `## Not in this PR` without asking.
