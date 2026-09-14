# Responsive images

Use this for `sizes`, responsive layouts, and avoiding oversized or low-resolution Cloudinary image delivery.

## Responsive images

- ✅ **Always pass `sizes`** on `<CldImage>` unless it's a known fixed-size icon. Without `sizes`, the browser defaults to `100vw` and may pick an oversized variant.
- ✅ Cloudinary automatically generates a `srcset` for the standard Next.js breakpoints — **you do not need to set `srcSet` manually**.
- ✅ Default crop mode is `limit`, which won't upscale beyond the original. To allow upscaling, use `crop="scale"` (note: may produce blurry images).

```tsx
<CldImage
  src="<Public ID>"
  width={1200}
  height={800}
  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
  alt=""
/>
```
