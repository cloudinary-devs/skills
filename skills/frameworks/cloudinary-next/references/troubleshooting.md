# Troubleshooting

Use this when the user provides an error message, broken behavior, or asks for a code review focused on bugs.

## Table of contents

- Install errors
- Environment variable errors
- Component / `use client` errors
- Import errors
- `CldImage` errors
- Upload widget errors
- Signed upload errors
- Server-side upload / delete errors
- `CldVideoPlayer` errors
- `CldOgImage` / social card errors
- TypeScript errors


# ⚠️ COMMON ERRORS & SOLUTIONS

## Install Errors

### `npm install next-cloudinary` fails with `ERESOLVE` / peer dependency conflict
- ❌ Problem: the project is on Next.js 15 or earlier. next-cloudinary v7 requires Next.js 16 (and React 18.2 or 19, Node.js 22+).
- ✅ Solution: install v6 with `npm install next-cloudinary@6`, or upgrade Next.js to 16 first. Don't use `--force` or `--legacy-peer-deps` to push v7 onto an older Next.js.

## Environment Variable Errors

### "Cloud name is required" / images don't render
- ❌ Problem: `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` is missing or has the wrong prefix.
- ✅ Solution:
  1. `.env.local` exists at the project root with `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=...` (note the `NEXT_PUBLIC_` prefix).
  2. `.env.local` is in `.gitignore`.
  3. **Restart `next dev`** after changes.

### "Invalid Signature" on a signed upload
- ❌ Problem: `CLOUDINARY_API_SECRET` is missing on the server, or the route handler uses a stale value, or the signature endpoint returns the wrong shape.
- ✅ Solution:
  1. Confirm `CLOUDINARY_API_SECRET` is set on the server **without** `NEXT_PUBLIC_`.
  2. Confirm the route handler returns `{ signature }` (not `{ data: { signature } }`, not just the raw string).
  3. Confirm you're calling `cloudinary.utils.api_sign_request(paramsToSign, process.env.CLOUDINARY_API_SECRET)` — passing the secret as the second arg, on every request.
  4. Confirm you're using **Node SDK v2** (`import { v2 as cloudinary } from 'cloudinary'`), not v1.
  5. Confirm the route runs on the **Node** runtime (default), not Edge.

### "process.env.CLOUDINARY_API_SECRET is undefined" in a Server Action
- ❌ Problem: `.env.local` not loaded (file misnamed, or in the wrong directory) or the dev server wasn't restarted.
- ✅ Solution: confirm filename (`.env.local`, not `.env.local.txt`), location (project root), and restart the dev server. Don't use `dotenv` manually — Next.js loads it automatically.

## Component / "use client" errors

### "Functions cannot be passed directly to Client Components" / "Event handlers cannot be passed to Client Component props"
- ❌ Problem: a Server Component passes a function to a `next-cloudinary` component: an event handler (`onSuccess`, `onLoad`, `onPlay`, …), a ref, or the render-function child of `<CldUploadWidget>`.
- ✅ Solution: add `"use client"` at the top of the file, or move the component and its handlers into a small Client Component and render that from the server file. To call server code on upload, `<CldUploadButton>` and `<CldUploadWidget>` accept Server Actions in their `*Action` props (e.g. `onSuccessAction`).

### "You're importing a component that needs `useState`…" / `useState is not a function` / `useRef is not a function` (v6)
- ❌ Problem: on next-cloudinary v6, a component (including `<CldImage>`) is rendered from a Server Component. v6 components don't include `'use client'`.
- ✅ Solution: add `"use client"` to the file, or wrap the component in a Client Component. On Next.js 16, upgrading to v7 also fixes this (see `references/migrating-to-v7.md`).

## Import Errors

### "Cannot find module 'next-cloudinary/dist/cld-video-player.css'"
- ❌ Problem: Wrong path or the package isn't installed.
- ✅ Solution: install `next-cloudinary`, then import exactly: `import 'next-cloudinary/dist/cld-video-player.css';`. Don't use `cloudinary-video-player/...` — that's the standalone package, not the Next wrapper.

### "Can't resolve 'next-cloudinary/cld-video-player.css'"
- ❌ Problem: the short CSS path only exists in v7. The project is on v6.
- ✅ Solution: use `next-cloudinary/dist/cld-video-player.css`, which works in both.

### "Module not found: Can't resolve 'next-cloudinary/dist/…'" / `ERR_PACKAGE_PATH_NOT_EXPORTED`
- ❌ Problem: v7 defines an `exports` map, so imports of internal files such as `next-cloudinary/dist/index.js` no longer resolve.
- ✅ Solution: import from `next-cloudinary`. The only supported file paths are the video player CSS (`next-cloudinary/dist/cld-video-player.css`, or `next-cloudinary/cld-video-player.css` in v7).

### "Module not found: cloudinary" in a route handler
- ❌ Problem: `cloudinary` (Node SDK) wasn't installed.
- ✅ Solution: `npm install cloudinary`. Verify import is `import { v2 as cloudinary } from 'cloudinary'`.

### Edge runtime errors when importing `cloudinary`
- ❌ Problem: Route handler or middleware has `export const runtime = 'edge'`, but the Cloudinary Node SDK requires Node APIs.
- ✅ Solution: remove the edge runtime from that file (default Node runtime is fine), or move the SDK call to a Node-runtime route.

## CldImage Errors

### Image renders broken / 404
- ✅ Checks:
  1. Is `src` a **public ID** (no extension, no leading slash, case-sensitive)? If you pass a URL, it must include `/v1234/`.
  2. Is the asset actually in this Cloudinary cloud? Mismatch between cloud names and uploaded assets is common.
  3. Are you using a sample public ID that the user may have deleted? Add an `onError` fallback.

### `aspectRatio` has no effect
- ❌ Problem: `aspectRatio` only applies in some crop modes (`auto`, `crop`, `fill`, `lfill`, `fill_pad`, `thumb`) AND requires no concrete `width`/`height`.
- ✅ Solution: pass `fill` (Next Image fill prop), a crop mode that crops (e.g. `crop="fill"`), and **omit** `width`/`height`. Wrap the parent with `position: relative` and an `aspect-ratio` style.

### Image looks low-resolution at large sizes
- ❌ Problem: Older versions of `next-cloudinary` did 2-stage cropping by default, which capped resolution. v6+ removed that default.
- ✅ Solution: upgrade to `next-cloudinary` v6+. If you opt back in via `crop={{ type: '...', source: true }}`, set the source `width`/`height` large enough.

### Dynamic crop changes appearance at different breakpoints
- ❌ Problem: `thumb` (and similar) crops differ per requested size.
- ✅ Solution: use the two-stage crop pattern — `crop={{ type: 'thumb', source: true }}`.

### Mixing `f_auto`/`q_auto` props with `rawTransformations` produces duplicates
- ❌ Problem: Setting `format` or `quality` in props **and** in `rawTransformations`.
- ✅ Solution: pick one. If `rawTransformations` already includes `f_auto`/`q_auto`, those are detected and the props won't double-add — but don't set `format="auto"` and `rawTransformations={['f_auto']}` together; pick one path.

### "preserveTransformations" doesn't preserve anything
- ❌ Problem: The full Cloudinary URL passed as `src` doesn't include a version segment (`/v1234/`).
- ✅ Solution: include the version. Without it, the URL parser can't safely identify where transformations end.

## Upload Widget Errors

### Upload fails for unsigned uploads — debug checklist
- ✅ In order:
  1. Is `uploadPreset` set on the widget and spelled exactly the same as in the dashboard?
  2. Does the preset exist?
  3. Is it set to **Unsigned** in the dashboard?
  4. Was the dev server restarted after `.env.local` changes?
  5. Are file size / type allowed by the preset?

### "Upload preset must be whitelisted for unsigned uploads"
- ❌ Problem: The preset is **Signed** in the dashboard, but you used `uploadPreset` without `signatureEndpoint`.
- ✅ Solution: either flip the preset to Unsigned in the dashboard, or add a `signatureEndpoint` (see signed uploads pattern).

### `onUpload` is never called, or "Property 'onUpload' does not exist"
- ❌ Problem: `onUpload` was deprecated in v6 and removed in v7.
- ✅ Solution: use `onSuccess`. The second argument is an object: `(result, { widget }) => …` (with `onUpload` it was `(result, widget)`).

### `result.info` is a string, not an object
- ❌ Problem: You're handling a non-success event (e.g. `queues-end`, `display-changed`) where `info` is a string.
- ✅ Solution: only treat `result.info` as upload info inside `onSuccess`, and narrow with a type guard before reading `public_id`.

### Widget opens, user uploads, but nothing happens after
- ❌ Problem: You may be handling `onSuccess` but never closing the widget — looks broken to the user.
- ✅ Solution: call `widget.close()` from `onSuccess` (or use `onQueuesEnd` for multi-file uploads).

## Signed Upload Errors

### Route handler returns 200 but widget still says "Invalid Signature"
- ❌ Problem: Wrong response shape, or the secret used to sign doesn't match the cloud name being uploaded to.
- ✅ Solution:
  1. Return exactly `{ signature }` (you can include `timestamp`, `api_key`, `cloud_name` too, but the field name `signature` must be present).
  2. Confirm `cloud_name`, `api_key`, `api_secret` in the route's `cloudinary.config()` call match the same Cloudinary account.
  3. Confirm you're not toggling between cloud names (e.g. dev vs prod) mid-session.

### "Missing required parameter - api_key"
- ❌ Problem: `NEXT_PUBLIC_CLOUDINARY_API_KEY` is unset, so the widget can't include it.
- ✅ Solution: set `NEXT_PUBLIC_CLOUDINARY_API_KEY` and restart the dev server. Note: API key is public-safe; the **secret** is what must stay server-only.

### Signed upload works locally, fails on Vercel
- ✅ Checks:
  1. Are env vars configured on Vercel (Project → Settings → Environment Variables)?
  2. Is `CLOUDINARY_API_SECRET` set as a **server-side** env var (not exposed to client)?
  3. Did you redeploy after adding env vars?

## Server-side Upload / Delete Errors

### "Must supply api_key" on `cloudinary.uploader.upload`
- ❌ Problem: `cloudinary.config(...)` not called, or env vars unset on the server.
- ✅ Solution: call `cloudinary.config({ cloud_name, api_key, api_secret })` once at the top of the server file (idempotent). Confirm env vars are present in the runtime where the action/route runs.

### `File is not a valid input` on `cloudinary.uploader.upload`
- ❌ Problem: Passing a `File` / `Blob` directly. The Node SDK doesn't accept those.
- ✅ Solution: convert to a `Buffer` (or base64 string / data URI), then use `upload_stream(...).end(buffer)` or `upload(`data:${mime};base64,${b64}`)`.

### Edge runtime fails: "Module not found: 'fs'" / "Module not found: 'crypto'"
- ❌ Problem: The Cloudinary Node SDK depends on Node APIs.
- ✅ Solution: ensure the route handler / Server Action runs on the **Node** runtime (default; remove any `export const runtime = 'edge'`).

### `destroy` returns `{ result: 'not found' }` even though the asset exists
- ✅ Checks:
  1. `publicId` matches exactly (case-sensitive, includes folder path, no file extension).
  2. `resource_type` matches the asset (`'image'` is the default; videos need `'video'`).
  3. Use the same cloud name. A delete request signed for cloud A can't delete in cloud B.

### Deleted asset still loads on the page
- ❌ Problem: Cached at the CDN.
- ✅ Solution: pass `invalidate: true` to `destroy` to evict the CDN cache.

## CldVideoPlayer Errors

### "Cannot find module 'next-cloudinary/dist/cld-video-player.css'"
- ✅ Solution: install `next-cloudinary`. This path works in v6 and v7; v7 also accepts `next-cloudinary/cld-video-player.css`.

### Poster image is broken when `aspectRatio` is set (v7.0.x)
- ❌ Problem: known limitation with Video Player v4. The video itself plays normally.
- ✅ Solution: remove `aspectRatio` if it isn't needed, or also set a crop mode such as `cropMode="fill"`, which crops the video to that ratio. `cropMode` isn't in the TypeScript types yet, so it needs a cast. A fix is planned for a follow-up release.

### Custom poster from the Video Player Studio isn't shown
- ✅ Checks: v7 shows Studio posters automatically; v6 (Video Player v1.x) doesn't. A `poster` prop set in code takes precedence.

### Player styles are broken / unstyled controls
- ❌ Problem: CSS not imported.
- ✅ Solution: `import 'next-cloudinary/dist/cld-video-player.css';` once on a layout or the page using the player.

### Player throws hydration / removeChild errors
- ❌ Problem: on v6, the component is in a Server Component; or the page suspends and unmounts the player at the wrong time.
- ✅ Solution: on v6, add `"use client"` to the file. Wrap the player in its own component if needed so it's not torn down by parent suspense.

### Player is blank after navigating away and back
- ❌ Problem: on v6, the player doesn't re-initialise after it's unmounted and mounted again (for example after client-side navigation away and back).
- ✅ Solution: fixed in v7. See `references/migrating-to-v7.md`.

### Video doesn't autoplay
- ❌ Problem: Browsers block autoplay with sound. The `autoplay` prop also takes a string `autoplayMode` (e.g. `"on-scroll"`).
- ✅ Solution: pass `muted` along with `autoplay` for unconditional autoplay; or use `autoplay="on-scroll"` for play-when-visible.

## CldOgImage / Social card Errors

### `<CldOgImage>` renders nothing in the App Router
- ❌ Problem: It only works in the Pages Router.
- ✅ Solution: in the App Router, use `getCldOgImageUrl` inside `generateMetadata` and put the URL into `metadata.openGraph.images` and `metadata.twitter.images`.

### OG image is correct on a single page but stale on social media
- ❌ Problem: Social platforms cache OG images aggressively.
- ✅ Solution: change the URL (e.g. add a query param like `?v=2`) or re-scrape via the platform's debugger (Facebook / X / LinkedIn each provide one).

## TypeScript Errors

### "Property 'paramsToSign' does not exist on type 'unknown'"
- ✅ Solution: type the request body in your route handler:
  ```ts
  const { paramsToSign } = (await request.json()) as { paramsToSign: Record<string, string | number> };
  ```

### "Type '{ public_id: string; … }' is not assignable to type 'string'"
- ❌ Problem: Treating `result.info` as a string in some branches and an object in others.
- ✅ Solution: narrow with a type guard (`isUploadInfo`) before accessing object fields.

### "Property 'NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME' does not exist on type 'ProcessEnv'"
- ✅ Solution: declare the env vars in an `env.d.ts` (see "Environment Variable Typing" above).

### "Type 'RefObject<unknown>' is not assignable…" / "Type 'null' is not assignable to type 'RefObject<…>'"
- ✅ Solution: type refs with the actual element / instance type:
  ```ts
  import type { CloudinaryVideoPlayer } from 'next-cloudinary';

  const videoRef = useRef<HTMLVideoElement | null>(null);
  const playerRef = useRef<CloudinaryVideoPlayer | null>(null);
  ```

---
