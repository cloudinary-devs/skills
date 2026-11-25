# PLP patterns

Read this when building a product grid, category page or search results page.
A PLP shows many products at once, so the job is small, consistent, fast
thumbnails, not interactive media. Do not put a Product Gallery widget in each
card.

For transformation syntax and responsive-image detail, use
cloudinary-transformations. For video, use cloudinary-video.

## The card image

One delivery URL pattern for every card, with a fixed aspect ratio so the grid
does not reflow as images load:

```
https://res.cloudinary.com/your-cloud-name/image/upload/c_fill,ar_3:4,g_auto,w_400/f_auto/q_auto/products/sku-1042/sku-1042_01
```

| Part | Why |
| --- | --- |
| `c_fill,ar_3:4,w_400` | Same crop and ratio for every product, whatever the original shape |
| `g_auto` | Keeps the product in frame when the crop trims the image |
| `f_auto/q_auto` after the sizing step | Best format and quality per browser; keep them as separate path segments |
| Same public ID as the PDP's first image | The card and the gallery start from one asset, so the shopper sees continuity |

Use `c_pad` with a background colour instead of `c_fill` when cropping would
cut off the product (shoes, jewellery on white).

## Responsive `srcset`

```html
<img
  src="https://res.cloudinary.com/your-cloud-name/image/upload/c_fill,ar_3:4,g_auto,w_400/f_auto/q_auto/products/sku-1042/sku-1042_01"
  srcset="
    https://res.cloudinary.com/your-cloud-name/image/upload/c_fill,ar_3:4,g_auto,w_200/f_auto/q_auto/products/sku-1042/sku-1042_01 200w,
    https://res.cloudinary.com/your-cloud-name/image/upload/c_fill,ar_3:4,g_auto,w_400/f_auto/q_auto/products/sku-1042/sku-1042_01 400w,
    https://res.cloudinary.com/your-cloud-name/image/upload/c_fill,ar_3:4,g_auto,w_800/f_auto/q_auto/products/sku-1042/sku-1042_01 800w"
  sizes="(min-width: 1024px) 25vw, (min-width: 600px) 33vw, 50vw"
  width="400" height="533"
  alt="Trail running shoe, side view"
  loading="lazy"
/>
```

Set `sizes` to the card's real width at each breakpoint; a wrong `sizes` makes
the browser download the wrong candidate. Keep to three or four widths per
card: every extra width is another derived image to generate. Use `width` and
`height` (or CSS `aspect-ratio`) so the space is reserved.

For frameworks, generate this with the SDK rather than by hand: use
cloudinary-react or cloudinary-next.

## Loading priority

| Cards | Setting |
| --- | --- |
| First row, above the fold | `loading="eager"` and `fetchpriority="high"` on the first image only |
| Everything else | `loading="lazy"` |

Never lazy-load the image most likely to be the largest contentful paint.

## Second image on hover

Fetch a second image only when the shopper hovers or focuses the card, so it
costs nothing for the rest:

```js
card.addEventListener("pointerenter", () => {
  const img = card.querySelector("img");
  img.dataset.rest ??= img.src;
  img.src = img.dataset.hover; // second image URL, same transformation
}, { once: true });
```

Keep the second URL on the same crop and ratio. On touch screens there is no
hover: show the first image only, and let the PDP carry the rest.

## Video previews on cards

Autoplaying video in a grid is expensive. If the brand wants it:

- Preview only the card under the pointer, never the whole grid.
- Use a short, silent loop (no audio track needed), with `preload="none"` and a
  poster that is the card image, loaded when the pointer enters.
- Build the player and delivery with cloudinary-video, which decides
  progressive versus adaptive delivery per source.

## Match the PDP

| Setting | PLP | PDP widget |
| --- | --- | --- |
| Aspect ratio | `ar_3:4` | `aspectRatio: "3:4"` |
| Crop | `c_fill` or `c_pad` | `transformation: { crop: "fill" }` or `"pad"` on the asset entry |
| First asset | `..._01` | The gallery's first asset (assets sort by public ID) |

The widget accepts only a fixed list of aspect ratios (`square`, `1:1`, `3:4`, `4:3`, `5:7`, `9:16`, `16:9` and a few more), so choose the PLP ratio from that list. Then the shopper's thumbnail and the PDP's first image are the same shot.

## Validate

| Check | Expected | On failure |
| --- | --- | --- |
| Network tab on a PLP load | Each card requests one image, sized near its CSS width times the device pixel ratio, in AVIF or WebP on supporting browsers | Check `sizes` and the `f_auto` segment |
| Layout shift when images arrive | None | Add `width` and `height` or `aspect-ratio` |
| Hover image | Requested on first hover only | Move the swap into the pointer handler |
| Card image URL vs the PDP's first asset | Same public ID | Align the naming convention (media-preparation.md) |
