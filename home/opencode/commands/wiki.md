---
description: Search or update the private cross-session agent wiki
---

Work with the private `agent-wiki` reference according to this request: $ARGUMENTS

First run `git pull --ff-only` in `/home/mollyw/.config/opencode/wiki` so reads and edits use the latest remote state. Search existing entries before answering or changing anything.

For a read request, answer from the wiki and cite the relevant file paths. Do not modify files.

For an update request, make the smallest useful Markdown edit. Record durable facts, decisions, preferences, project context, or runbooks only. Do not add secrets, credentials, raw transcripts, temporary task state, or unsupported guesses. Include dates where staleness matters and preserve conflicting historical decisions rather than silently rewriting history.

After an update, review `git diff`, commit only the wiki changes with a concise message, run `git pull --rebase`, and push to `origin main`. If the worktree contains unrelated changes or synchronization conflicts, stop without overwriting them and explain the blocker.
