# Development workflow

This document defines the standard workflow for changes in this repository.

## 1. Choose a branch name

Use a short, lowercase name with a clear prefix:

- `feature/<short-description>` for a user-facing capability.
- `fix/<short-description>` for a bug fix.
- `survey/<short-description>` for research or a time-limited technical investigation.
- `docs/<short-description>` for documentation-only work.
- `release/<version>` for release preparation.

Examples:

- `feature/citygml-streaming-reader`
- `survey/citygml-parser-options`
- `fix/windows-path-handling`
- `release/0.1.0`

Use kebab-case and describe the subject, not the person or date.

## 2. Write a local plan before implementation

For non-trivial code, behavior, dependency, or build-system changes:

1. Copy `docs/templates/development-plan.md` to `.local/plans/<branch-name>.md`.
2. Record the goal, proposed approach, affected components, test plan, risks, and alternatives before editing source.
3. Keep the plan in `.local/`; this directory is ignored by Git and must not be committed.

Small typo fixes and similarly trivial documentation edits do not need a separate plan.

## 3. Implement and test

- Inspect the relevant implementation and tests before making changes.
- Keep the change focused. Do not add unrelated cleanup or speculative abstractions.
- Place a test in the nearest module's `Tests/` directory. Put only cross-module integration tests in `tests/Integration/`.
- Add or update tests for behavior changed by the implementation. Include an OS-specific test when the code depends on an OS-specific format, compression, encoding, path, or file-system behavior.
- Run the smallest relevant test set first. Run the required CI-equivalent checks for the affected Unity version and host OS before marking the work complete.
- Report checks that could not be run and the reason. Do not present an unrun check as passing.

## 4. Commit changes

Write commit subjects in simple English that clearly state what changed. Prefer an action verb and avoid vague subjects such as `update`, `misc`, or `fix stuff`.

Examples:

- `Add CityGML feature filtering`
- `Read compressed files on Windows`
- `Run Unity edit-mode tests on Linux`

Use the commit body for context that does not fit in the subject:

```text
Why:
What changed:
Trade-off:
Not done and why:
Tests:
```

Keep the body concise. Include `Trade-off` and `Not done and why` when a meaningful alternative or limitation was considered; do not invent one for a trivial change.

## 5. Record the result in a GitHub Issue

When the development work is complete, record the relevant plan and findings in the related GitHub Issue. If an Issue already exists, update it rather than creating another. If none exists, create one only when it is appropriate; creating an Issue at this stage is not mandatory. Include:

- The goal and final behavior.
- The main implementation areas.
- Important decisions and trade-offs.
- What was not implemented and why.
- Tests and builds actually run, with their results.
- Remaining risks or follow-up work.

Do not include machine-specific local paths, private data, or secrets. The local plan may be retained for personal reference, but it is not a substitute for the GitHub Issue record.
