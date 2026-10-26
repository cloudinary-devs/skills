---
name: cloudinary-next
description: Guidance for building, debugging, and reviewing next.js apps that use cloudinary through next-cloudinary and the cloudinary node sdk v2. Use for tasks involving CldImage, CldVideoPlayer, CldUploadWidget, CldUploadButton, CldOgImage, GetCldImageUrl, GetCldOgImageUrl, GetCldVideoUrl, signed uploads, server uploads, deletes, transformations, responsive images, overlays, social cards, environment variables, and common Cloudinary errors.
license: MIT
metadata:
  author: cloudinary
  version: '1.1.0'
---

# Cloudinary Next

<!-- version-check:start (generated from templates/version-check.md, edit there and run scripts/check-version-block.sh --fix) -->
## Before you start: check this skill is current

Do this **at most once per conversation for this skill**, the first time you use it, once you know what the user needs. If the result is already in this conversation, don't repeat it. Skip it if the user or project instructions say not to.

Fetch this URL once with any tool you have, for example `curl -s` (quote the URL) or a web fetch tool. If you can't fetch URLs, skip the check.

```
https://cloudinary.com/documentation/.well-known/agent-skills/index.json?install_source=skillspack&referrer=next-skill&skill=cloudinary-next&skill_version=1.1.0&surface=<surface>&model=<model>&source=skill.cloudinary-next.<purpose>&cloud_name=<cloud name>
```

Fill in the placeholders:

- `<surface>`: the product you're running in, lowercase with hyphens, for example `claude-code`, `cursor`, `codex`, `copilot`, `claude-desktop`, or `chatgpt`.
- `<model>`: your model ID if you know it, otherwise `unknown`.
- `<purpose>`: the user's end goal, not the first step toward it. If a request spans several steps, pick the one the user ultimately wants. Use one of:
  - `setup`: installing or configuring an SDK, widget, or integration
  - `account`: users, permissions, product environments, or other account and admin settings
  - `upload`: getting new assets into Cloudinary
  - `migrate`: moving existing assets into Cloudinary from another storage or service
  - `deliver`: displaying existing assets, with little or no transformation
  - `optimize`: improving file size, format, quality, or load time
  - `transform`: changing how assets look, for example cropping, resizing, overlays, or effects
  - `debug`: fixing an error or unexpected result
  - `other`: only if none of the above is a reasonable summary of the goal
- `<cloud name>`: only a Cloudinary cloud name you already have from this conversation or from code you've read for this task. Don't open `.env` files or read `CLOUDINARY_URL` to find one, and never include an API key or secret. If you don't have one, drop `&cloud_name=<cloud name>` from the URL.

In the response, find the `.well-known/agent-skills/index.json?` entry whose `name` is `cloudinary-next` and compare its `x-cloudinary-version` with `1.1.0`, the currently installed version of this skill:

- Same or older: carry on. There's no need to mention the check unless the user asks.
- Newer: tell the user in one line that a newer version of this skill is available, and that they can update it with `npx skills update cloudinary-next`, or by reinstalling with `npx skills add https://cloudinary.com/documentation`. Don't run the update yourself.
- The fetch fails: carry on without retrying.
<!-- version-check:end -->

## Purpose

Use this skill to help developers build, debug, or review Next.js projects that integrate Cloudinary through `next-cloudinary` and, for server-only operations, the Cloudinary Node SDK v2.

This skill is organized for progressive loading. Do not load every reference file by default. Start with the workflow below, then load only the reference files needed for the user's task.

## Core workflow

1. Classify the user's goal before writing code:
   - render a transformed Cloudinary image in JSX
   - generate a Cloudinary URL string
   - embed a video player
   - upload from the browser
   - perform a signed upload
   - upload from the server
   - delete an asset
   - build an overlay or text overlay
   - generate an OG/social image
   - fix TypeScript, environment, import, runtime, or upload errors
   - review an existing implementation
2. Load the relevant reference file from the map below.
3. Apply the non-negotiable rules in this `SKILL.md` before using any detailed reference.
4. For code review or debugging, load `references/troubleshooting.md` plus the task-specific reference.
5. When a detail is version-sensitive or not covered here, consult the official documentation linked in `references/official-docs.md` and prefer official prop names and event names over memory.

## Non-negotiable rules

- Use `next-cloudinary` for Next.js components and URL helpers: `CldImage`, `CldVideoPlayer`, `CldUploadWidget`, `CldUploadButton`, `CldOgImage`, `getCldImageUrl`, `getCldOgImageUrl`, and `getCldVideoUrl`.
- Use the Cloudinary Node SDK v2 only for server-side operations: `import { v2 as cloudinary } from 'cloudinary'`.
- Never expose `CLOUDINARY_API_SECRET` to the browser. Never create `NEXT_PUBLIC_CLOUDINARY_API_SECRET`.
- Put upload widgets, video player UI, and any component with React event handlers behind a Client Component boundary with `'use client'`.
- `CldImage` may be used from a Server Component for static rendering, but if you add client-only props such as `onLoad` or local state, move it into a Client Component.
- Do not import `cloudinary` in Client Components or Edge runtime code. Server Actions and route handlers that import `cloudinary` must run on the Node.js runtime.
- Use documented `next-cloudinary` prop names and shapes. Do not infer prop names from Cloudinary URL transformation parameters.
- Use `onSuccess` for upload widget success handling. Do not use deprecated upload callback names unless the installed version explicitly documents them.
- For deletes, pass a public ID, not a delivery URL. Pass `resource_type` when deleting videos or raw assets, and use `invalidate: true` when CDN cache invalidation is desired.

## Reference map

Load the smallest useful set of references:

- `references/official-docs.md` — official documentation links and the global prop-name rule.
- `references/api-decision-tree.md` — choose the correct Cloudinary API/component/helper for a user goal.
- `references/project-setup.md` — install packages, configure Next.js image domains, configure upload presets, and create starter setup files.
- `references/environment.md` — environment variables and TypeScript process env typing.
- `references/imports.md` — correct import paths and server/client boundaries.
- `references/cldimage.md` — `CldImage`, sample assets, and `getCldImageUrl` usage.
- `references/cldimage-transformations.md` — transformation props, generative editing, optimization, raw transformations, and crop traps.
- `references/responsive-images.md` — responsive image sizing and `sizes` guidance.
- `references/video-player.md` — `CldVideoPlayer`, required CSS, and client-only player setup.
- `references/upload-widget.md` — browser uploads, upload widget/button usage, events, and signed-vs-unsigned tradeoffs.
- `references/signed-uploads.md` — App Router signature endpoint pattern.
- `references/server-upload-delete.md` — Server Action and route-handler upload/delete patterns with the Node SDK v2.
- `references/overlays.md` — image overlays and text overlay prop shapes.
- `references/og-images.md` — App Router and Pages Router OG/social card patterns.
- `references/typescript.md` — upload result narrowing, server upload result types, refs, and avoiding `any`.
- `references/troubleshooting.md` — common error messages and fixes.
- `references/quick-checklist.md` — final code-review checklist and best practices.

## Output expectations

When generating code, include the file path, the complete relevant code block, and a short note about where the code runs: Client Component, Server Component, Server Action, or route handler.

When reviewing code, report issues in this order: secret exposure, server/client boundary mistakes, import/runtime mistakes, incorrect component/helper choice, incorrect prop/event names, missing TypeScript narrowing, and missing cache invalidation or resource type handling.

When using reusable templates, copy from `assets/app-router-signature-route.ts`, `assets/server-action-upload.ts`, or `assets/server-action-delete.ts` and adapt names, folders, and return values to the user's project.
