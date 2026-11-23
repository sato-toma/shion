# Copilot instructions

- Follow the repository workflow in `CONTRIBUTING.md`.
- For non-trivial implementation work, create a plan under `.local/plans/` from `docs/templates/development-plan.md` before changing source code.
- Keep `.local/` files local. Never stage or commit them. After the work, update its related GitHub Issue if one exists; create an Issue only when none exists and it is appropriate.
- Read nearby code and tests before editing. Keep changes focused and follow existing patterns.
- Place tests beside the code they cover, in that module's `Tests/` folder. Use `tests/Integration/` only for tests that cross modules.
- Run the smallest relevant test set and report the exact result. Do not claim a check passed if it was not run.
- Record important trade-offs, including what was deliberately not implemented and why, in the commit body or final GitHub Issue.
