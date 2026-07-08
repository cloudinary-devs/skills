# CldImage and URL helpers

Use this for JSX image rendering with `CldImage`, demo assets, and string URL generation with `getCldImageUrl`.


## CldImage — basic usage

`CldImage` extends Next.js `<Image>`. **Required props**: `src` (a Cloudinary public ID), `alt`, `width`, `height` (or `fill`).

```tsx
import { CldImage } from 'next-cloudinary';

<CldImage
  src="samples/cloudinary-icon"   // public ID, NOT a URL
  width={960}
  height={600}
  sizes="100vw"                   // strongly recommended for responsive
  alt="Cloudinary icon"
/>;
```

- ✅ **`src` is a public ID**, e.g. `"samples/cloudinary-icon"` or `"my-folder/my-image"`. Do **not** include a file extension. Slashes are allowed for folders. Public IDs are case-sensitive.
- ✅ A full Cloudinary URL is also accepted as `src` **only if it includes a version segment** (e.g. `/v1234/`). To preserve transformations already in that URL, also pass `preserveTransformations`.
- ✅ Pass a **`sizes`** prop on every `<CldImage>` that isn't a fixed-size icon — this is what powers responsive `srcset`. See "Responsive images".
- ✅ **Optimization is automatic**: by default `format=auto` and `quality=auto` are applied. Don't add raw `f_auto` / `q_auto` yourself.
- ✅ `<CldImage>` can render in a Server Component, **but** if the file uses event handlers (`onLoad`, `onError`), refs, or other client-only APIs, add `"use client"` at the top of the file.

### Sample assets (use for demos when no upload yet)

Cloudinary accounts ship with sample public IDs that **may** exist (users can delete them — always handle `onError`):
- Images: `samples/cloudinary-icon`, `samples/two-ladies`, `samples/food/spices`, `samples/landscapes/beach-boat`, `samples/bike`, `samples/landscapes/girl-urban-view`, `samples/animals/reindeer`, `samples/food/pot-mussels`
- Video: `samples/elephants`
- ✅ Default for a single image: `samples/cloudinary-icon`. Prefer uploaded assets when available.

## getCldImageUrl — same API as CldImage, returns a URL string

Use when you need a URL string (metadata, route handlers, plain `<img>` outside React, server-side prefetching, etc.). Same options as `CldImage`.

```ts
import { getCldImageUrl } from 'next-cloudinary';

const url = getCldImageUrl({
  src: 'samples/cloudinary-icon',
  width: 960,
  height: 600,
  crop: 'fill',
  removeBackground: true,
});
```

✅ **Use `getCldImageUrl` instead of constructing Cloudinary URLs by hand or with `cloudinary.url()` from the Node SDK** — it stays in sync with `<CldImage>` semantics (auto format/quality, two-stage crop opt-ins, etc.).
