---
name: plan-status
description: Report where every plan stands — what is waiting to merge, what is blocked on another repo or person, which review comments are unanswered, and which drafts are ready to write. Regenerates the plans README index. Use when the user asks where things stand, what is blocked, or what to pick up.
---

# plan-status

A verdict on each plan, not a survey. Read `plan-spec` first.

## Gather

```bash
git fetch origin
ls .claude/plans/{drafts,next,open,done,discarded}
gh pr list --author @me --state open --json number,title,headRefName,isDraft,mergeable,statusCheckRollup,reviewDecision
gh pr list --author @me --state merged --limit 20 --json number,headRefName,mergedAt
```

For each plan in `open/`, check its PR:

```bash
gh pr view <pr> --json mergeable,statusCheckRollup,reviews,comments,isDraft
gh pr view <pr> --comments
```

Read the comments for **unanswered review findings** — from bot reviewers as much as
people. They gate a merge as surely as CI does.

## Report

Five sections. Skip any that is empty. Lead with what needs you.

**Needs you now**
- CI red — the PR, the failing job, the likely cause in one line.
- An unanswered review comment, bot or human.
- A merge conflict. Name it; a stack goes stale fast.
- A draft PR whose live verification is the only thing outstanding.

**Waiting on someone else**
- `blocked-by:` pointing at a PR in another repo, and whether it has merged.
  Cross-repo ordering is the usual blocker: one repo needing a resource another
  creates.
- A PR waiting on a reviewer with approval rights. Name them.
- Say how long each has waited.

**Ready to merge**
- Mergeable, checks green, comments answered. Just needs you to press the button.

**Ready to dispatch**
- Plans in `next/`, with their appetite. If more than three are sitting there, say so —
  a queue of written plans means dispatch is the bottleneck, not planning.

**Drafts worth writing**
- Plans in `drafts/`, oldest first. Flag any older than two weeks: either write it or
  discard it.

## Stale worktrees

```bash
git worktree list
```

Any worktree whose branch is merged, or that has no plan in `open/`, is dead. List them
for `plan-sync` to clean up. Do not remove them here.

## Regenerate the index

Rewrite the tables in `.claude/plans/README.md` from what you found. Tables only —
do not add prose to the index.

## Commit the plans repo

The tree lives in `Evalir/plans` so other machines and cloud sessions can read it. Push
what changed; skip when nothing did. The remote check is not optional: without the mount,
`$PLANS` would resolve to the code repo, and `add -A` there would commit your working tree.

```bash
PLANS=$(git -C "$(readlink .claude/plans 2>/dev/null || echo .)" rev-parse --show-toplevel)
git -C "$PLANS" remote get-url origin | grep -q 'Evalir/plans' || { echo "not Evalir/plans: $PLANS"; exit 1; }
git -C "$PLANS" add -A
git -C "$PLANS" diff --quiet --cached || { git -C "$PLANS" commit -q -m "status: <repo> <date>"; git -C "$PLANS" push -q; }
```

## Report style

Short sentences. A table when there are more than three rows in a section. No
restatement of what each plan is about; the user wrote them. If nothing needs the user,
say that in one line and stop.

## Do not

- Do not fix anything. This skill reads and reports.
- Do not move plans between folders. That is `plan-sync`.
- Do not pad an empty section with "nothing here".
- Do not guess at a CI failure you have not read the log for — say the job name and
  offer to look.
