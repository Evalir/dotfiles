---
name: plan-init
description: One-time setup of the .claude/plans/ tree in the current repo, gitignored, with its README index. Use when a repo has no plans folder yet and the user wants to start tracking plans there.
---

# plan-init

Create the plan tree in **this** repo. Run once per repo. Read `plan-spec` first.

## Check first

```bash
git rev-parse --show-toplevel
ls .claude/plans 2>/dev/null
```

If `.claude/plans/` already exists, stop and say so. Do not overwrite an index that
has entries in it.

## Create

```bash
mkdir -p .claude/plans/{drafts,next,open,done,discarded}
```

Git will not track empty directories, and the tree is gitignored anyway, so no
`.gitkeep` files. Do not add any.

## Gitignore

Plans are working state, not documentation. They do not get committed.

Append to `.gitignore`, only the lines not already present:

```
.claude/plans/
.claude/settings.local.json
```

Check each with `grep -q '^<line>$' .gitignore` first. Leave the rest of the file alone.
Do **not** ignore `.claude/` wholesale — `.claude/skills/` is often tracked and
referenced from the repo's `AGENTS.md`.

## The index

Write `.claude/plans/README.md`:

```markdown
# Plans

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

## Report

Print the tree and the next step:

```bash
find .claude/plans -type d | sort
```

Then tell the user: capture an idea with `plan-add`. Nothing else to do.

## Do not

- Do not commit anything. The `.gitignore` lines are the user's to commit when they
  choose.
- Do not create a plan tree outside a git repo.
- Do not scan the repo for work to seed the tree with. It starts empty.
