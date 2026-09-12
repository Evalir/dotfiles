---
name: plan-init
description: Connect the current code repo to the plans repo — clone Evalir/plans if needed, create this repo's tree in it, and mount it at .claude/plans. Use when a repo has no plans link yet and the user wants to start tracking plans for it.
---

# plan-init

Connect **this** code repo to the plans repo. Run once per repo, per machine. Read
`plan-spec` first.

## Check first

```bash
git rev-parse --show-toplevel
ls -la .claude/plans 2>/dev/null
```

If `.claude/plans` already exists — as a link or a directory — stop and say so. Never
replace it.

## The plans repo

```bash
PLANS=~/dev/evalir/plans
[ -d "$PLANS/.git" ] || gh repo clone Evalir/plans "$PLANS"
git -C "$PLANS" pull -q --ff-only
```

## This repo's tree

```bash
REPO=$(basename "$(git rev-parse --show-toplevel)")
mkdir -p "$PLANS/$REPO"/{drafts,next,open,done,discarded}
```

If `$PLANS/$REPO` already has plans in it — another machine set it up — keep them and
skip to the link. Otherwise write `$PLANS/$REPO/README.md`:

```markdown
# <repo>

`plan-status` regenerates the tables below. Do not hand-edit them.

## open
| plan | branch | PR | blocked by |
|---|---|---|---|

## next
| plan | appetite | issue |
|---|---|---|

## drafts
| plan | captured |
|---|---|

## done
| plan | PR | merged |
|---|---|---|

## discarded
| plan | why |
|---|---|
```

Git does not track empty directories; that is fine. `plan-add` writes the first file.

## The link

```bash
mkdir -p .claude
ln -s "$PLANS/$REPO" .claude/plans
```

## Ignore it, per clone

The link is this machine's, not the project's, so it goes in `.git/info/exclude` — the
same place the harness puts its own worktree excludes — never in the tracked
`.gitignore`. A `.gitignore` line ending in `/` matches only a directory, not a symlink,
so an existing `.claude/plans/` entry does not cover the link.

```bash
git check-ignore -q .claude/plans     || echo '.claude/plans'      >> .git/info/exclude
git check-ignore -q .claude/worktrees || echo '.claude/worktrees/' >> .git/info/exclude
git status --short .claude            # must print nothing
```

## Commit the plans repo

```bash
git -C "$PLANS" add "$REPO"
git -C "$PLANS" commit -q -m "Add $REPO"
git -C "$PLANS" push -q
```

Skip the commit if nothing changed — the tree already existed.

## Report

The link, the tree, and the next step: capture an idea with `plan-add`. Nothing else.

## Do not

- Do not touch tracked files in the code repo. This skill commits nothing there.
- Do not create a tree for a directory that is not a git repo.
- Do not scan the repo for work to seed the tree with. It starts empty.
