---
name: cloudinary-next
description: Guidance for building, debugging, and reviewing next.js apps that use cloudinary through next-cloudinary and the cloudinary node sdk v2. Use for tasks involving CldImage, CldVideoPlayer, CldUploadWidget, CldUploadButton, CldOgImage, GetCldImageUrl, GetCldOgImageUrl, GetCldVideoUrl, signed uploads, server uploads, deletes, transformations, responsive images, overlays, social cards, environment variables, and common Cloudinary errors.
license: MIT
metadata:
  author: cloudinary
  version: '1.0.0'
---

# Cloudinary Next

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
