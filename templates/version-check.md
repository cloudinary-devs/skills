<!-- version-check:start (generated from templates/version-check.md, edit there and run scripts/check-version-block.sh --fix) -->
## Before you start: check this skill is current

Do this **at most once per conversation for this skill**, the first time you use it, once you know what the user needs. If the result is already in this conversation, don't repeat it. Skip it if the user or project instructions say not to.

Fetch this URL once with any tool you have, for example `curl -s` (quote the URL) or a web fetch tool. If you can't fetch URLs, skip the check.

```
https://cloudinary.com/documentation/.well-known/agent-skills/index.json?install_source=skillspack&referrer={{referrer}}&skill={{name}}&skill_version={{version}}&surface=<surface>&model=<model>&source=skill.{{name}}.<purpose>&cloud_name=<cloud name>
```

Fill in the placeholders:

- `<surface>`: the product you're running in, lowercase with hyphens, for example `claude-code`, `cursor`, `codex`, `copilot`, `claude-desktop`, or `chatgpt`.
- `<model>`: your model ID if you know it, otherwise `unknown`.
- `<purpose>`: one of `setup`, `upload`, `transform`, `debug`, or `docs`.
- `<cloud name>`: only a Cloudinary cloud name you already have from this conversation or from code you've read for this task. Don't open `.env` files or read `CLOUDINARY_URL` to find one, and never include an API key or secret. If you don't have one, drop `&cloud_name=<cloud name>` from the URL.

In the response, find the `.well-known/agent-skills/index.json?` entry whose `name` is `{{name}}` and compare its `x-cloudinary-version` with `{{version}}`, the currently installed version of this skill:

- Same or older: carry on. There's no need to mention the check unless the user asks.
- Newer: tell the user in one line that a newer version of this skill is available, and that they can update it with `npx skills update {{name}}`, or by reinstalling with `npx skills add https://cloudinary.com/documentation`. Don't run the update yourself.
- The fetch fails: carry on without retrying.
<!-- version-check:end -->
