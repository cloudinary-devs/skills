# Contributing

Rules for adding or changing skills in this repo. The `skills` CLI is unforgiving
about layout and frontmatter: a skill that breaks these rules is dropped from
discovery with no warning, so read this before opening a PR.

## Layout

Every skill lives at `skills/<category>/<name>/SKILL.md`, exactly two directories
deep. The CLI does not look any deeper, so a skill nested at depth three is
invisible to users.

Categories:

- `platform` — reference skills for a Cloudinary capability (uploads,
  transformations, docs lookup)
- `frameworks` — patterns for using Cloudinary in a specific framework or SDK
- `use-cases` — end-to-end recipes that combine several capabilities
- `utilities` — tools that do a job using Cloudinary

Category directories are created with their first skill. Do not add a README or
placeholder to an empty category.

Users install skills by name, not by path, so the category is invisible to them.
Moving a skill between categories does not affect existing installs.

## Frontmatter

```yaml
---
name: cloudinary-example
description: "Reference for <capability>. Use when <trigger phrases>."
license: MIT
metadata:
  author: cloudinary
  version: '1.0.0'
---
```

- `name` must equal the directory name.
- `name` and `description` must both be strings. If either is missing, or the
  frontmatter fails to parse, the skill silently vanishes from discovery.
- A description containing a colon must be quoted. Unquoted, YAML reads the colon
  as a nested key, the description is no longer a string, and the skill vanishes.
- Include `license`, `metadata.author`, and `metadata.version` (semver).
- Set `metadata.internal: true` on a work-in-progress skill that should not appear
  in the default install. Users can reveal it with `INSTALL_INTERNAL_SKILLS=1`.

## Description shapes

Agents see the catalog as a flat list of names and descriptions, so every
description does two jobs. It opens with a clause that self-locates the skill in
that list, then follows with a "Use when..." sentence that carries the trigger
phrases.

| Category | Opening shape |
|---|---|
| Platform | `Reference for <capability>.` |
| Frameworks | `Patterns for using Cloudinary in <framework>.` |
| Use-case | `End-to-end recipe for <outcome>.` |
| Utility | `Tool that <does X> using Cloudinary.` |

Rules:

- The opening clause never contains a colon before its first period unless the
  whole description is quoted.
- Trigger phrases live in the "Use when" sentence, not in the opening clause.

Existing skills predate these shapes and are not yet retrofitted. New skills must
follow them.

## Referencing other skills

Refer to another skill by its name only, for example "use cloudinary-docs for
anything outside this skill's scope". Never reference another skill by file path.
Installed paths differ per agent and per install scope, so a path that works on
your machine will be wrong on someone else's.

## Versioning

Bump `metadata.version` on any content change to a skill, including its
references and assets. Moving or renaming files with identical content does not
bump the version; the lock-file hash is unchanged and `skills update` correctly
reports nothing to do. CI enforces this on every PR: a skill with changed
content and an unchanged version fails the `versions` job.

## Documentation links

Every link to a Cloudinary docs `.md` page or `llms.txt` must carry
`?install_source=skillspack&referrer=<skill>-skill` so traffic from skills is
attributable. Use the same `referrer` value throughout a skill, for example
`trans-skill` or `react-skill`. CI fails the `links` job on any link missing
either param.

## Local check

Before opening a PR, run the same checks CI runs:

```bash
INSTALL_INTERNAL_SKILLS=1 npx -y skills@latest add . --list
scripts/check-links.sh
scripts/check-versions.sh origin/main HEAD
```

The `Found N skills` line must match the number of `SKILL.md` files under
`skills/`, and every skill name must appear in the list. A mismatch means a skill
is being dropped: check for bad frontmatter, an unquoted colon in the
description, a missing `name` or `description`, or a directory nested at the wrong
depth. The two scripts report any untracked doc link and any changed skill whose
version was not bumped. CI (`.github/workflows/skills-discovery.yml`) runs all
three and fails the PR on the same conditions.
