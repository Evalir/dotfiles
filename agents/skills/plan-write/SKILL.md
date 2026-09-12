---
name: plan-write
description: Turn a draft plan into one the user can approve — investigate the cause, name the change, write the exact check commands and the live verification, and split it into a PR stack. Use when the user says to write up, flesh out, plan, or work out a draft. Writes no code.
---

# plan-write

Investigate, then write. **No code, no branch, no PR.** You show the plan; the user
approves it before anything is built. Read `plan-spec` first.

## Before you start

```bash
git fetch origin && git log --oneline HEAD..origin/main | head -20
```

If main has moved, read what moved. Planning against a stale main is the correction
you have had to make most often.

## Investigate

Find the **cause**, not the symptom. Read the code. Reproduce it if there is a way to —
the repo's local stack, a live query against the running thing, a request by hand. A
plan that says "probably X" is not ready.

Fan out to subagents only if the questions are genuinely independent — different crates,
different repos. Cap at 3. If the investigation is one thread of reasoning, do it
yourself; parallel agents on serial work waste tokens.

Read the repo's `AGENTS.md` or `CLAUDE.md` before proposing anything. Its rules are the
ones a plan most often breaks.

## Write the plan

Move the file `drafts/ → next/`, set `status: next`, and fill the body per `plan-spec`.

```bash
mv .claude/plans/drafts/<file> .claude/plans/next/<file>
```

Hold each section to its bar:

- **Problem** — what you observed, and where. Name the client, the log line, the host.
  "The client fails the handshake with error -32022 right after login" beats
  "negotiation is broken".
- **Change** — one bullet per moving part, each naming the file or type it lands in.
- **Checks** — the repo's real gate, found the way `plan-spec` says. Not "run the tests".
- **Verify live** — the thing you will do outside the suite, with the command and the
  output you expect to see. If a change genuinely cannot be seen live, say that.
- **Not in this PR** — the follow-ups you are refusing. Be specific; this is what keeps
  the diff small.

## Split into a stack

If the change exceeds roughly 400 lines, or mixes a refactor with a behaviour change,
split it. Write one plan file per layer, `stacked-on:` pointing down the stack, and
number the slugs so the order is obvious (`<scope>-<slug>-1`, `<scope>-<slug>-2`).

A refactor that makes room for the feature always goes **below** the feature.

## Tests

Name the tests the change needs, and name what you are deliberately not testing.
No test that exercises a dependency, the language, or ground another test covers.

## Cross-repo ordering

If this needs a change in another repo — a resource another repo creates, an image
another repo's CD publishes — put it in `blocked-by:` as `owner/repo#N` and state the
ordering in one line at the top of the body. This is your most common real blocker.

## Show it

Print the plan. Ask for approval in one line. Do not start building, do not create a
worktree, and do not offer to. Dispatch is a separate, deliberate step.

If the user asks for changes, edit and show again.

## Do not

- Do not write, edit, or scaffold code. Not even "barebones".
- Do not create a branch, worktree, or PR.
- Do not pad the plan. Short sentences, no restated background.
- Do not leave a section as a placeholder — cut it instead.
