# Migrating from next-cloudinary v6 to v7

Use this when a project is on v6 and the user asks about upgrading, or when you recommend the upgrade once at the start of a session.

## Can this project upgrade?

Check before recommending anything:

| Project | Recommendation |
| --- | --- |
| Next.js 16, React 18.2 or 19, Node.js 22+ | Can upgrade now. |
| Next.js 15 or earlier | Needs a Next.js 16 upgrade first. That is a separate, larger change: mention it, but don't push it during an unrelated task. |
| React below 18.2, or Node.js below 22 | Needs those upgraded first. |
| The user doesn't want to upgrade | Stay on v6 (see `references/v6.md`). It continues to work. |

## What the upgrade gives them

- `CldVideoPlayer` uses Cloudinary Video Player v4 (v6 uses 1.11.1). Custom posters saved in the Video Player Studio are shown automatically.
- Components include `'use client'`, so they can be rendered from Server Components when no functions are passed.
- Fixes: the video player re-initialises after unmount/remount (for example navigating away and back), `q_auto` no longer repeats in video URLs with a `transformation` array, and overlay text with several commas no longer breaks image URLs.
- More complete TypeScript types, and `seed` for `fillBackground`.

## Find what needs changing

Search the project for:

| Search for | Change |
| --- | --- |
| `onUpload` | Removed in v7. Use `onSuccess`. The second argument is an object: `onUpload={(result, widget) => …}` becomes `onSuccess={(result, { widget }) => …}`. |
| Imports from `next-cloudinary/dist/…` other than `dist/cld-video-player.css` | v7 defines an `exports` map. Import from `next-cloudinary` instead. |
| The `overlay` option (singular) | Removed from the types. It was never applied in v6, so replace it with `overlays` (an array) if the overlay is wanted, otherwise delete it. |
| `assetType` values other than `'image'`, `'images'`, `'video'`, `'videos'` or `'all'` | Now a type error. Other values such as `'raw'` already threw at runtime. |
| `analytics: false` passed to `getCldImageUrl` or `getCldVideoUrl` | No longer accepted. It never disabled analytics in v6: remove it. |
| Code that calls `cloudinaryLoader` directly or uses `CloudinaryLoaderCldOptions` | `src` is now required. |
| Option types imported from `@cloudinary-util/url-loader` | Some names and shapes changed. Prefer the types exported by `next-cloudinary`. |
| Custom CSS targeting the video player | The player moved from v1.11.1 to v4.1.2 (three majors). Check the styles still apply. |
| `CldVideoPlayer` with `aspectRatio` | Known limitation in 7.0: the poster image fails to load (the video plays normally). See `references/video-player.md`. |

`'use client'` wrappers that only existed so a component could render in a Server Component can stay; removing them is optional.

## Steps

1. Confirm Next.js 16, React 18.2 or 19, and Node.js 22 or later.
2. `npm install next-cloudinary@7`
3. Apply the changes found above.
4. Run the type check and a production build (`next build`), then check pages that use `CldVideoPlayer` and `CldUploadWidget` in the browser.

Full release notes: https://github.com/cloudinary-community/next-cloudinary/releases
