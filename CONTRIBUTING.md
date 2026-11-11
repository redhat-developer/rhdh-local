# Contributing to RHDH Local

We welcome contributions from all engineers! For the full guide — bug reporting,
contribution types, documentation standards, and the review process — see the
built-in TechDocs page:
[Help & Contributing](./docs/rhdh-local-guide/help-and-contrib.md).

## Branching model

| Branch | Purpose | Tracks |
|---|---|---|
| **`main`** (default) | Latest stable GA release of RHDH | Current GA RHDH version |
| **`dev`** | Active development for the upcoming RHDH release | RHDH `next` tag |
| **`release-x.y`** | Release stabilization and patch releases | Specific RHDH version |

### Where should my PR go?

| Change type | Target branch |
|---|---|
| All development work (features, docs, dependency updates, etc.) | `dev` |
| Bug fixes for a specific supported release | `release-x.y` |

Do **not** target `main` directly. Maintainers manage `main` via merges and
cherry-picks.

### Release merge (maintainers)

At GA for the latest minor or major release, maintainers merge the release tag
into `main` so it always reflects the latest stable RHDH release. Z-stream
releases on older supported branches are not merged into `main`.

```sh
git checkout main
git pull
git merge <x.y.z> --no-ff   # e.g. git merge 2.1.0 --no-ff
# resolve any conflicts, then commit and push
```

After the merge, pin the RHDH container image tag from `next-x.y` to `x.y.z`
wherever applicable (e.g., `compose.yaml`, documentation, environment files).
