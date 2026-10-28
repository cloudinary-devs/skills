# Quick checklist and best practices

Use this at the end of generation or review tasks to catch common Cloudinary + Next.js mistakes before finalizing.

## Best Practices
- ✅ Default to `<CldImage>` for any Cloudinary image. Use `getCldImageUrl` only when you need a string URL.
- ✅ Always pass `sizes` for non-icon images.
- ✅ Always include `alt` on `<CldImage>`.
- ✅ Use `crop={{ type: '<dynamic>', source: true }}` for dynamic crops (`thumb`, etc.) so responsive variants stay consistent.
- ✅ For `aspectRatio`, also use `fill` and a crop mode that crops; omit `width`/`height`.
- ✅ Store `public_id` from upload results (and asset type / dimensions if you'll need them) — not the full URL.
- ✅ For client uploads, default to **unsigned**; switch to signed only when explicitly requested.
- ✅ Never hold the API secret on the client; never prefix it with `NEXT_PUBLIC_`.
- ✅ Add `"use client"` at the top of any file that passes functions to a `next-cloudinary` component (event handlers, refs, the `CldUploadWidget` render function). On v6, add it to any file that uses a `next-cloudinary` component.
- ✅ Use the **Node SDK v2** (`import { v2 as cloudinary } from 'cloudinary'`) for all server-side upload/delete/sign work; run on the Node runtime.
- ✅ Pass `invalidate: true` on `destroy` to evict the CDN cache.
- ✅ Use TypeScript: type upload results, env vars, refs.

---

## Quick Reference Checklist

When something isn't working, check:
- [ ] **Picked the right tool?** → `<CldImage>` for JSX images, `getCldImageUrl` for URL strings, `<CldUploadWidget>` for browser uploads, `cloudinary.uploader.upload` (Node SDK, server) for server-side uploads, `cloudinary.uploader.destroy` (Node SDK, server) for deletes
- [ ] **Version**: code matches the installed next-cloudinary major (v7 by default; `references/v6.md` for v6)
- [ ] **`"use client"`** at the top of any file passing event handlers, refs, or the `<CldUploadWidget>` render function (v6: any file using a `next-cloudinary` component)
- [ ] **Env vars**: `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` set; `CLOUDINARY_API_SECRET` (server only, NEVER prefixed with `NEXT_PUBLIC_`); dev server restarted after edits
- [ ] **`.env.local` in `.gitignore`** — never commit secrets
- [ ] **`<CldImage src>`** is a Cloudinary public ID (no extension, no leading slash) — or a full URL with `/v1234/` and `preserveTransformations`
- [ ] **`<CldImage>`**: pass `sizes` for responsive images; for `aspectRatio` also use `fill` and a crop mode and omit `width`/`height`
- [ ] **Dynamic crops** (`thumb`, etc.): use `crop={{ type: 'thumb', source: true }}` to keep results consistent across breakpoints
- [ ] **`<CldVideoPlayer>`**: `"use client"` + `import 'next-cloudinary/dist/cld-video-player.css'`
- [ ] **`<CldUploadWidget>` unsigned**: preset is **Unsigned** in the dashboard, name matches `uploadPreset` exactly
- [ ] **`<CldUploadWidget>` signed**: `signatureEndpoint="/api/sign-cloudinary-params"`; route returns `{ signature }`; uses Node SDK v2 (`import { v2 as cloudinary } from 'cloudinary'`); runs on Node runtime
- [ ] **Use `onSuccess`** (not deprecated `onUpload`); narrow `result.info` with a type guard before reading `public_id`
- [ ] **Server uploads**: `"use server"` (or route handler), Node runtime, convert `File` → `Buffer` before `upload_stream`
- [ ] **Delete**: `cloudinary.uploader.destroy(publicId, { resource_type, invalidate: true })`; `result === 'ok'` on success
- [ ] **OG images**: App Router → `getCldOgImageUrl` in `generateMetadata`; Pages Router → `<CldOgImage>` outside `<Head>`
- [ ] **Overlays**: `publicId` (image) or `text` (text) per overlay; gravity uses underscores (`"south_east"`); blend modes go in `appliedEffects`
- [ ] **Installing Cloudinary packages**: next-cloudinary v7 on Next.js 16, `next-cloudinary@6` on Next.js 15 or earlier; use caret in `package.json`; valid names are `next-cloudinary` and `cloudinary`
- [ ] **OG images (App Router)**: on Next.js 15+, `await params` in `generateMetadata`
- [ ] **TypeScript**: define an upload-result interface; type env vars in `env.d.ts`; use `unknown` + guards instead of `any`
- [ ] **Sample assets** (`samples/cloudinary-icon`, `samples/elephants`, etc.) may have been deleted — handle `onError` and provide an upload path
