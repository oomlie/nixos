# Global OpenCode Rules

- Inspect the codebase and existing conventions before proposing or applying changes.
- Never revert, overwrite, or include unrelated worktree changes without explicit approval.
- Prefer the smallest correct change and avoid compatibility layers without a concrete need.
- Use declarative Nix packages instead of imperative installation. For one-off tools, prefer `nix run nixpkgs#<package>`.
- For Nix changes, run the repository formatter, `nix flake check`, and a relevant evaluation or build before considering the work complete.
- Do not commit credentials, generated `result` links, runtime state, or backup configuration files.
- Review all intended changes before committing or pushing. Never force-push.
- Use the `agent-wiki` reference for durable, cross-session facts, decisions, preferences, project context, and runbooks. Search it before asking the user to repeat established information.
- Treat wiki content as curated context, not unquestionable truth. Prefer current repository state and direct user instructions when they conflict, and update stale wiki entries when asked.
- Do not write transcripts, secrets, credentials, tokens, or speculative conclusions to the wiki. Use `/wiki` to make deliberate, reviewable updates and synchronize them with the private remote.
