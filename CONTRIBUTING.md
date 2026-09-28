# Contributing / Git workflow

This is a solo portfolio project, but it follows the same lightweight
branching model I use on real engagements — small, single-purpose branches
merged through a pull request, instead of committing straight to `main`.

## Branch naming

| Prefix     | Used for                                             |
|------------|-------------------------------------------------------|
| `feature/` | New infrastructure, module, or capability             |
| `ci/`      | Changes to GitHub Actions workflows                    |
| `docs/`    | Documentation only (README, this file, etc.)           |
| `chore/`   | Repo maintenance with no functional change (.gitignore, deps) |
| `fix/`     | Bug fix in existing code/infrastructure                |

Example: `feature/rds-module`, `ci/docker-pipeline`.

## Commit messages — Conventional Commits

```
<type>(<optional scope>): <short, imperative summary>
```

Types used in this repo: `feat`, `fix`, `ci`, `docs`, `chore`, `refactor`.

Examples:
- `feat(ecs): add Fargate cluster, task definition and service module`
- `ci(terraform): add fmt/validate/plan workflow with manual-approval apply`
- `docs: document architecture and local run instructions`

## Workflow

1. Branch off `main`: `git checkout -b feature/short-description`
2. Make one logical change per branch (one module, one pipeline, one doc).
3. Commit with a Conventional Commits message.
4. Push the branch: `git push -u origin feature/short-description`
5. Open a pull request on GitHub, review the diff, merge into `main`.
6. Delete the branch after merging (GitHub offers this automatically).

No direct commits to `main` — everything lands there through a merged PR,
even on a one-person project. It keeps the history readable and mirrors how
teams actually review infrastructure changes.
