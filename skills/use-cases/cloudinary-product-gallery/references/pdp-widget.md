# PDP widget configuration

Read this when configuring how the Product Gallery looks and behaves. Source of
truth: the
[reference](https://cloudinary.com/documentation/product_gallery_reference.md?install_source=skillspack&referrer=gallery-skill).
Verify any parameter not shown here against it before using it.

All snippets use the script-embed API. The npm `<Gallery>` takes the same
configuration through `resolveConfig`.

## Layout

| Goal | Config |
| --- | --- |
| Thumbnails left of the viewer on desktop, below on phones | The default: one built-in breakpoint at 520 px |
| Three layouts (wide, narrow, tiny) | `viewportBreakpoints`, see below |
| All assets stacked in a scroll column (editorial layout) | `displayProps: { mode: "expanded", columns: 1, spacing: 8 }` |
| Two-column grid of all assets | `displayProps: { mode: "expanded", columns: 2 }` |
| Dots instead of thumbnails | `carouselStyle: "indicators"` |
| Square, portrait or landscape viewer | `aspectRatio`: `square` (default), `1:1`, `3:4`, `4:3`, `5:7`, `9:16`, `16:9` and a few more |

`expanded` mode is desktop only: phones always use `classic`. Keep the viewer
shorter than the viewport, since height comes from container width and
`aspectRatio`. Set `topOffset` when a sticky header covers the top.

```js
viewportBreakpoints: [
  { breakpoint: 600, carouselStyle: "thumbnails", carouselLocation: "bottom" },
  { breakpoint: 300, carouselStyle: "indicators", carouselLocation: "bottom", navigation: "always" }
]
```

The breakpoint is matched against the **widget's** width, and a breakpoint's
options apply at that width or below. The widget fills its container: size the
container with CSS (`max-width`, a grid or flex cell). There are no `width` or
`height` options.

## Images and the default transformation

Images and spin frames get `crop: "pad"`, `background: "#FFFFFF"`,
`fetch_format: "auto"`, `quality: "auto"` and `gravity: "auto"` by default. Only
`fill` and `pad` are supported.

| Goal | Config |
| --- | --- |
| Fill the viewer, no white bars | `transformation: { crop: "fill" }` on the asset entry |
| Keep the whole product visible on a coloured background | `transformation: { crop: "pad", background: "#F4F1EC" }` |
| Add a watermark | `transformation: { transformation: [{ overlay: "brand_logo", gravity: "south_east" }] }` |
| Run a transformation before the defaults (for example background removal) | `transformation: { prefixed: false, effect: "background_removal" }` |
| Different thumbnail crop | `thumbnailTransformation` on the asset entry |

Transformation objects use the JavaScript (legacy) syntax, not URL strings.

Each distinct width generates a derived asset on first request. To use fewer
transformations at the cost of more bytes: raise `imageBreakpoint` (default
100), fix the container width, or turn off `placeholderImage`.

## Zoom

```js
zoomProps: { type: "popup", trigger: "click", steps: 3, stepLimit: true }
```

`type`: `inline` (default), `flyout` or `popup`. Multi-step zoom works only
with `popup`; use it with high-resolution originals or zoomed views look soft.
Hover zoom (desktop): `trigger: "hover"`. Turn zoom off with `zoom: false`.

## Video

| Goal | Config |
| --- | --- |
| Muted autoplay loop (default) | `videoProps: { controls: "none" }` |
| Play and pause button only | `videoProps: { controls: "play", autoplay: false }` |
| Cloudinary Video Player | `videoProps: { playerType: "cloudinary" }` plus any Video Player option |
| Longer than 30 s | The default video transformation is `duration: 30`; override `transformation` on the video entry |

In classic mode the first video starts muted whatever `sound` says, and in
expanded mode all videos start muted, because of browser autoplay policy. For
a Video Player strategy beyond the gallery (adaptive streaming, captions), use
cloudinary-video.

## 360 spin sets

```js
spinProps: { animate: "start", spinDirection: "counter-clockwise", showTip: "touch" }
```

Frames come from every image with the tag, ordered by public ID, so name them
to sort (`_01` … `_36`). `animate` controls auto-spin; `disableZoom: true`
turns zoom off for spins. Tip text is `tipText` (pointer) and `tipTouchText`
(touch).

## 3D models and AR

```js
ar3dProps: { showAR: true, autoRotate: true, shadows: true, showZoomButtons: true }
```

GLB only. Listen to `3dmodelloaded` to hide a loading state, and `onArClick`
with `useCustomArModal: true` to supply your own AR dialog (the event data has
`qrUrl` and `qrSvg`). The npm package bundles three.js for this, which grows the
main bundle even for image-only galleries; code-split the gallery component.

## Alt text and accessibility

Replace the default "Gallery asset n of m" with real alt text:

```js
accessibilityProps: { mediaAltSource: "contextual", mediaAltId: "alt" }
```

`contextual` reads a contextual metadata key (the empty string uses the default
`alt` key on every asset); `metadata` reads a structured metadata field by its
`external_id`. Recommended for the most accessible setup: `displayProps.mode`
`expanded`, `zoomProps.type` `popup`, `videoProps.controls` `play`. The widget
supports Tab, Enter (view or zoom), Esc (exit zoom) and Space (play or pause)
in v2.0. A v2.1 pre-release changes the keyboard map and adds video captions,
audio description, translated labels and spin or 3D rotate buttons, and changes
the widget's internal markup (so recheck any CSS overrides). Read the
[changelog](https://cloudinary.com/documentation/product_gallery_changelog.md?install_source=skillspack&referrer=gallery-skill)
for the version you pin before relying on keyboard behaviour or markup.

## Theming and CSS

Prefer a config parameter (`themeProps`, `thumbnailProps`, `navigationButtonProps`
and others in the reference). For the rest, inspect the widget in devtools:
everything lives under a `.pgw` root with readable class names.

```css
.pgw .thumbnailItem { border-radius: 12px; }
.pgw .thumbnailItem--selected { --thumb-sel-border: 3px solid #0a141e; }
.pgw.galleryWrapper { --gw-loader-color: #0a141e !important; } /* config-derived: needs !important */
```

Selectors must include `.pgw`. Variables the widget derives from config are
written inline on the root, so setting them on an ancestor loses. Class names
can change between releases, so pin the version and recheck overrides when
upgrading.

## Events and analytics

```js
gallery.on("thumbclick", (d) => track("gallery_thumb", d.label));
gallery.on("videoprogress", (d) => track("gallery_video", d.label, d.progress));
```

Events: `thumbclick`, `thumbnext`, `thumbprev`, `viewernext`, `viewerprev`,
`zoomin`, `zoomout`, `spinclick`, `videostart`, `videopause`, `videoprogress`
(25, 50, 75 and 100 %), `3dmodelloaded`, `onArClick`, `onQrReady`,
`mouseenter`, `mouseleave`, `indicatorclick`. Each carries `label` (the public
ID) and `timestamp`. With Google Tag Manager on the page, `analytics: true`
pushes the events to `dataLayer`. The React `<Gallery>` component does not
expose events: use the script embed if you need them.

## Instance methods (script embed)

`render()`, `update(options)`, `destroy()`, `on()`, `setItem(i)`, `nextItem()`,
`prevItem()`, `getActiveItem()`, `getActiveIndex()`. Call `destroy()` before
removing the container from the DOM, or the widget leaks memory.
