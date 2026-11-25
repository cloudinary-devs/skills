# PDP integration by stack

Read this when writing the integration for a specific stack, or migrating from
v1. Get the current widget version from the
[changelog](https://cloudinary.com/documentation/product_gallery_changelog.md?install_source=skillspack&referrer=gallery-skill)
and pin it. The examples use `your-cloud-name`, the tag `sku-1042` and a
`<version>` placeholder.

## Script embed (plain HTML, Vue, Angular, server-rendered platforms)

See the quick start in SKILL.md. Notes by stack:

- **Server-rendered platforms (not Node):** put the container and the config
  in the product template, and render the product's tag or public IDs into the
  config server-side. The widget itself renders in the browser.
- **Vue and Angular:** create the instance in the mounted hook, and call
  `destroy()` in the unmount hook. Do not recreate the instance on every
  re-render: call `update({ mediaAssets })` when the product changes. Sample
  apps: the
  [Vue](https://github.com/cloudinary-devs/cld-vue-product-gallery) and
  [Angular](https://github.com/cloudinary-devs/cld-angular-product-gallery)
  Product Gallery repositories.
- **Avoid layout shift:** the script embed paints after load. Reserve the space
  with CSS so the page does not jump:

```html
<div id="product-gallery" style="max-width: 640px; width: 100%; aspect-ratio: 4 / 3; margin: 0 auto"></div>
```

Match the `aspectRatio` option to the container's ratio (`"4:3"`). Thumbnails
add height beside or below the viewer, so measure the final height once and
reserve that instead if the shift remains.

## Next.js App Router (server-rendered gallery)

```bash
npm install @cloudinary/product-gallery
```

The package is ESM only, needs Node 18 or later, and takes React 18 or 19 as a
peer dependency. Import the stylesheet once; it is not injected for you.

```tsx
// app/layout.tsx
import "@cloudinary/product-gallery/index.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

```tsx
// app/products/[sku]/page.tsx  (Server Component; Next.js 15 and later pass params as a Promise)
import { resolveConfig } from "@cloudinary/product-gallery/server";
import { GalleryClient } from "./GalleryClient";

const MAX_WIDTH = 640; // same number as the container's max-width

export default async function ProductPage({ params }: { params: Promise<{ sku: string }> }) {
  const { sku } = await params;
  const resolvedConfig = await resolveConfig({
    cloudName: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME!,
    aspectRatio: "4:3",
    viewerWidthHint: MAX_WIDTH,
    mediaAssets: [
      { tag: sku, transformation: { crop: "fill" } },
      { tag: sku, mediaType: "video" },
      { tag: `${sku}-360`, mediaType: "spin" },
    ],
  });

  return (
    <div style={{ maxWidth: MAX_WIDTH, width: "100%", margin: "0 auto" }}>
      <GalleryClient resolvedConfig={resolvedConfig} />
    </div>
  );
}
```

```tsx
// app/products/[sku]/GalleryClient.tsx
"use client";
import { Gallery, type ConfigProps } from "@cloudinary/product-gallery";

export function GalleryClient({ resolvedConfig }: { resolvedConfig: ConfigProps }) {
  return <Gallery resolvedConfig={resolvedConfig} />;
}
```

`viewerWidthHint` tells the server how wide the container will be so the first
image request is the right size and hydration matches. Without it the widget
emits `sizes="100vw"`. `viewportBreakpoints` apply after hydration, so on a
phone the breakpoint layout appears a moment after first paint. For the rest of
the Next.js project setup, use cloudinary-next. `resolveConfig` does not
reject when a tag is empty or its list fails: it logs a warning and leaves that
tag out, so check the server logs when an asset is missing.

## React without SSR

Call `resolveConfig` in an effect, then render `<Gallery>`. Remount with a
`key` when the product changes, because the component has no `update()`. Lazy
load it (`React.lazy`) so three.js, which the package imports for 3D, stays out
of the main bundle. A complete component is in the
[guide](https://cloudinary.com/documentation/product_gallery.md?install_source=skillspack&referrer=gallery-skill#using_the_npm_package_in_a_client_only_react_app).

## Express, Remix and other React servers

`renderToString(createElement(Gallery, { resolvedConfig }))` on the server,
embed `resolvedConfig` as JSON in the page, and `hydrateRoot` on the client
with the same config. Inline or serve `@cloudinary/product-gallery/index.css`.
Full code is in the guide section "Generic React server-side rendering".

## Non-React stores that need a server-rendered gallery

The documented server-rendering path is React only. For a Vue, Svelte, Angular
or non-Node storefront, the supported option is the script embed, rendered on
the client, with space reserved as above. Do not invent a server-rendering
path from internals. If the user needs it, say that it is not documented and
point them to Cloudinary support.

## Private CDN or custom hostname

```js
cloudinary.galleryWidget({
  container: "#product-gallery",
  cloudName: "your-cloud-name",
  secure: true,
  privateCdn: true,
  secureDistribution: "images.example-store.com",
  mediaAssets: [{ tag: "sku-1042" }],
});
```

Use these only when the account has a private CDN or custom delivery hostname
(CNAME), and set them to match it, or the widget's URLs will not resolve. They
keep every image on the store's own domain.

## Migrating from v1

v2 keeps v1.3.4's parameters, methods and events, so a page that only calls the
API needs only the script URL changed:

| Before | After |
| --- | --- |
| `https://product-gallery.cloudinary.com/<any>/all.js` (including `latest`) | `https://product-gallery-v2.cloudinary.com/<pinned version>/all.js` |

Expect these differences and check each:

1. **Image URLs change.** v2 uses `srcset`, so derived-image URLs differ from
   v1's and CDN caches warm up again.
2. **Sizing.** v1 measured the container in JavaScript; v2 is CSS only. If the
   layout relied on the widget's pixel size, constrain the container instead.
3. **Custom CSS.** v1 class names were hashed (`css-xxxx`) and v1 `data-test`
   hooks are not emitted unless `testAttributes: true`. Rewrite overrides
   against v2's `.pgw` class names, or use config parameters.
4. **Video player.** The Cloudinary Video Player inside the gallery is v4, so
   CSS aimed at v1's `.vjs-` classes may need updating.
5. **Temporary bridge.** `useLegacyV1Mode: true` renders v1's markup hooks on
   top of v2 for the script embed. It is deprecated and will be removed: use it
   only to unblock a release, and plan to remove it.

Verify after the switch: first paint, the layout at three widths, the 360 spin,
zoom, video, and any analytics hooks that listened for v1 events.
