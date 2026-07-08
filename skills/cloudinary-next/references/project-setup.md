# Project setup

Use this when starting a new Next.js + Cloudinary project or adding missing setup files to an existing project.


## Project setup (rules-only / without CLI)

If the user is **not** using a CLI scaffold and only has these rules, generate the following so they get a correct config end-to-end.

**1. Install**

```bash
npm install next-cloudinary
# Add the Node SDK only if you do server-side uploads/deletes/signing:
npm install cloudinary
```

Use `npm install <package>` with **no version** so npm gets the latest compatible version. In `package.json` use a **caret range** (`"next-cloudinary": "^6.0.0"`). Do not pin exact versions unless verified on npm.

**2. Environment (`.env.local`)**

Create `.env.local` in the project root (Next.js auto-loads it, and it must be in `.gitignore`):

```bash
# Required (public, client-safe)
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=your_cloud_name

# Required only for the Upload Widget with SIGNED uploads
NEXT_PUBLIC_CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret  # ⚠️ SERVER ONLY — never NEXT_PUBLIC_

# Optional advanced config
NEXT_PUBLIC_CLOUDINARY_SECURE_DISTRIBUTION=cdn.example.com
NEXT_PUBLIC_CLOUDINARY_PRIVATE_CDN=true
```

Rules:
- ✅ `NEXT_PUBLIC_*` is exposed to the browser. Use it for `CLOUD_NAME` and (optionally) `API_KEY` (the API key is not secret).
- ❌ **Never** prefix `CLOUDINARY_API_SECRET` with `NEXT_PUBLIC_`. The secret must only be read on the server (`process.env.CLOUDINARY_API_SECRET`).
- ✅ `.env.local` must be in `.gitignore` (Next.js's default `.gitignore` already does this — verify it).
- ✅ **Restart the dev server** after editing `.env.local`; Next.js does not hot-reload env vars.
- ❌ Do **not** create a separate `server/.env` or load env files manually with `dotenv` in Next.js — Next.js loads `.env.local` automatically for both server and client (with the `NEXT_PUBLIC_` rule).

**3. `next.config.js` (only if you use `<Image>` or fetch Cloudinary URLs through the Next image optimizer)**

`<CldImage>` already serves through Cloudinary's CDN, so it does **not** require `images.remotePatterns` to work. Add `remotePatterns` only if you also use the standard Next.js `<Image>` with a Cloudinary `src`:

```js
// next.config.js
/** @type {import('next').NextConfig} */
module.exports = {
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: 'res.cloudinary.com' },
    ],
  },
};
```

**4. Signature route handler (only if signed uploads)**

Create `app/api/sign-cloudinary-params/route.ts` (App Router) — see **"Signed uploads (App Router)"** below for the canonical implementation.

**5. Summary for rules-only users**
- **Env**: `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` is required; add `NEXT_PUBLIC_CLOUDINARY_API_KEY` + `CLOUDINARY_API_SECRET` only when signing uploads. Restart dev server after edits.
- **No `Cloudinary` instance to construct**: `next-cloudinary` reads env automatically. Just import components/helpers and use them.
- **Components are client-side**: `CldUploadWidget`, `CldUploadButton`, `CldVideoPlayer` always need `"use client"`. `CldImage` works in both, but make the file a Client Component if you also use refs / event handlers / state with it.
- **Server work uses the Node SDK** (`cloudinary` v2) inside Server Actions or route handlers — never in client code.

## Upload Presets

- **Unsigned** = client-only uploads, no backend. **Signed** = backend required, more secure. See **"Signed vs unsigned uploads"** below for when to use which.
- ✅ Create the preset at https://console.cloudinary.com/app/settings/upload/presets
- ✅ For unsigned: set the preset's **Signing Mode** to **Unsigned**, then pass the preset name to `<CldUploadWidget uploadPreset="..." />`.
- ✅ For signed: set the preset to **Signed** (or use the built-in `ml_default`, which is signed by default — note that users can delete it).
- ⚠️ If the preset is missing or the wrong type, the widget shows an error like "Upload preset not found" or "Invalid upload preset for unsigned upload".
- **When unsigned upload fails** — debug checklist:
  1. Is the preset name in `uploadPreset` exactly correct (no typos)?
  2. Does the preset exist in the dashboard?
  3. Is it set to **Unsigned**?
  4. Was the dev server restarted after `.env.local` changes?

## Installing Cloudinary packages

- ✅ **Install latest**: `npm install <package>` (no version) so npm gets the latest compatible. Use a caret in `package.json`. Do not pin to an exact version unless verified on npm.
- ✅ **Package names only**: `next-cloudinary` (the Next.js wrapper), `cloudinary` (Node SDK v2 — server-side only). Do not invent names like `@cloudinary/next` or `next-cloudinary-server`.
- ❌ **WRONG**: `npm install next-cloudinary@1.2.3` (exact pin) when you haven't verified the version exists.
- ❌ **WRONG**: Installing `@cloudinary/url-gen` or `@cloudinary/react` for a Next.js project — `next-cloudinary` already wraps the URL builder. Only install those if the user explicitly wants to bypass `next-cloudinary`.
