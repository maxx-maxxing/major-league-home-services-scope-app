# AGENT_WORKFLOW.md

## Required workflow for this repo
1) Read docs first: AGENTS.md, UI_SYSTEM.md, schema.json, PLANS.md, DOCUMENTATION.md.
2) Create a branch: `git checkout -b <name>`
3) Implement changes in small slices.
4) After each slice:
   - run `git status`
   - run `git diff`
   - stage only relevant files
   - commit with a clear message
5) Run/build sanity check notes in DOCUMENTATION.md.
6) Stop when acceptance tests pass.

## Commit message style
Use one of:
- fix: ...
- feat: ...
- chore: ...
- docs: ...
