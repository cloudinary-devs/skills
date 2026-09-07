# CldImage transformations

Use this when applying image transformations. Prefer documented `next-cloudinary` prop names over raw URL transformation parameter names.

## CldImage — transformations (the canonical prop reference)

Use **only** the prop names and shapes below (and on https://next.cloudinary.dev/cldimage/configuration). These are not the same as the underlying URL transformation params.

### Basic transformations
| Prop | Type | Example |
| --- | --- | --- |
| `crop` | `string \| object \| object[]` | `"fill"`, `{ type: 'thumb', source: true }` |
| `gravity` | `string` | `"face"`, `"auto"` |
| `aspectRatio` | `string` | `"16:9"` (requires `fill` + a crop mode that crops; omit `width`/`height`) |
| `angle` | `number \| string` | `45` |
| `background` | `string` | `"blue"`, `"rgb:0000ff"` |

### Generative AI / advanced editing
| Prop | Type | Example |
| --- | --- | --- |
| `removeBackground` | `boolean \| string` | `removeBackground` |
| `replaceBackground` | `boolean \| string \| object` | `"fish tank"` or `{ prompt: 'fish tank', seed: 3 }` |
| `fillBackground` | `boolean \| object` | `fillBackground` or `{ crop: 'pad', gravity: 'south', prompt: 'cupcakes' }` |
| `extract` | `string \| string[] \| object` | `"space jellyfish"` |
| `remove` | `string \| string[] \| object` | `"apple"` or `{ prompt: 'apple', multiple: true, removeShadow: true }` |
| `replace` | `string[] \| object` | `['apple', 'banana']` or `{ from: 'apple', to: 'banana' }` |
| `recolor` | `[string, string] \| object` | `['duck', 'blue']` |
| `restore` | `boolean` | `restore` |
| `enhance` | `boolean` | `enhance` |

### Optimization & delivery
| Prop | Type | Default | Notes |
| --- | --- | --- | --- |
| `format` | `string` | `auto` | Override only for specific cases (e.g. `"png"`) |
| `quality` | `string \| number` | `auto` | Use `"default"` to omit `q_*` (needed for `flags: ['keep_iptc']`) |
| `dpr` | `number \| string` | — | `"2.0"` or `"auto"` |
| `unoptimized` | `boolean` | — | Skips both `f_auto` and `q_auto` |
| `deliveryType` | `string` | `upload` | e.g. `"fetch"` |
| `assetType` | `string` | `image` | Use `"video"` to make a thumbnail from a video public ID |
| `flags` | `string[]` | — | e.g. `['keep_iptc']` |
| `version` | `number \| string` | — | e.g. `1234` |

### Escape hatches
| Prop | Use when… |
| --- | --- |
| `effects` | You want to chain multiple effect blocks: `effects={[{ background: 'green' }, { gradientFade: true }]}` |
| `namedTransformations` | You have a named transformation in your Cloudinary account: `namedTransformations={['my-named']}` |
| `rawTransformations` | You need a transformation not exposed as a prop: `rawTransformations={['e_blur:2000']}` |
| `preserveTransformations` | The `src` is a full Cloudinary URL with transformations to keep |
| `strictTransformations` | Account requires strict mode (only `namedTransformations` allowed) |

❌ **Do NOT**: pass `f_auto`, `q_auto`, `c_fill`, etc. via `rawTransformations` and also via the named props — pick one. Mixing causes duplicates and unpredictable URLs.

### Cropping — the `fill` prop trap

Two distinct things share the word "fill":
- **`fill={true}`** (Next Image prop) — render the image absolutely-positioned, filling the parent. No `width`/`height` required; parent must be `position: relative`. Combine with `aspectRatio` for ratio-locked containers.
- **`crop="fill"`** (Cloudinary crop mode) — Cloudinary **crops** the asset to the requested width/height.

These are independent. You can use both: `<CldImage fill crop="fill" aspectRatio="16:9" sizes="100vw" alt="..." />`.

❌ **WRONG**: Using `aspectRatio` with explicit `width`/`height` and no `fill` — `aspectRatio` won't apply because Next Image needs concrete dimensions.
✅ **CORRECT**: For `aspectRatio`, also pass `fill` and a crop mode (e.g. `"fill"`, `"thumb"`); omit `width`/`height`.

### Two-stage cropping for dynamic crop modes

Dynamic crop modes (`thumb`, `crop` with no coordinates, etc.) produce **different visual results at different sizes**, which interacts badly with responsive `srcset`. To keep results consistent across breakpoints, crop the **source** image first, then let responsive sizing resize it:

```tsx
<CldImage
  src="<Public ID>"
  width={960}
  height={960}
  crop={{ type: 'thumb', source: true }}   // source: true → applied to original asset
  sizes="100vw"
  alt=""
/>
```

You can also pin the source crop dimensions:

```tsx
crop={{ type: 'thumb', width: 1200, height: 1200, source: true }}
```

❌ **WRONG**: Using `crop="thumb"` with `sizes="100vw"` — the thumbnail content shifts as the viewport changes.
✅ **CORRECT**: Use object form with `source: true` for `thumb`-style crops.
