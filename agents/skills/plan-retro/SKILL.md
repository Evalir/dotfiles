---
name: plan-retro
description: Read finished plans and what actually shipped, find the corrections that repeated, and propose edits to the plan-* skills and the repo's AGENTS.md. Closes the loop. Use when the user asks for a retro, wants to know what keeps going wrong, or wants the skills improved.
---

# plan-retro

Look back at finished work and change the skills so the same correction is not needed a
third time. Read `plan-spec` first.

## Gather

```bash
ls -t .claude/plans/done .claude/plans/discarded | head -20
gh pr list --author @me --state merged --limit 30 --json number,title,additions,deletions,createdAt,mergedAt
```

For a sample of merged PRs, read what review found:

```bash
gh pr view <pr> --comments
```

Bot reviewers leave the most durable record of what an agent got wrong; read their
findings first, then the human ones.

## Look for repeats, not incidents

Something that happened once is noise. Something that happened three times is a rule
that is missing. Specifically hunt for:

- **A correction the user typed more than twice.** Stale main, jumping to code before
  the plan is approved, frivolous tests, over-long output, re-running the suite between
  edits, deleting something they did not ask to delete.
- **A check that was skipped and then bit.** A breaking-change gate that would have
  caught a wire change. A live verification claimed but not run.
- **Plans that shipped bigger than written.** Compare each done plan's `## Change`
  against its diff size. Consistent overrun means `plan-write` is splitting too coarsely.
- **Plans that sat in `next/` for weeks.** Written work not dispatched means the
  appetite was wrong or the plan was too big to start.
- **Discards with the same reason.** Three plans killed for the same cause is a pattern
  worth naming.

## Propose, do not apply

Write the proposals as a short list. For each: the evidence (which plans, which PRs,
quoted), the exact edit, and which file it lands in — one of the `plan-*` skills (edit
the canonical copy in `~/.agents/skills/`, not a harness's symlink to it), or the repo's
`AGENTS.md`.

Say **remove** as readily as **add**. A skill that has grown past two pages is being
skimmed rather than read. If a rule has never fired, cut it.

Prefer editing an existing line to adding a new one. These skills work because they are
short.

Show the list. Apply only what the user picks.

## Keep the skills general

A finding that is about **one repo's code** — a rule agents keep breaking there — goes
into that repo's `AGENTS.md`, as a normal change through `plan-add`. It does not go into
a `plan-*` skill. The skills describe how work moves; the repo describes its own rules.

## Report

The three or four things worth changing, most-repeated first. Not an inventory. If
nothing repeated, say so in a line — a retro that invents findings is worse than a
quiet one.

## Do not

- Do not edit a skill without the user picking it.
- Do not report single incidents as patterns.
- Do not grow a skill past two pages to fit a new rule; replace a rule instead.
- Do not put repo-specific rules into a `plan-*` skill.
