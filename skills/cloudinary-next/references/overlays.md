# Image overlays

Use this when building image overlays, text overlays, badges, labels, or watermark-style transformations.

## Image overlays — the `overlays` prop shape

```tsx
<CldImage
  src="<Public ID>"
  width={960}
  height={600}
  sizes="100vw"
  overlays={[
    {
      publicId: 'logo',                 // image overlay
      position: { x: 50, y: 50, gravity: 'south_east' },
      effects: [{ crop: 'fill', gravity: 'auto', width: 200, height: 200 }],
      appliedEffects: [{ multiply: true }],   // blend modes go here
    },
  ]}
  alt=""
/>;
```

```tsx
// Text overlay
overlays={[
  {
    position: { x: 0, y: 80, gravity: 'south' },
    text: {
      color: 'white',
      fontFamily: 'Source Sans Pro',
      fontSize: 80,
      fontWeight: 'bold',
      text: 'Hello',
    },
  },
]}
```

Rules for the overlay shape:
- ✅ **Image overlay** → use `publicId` (just the ID, no URL, no extension).
- ✅ **Text overlay** → use a `text` object (with `text` inside it being the actual string). Do **not** put text under `publicId`.
- ✅ **Position** → object with `x`, `y`, `gravity` (and optional `angle`). `gravity` strings use **underscores**: `"south_east"`, `"north_west"`, `"center"` — not camelCase.
- ✅ **Effects** (sizing, crop, color, etc.) go in `effects: [...]`. **Blend modes** (`multiply`, `screen`, `overlay`, etc.) go in `appliedEffects: [...]`.
- ✅ For relative sizing, set widths/heights as fractional strings (`"0.5"`) and add `flags: ['relative']`.
- ❌ Don't try to use the `@cloudinary/url-gen` overlay builder API (`source(text(...))`, `compass(...)`, etc.) — that's the React/Vite SDK. In `next-cloudinary` everything is a plain prop object.

For a single text on an image, the convenience prop also works:

```tsx
<CldImage src="..." width={960} height={600} text="Hello" alt="" />
```
