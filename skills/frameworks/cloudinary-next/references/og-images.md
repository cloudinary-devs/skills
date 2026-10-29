# OG images and social cards

Use this for Open Graph/social card images with `getCldOgImageUrl` in App Router or `CldOgImage` in Pages Router.


## Social media cards (OG images)

**App Router** — use `getCldOgImageUrl` inside `generateMetadata`:

```ts
// app/blog/[slug]/page.tsx
import type { Metadata } from 'next';
import { getCldOgImageUrl } from 'next-cloudinary';

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const ogUrl = getCldOgImageUrl({
    src: 'blog/cover',
    overlays: [
      {
        text: { color: 'white', fontFamily: 'Source Sans Pro', fontSize: 80, fontWeight: 'bold', text: slug },
        position: { x: 0, y: 0, gravity: 'center' },
      },
    ],
  });

  return {
    openGraph: { images: [{ url: ogUrl, width: 1200, height: 627 }] },
    twitter: { card: 'summary_large_image', images: [ogUrl] },
  };
}
```

- ✅ On Next.js 15 and 16, `params` is a Promise: `await` it as above. Reading `params.slug` directly on Next.js 16 gives `undefined`, and the OG image is generated with empty text, with no build error.
- On Next.js 14 and earlier (next-cloudinary v6 only), `params` is a plain object: see `references/v6.md`.

**Pages Router** — use `<CldOgImage>` inside the page (NOT inside `<Head>`); it injects the meta tags:

```tsx
import { CldOgImage } from 'next-cloudinary';

export default function Page() {
  return (
    <>
      <CldOgImage src="blog/cover" alt="Cover" />
      <main>…</main>
    </>
  );
}
```

- ❌ **`<CldOgImage>` does NOT work in the App Router.** Use `getCldOgImageUrl` in `generateMetadata` instead. `next-cloudinary` will warn / silently no-op otherwise.
- ✅ OG images are **1200×627** by default. Override via `width`/`height` if needed.
