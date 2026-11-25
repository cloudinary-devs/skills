# Preview the widget on the customer's own page

Read this when the user wants to see the Product Gallery widget inside their
real store page before changing production code. The result is a local,
throwaway copy of one product page with the widget swapped in. It is a preview,
not an integration: when it looks right, write the real integration from
pdp-integration.md.

## Rules

- **The user saves the page, you do not scrape it.** Store CDNs often block
  scripted clients. Never spoof a user agent or headers to get around bot
  protection. Ask the user to open one product page in their own browser (pick
  a product that has images, a video and a 360 spin if they exist) and use
  **Save Page As, Webpage, Complete**. Use the saved HTML for the preview.
- **Nothing from the copy may reach the store's systems.** The saved page still
  runs the store's analytics, tag manager, A/B, fraud and session-replay code,
  which would record `localhost` sessions in their production tools. The
  preview script enforces a Content Security Policy that allows only itself,
  Cloudinary delivery, the widget CDN and hosts you pass with `--allow`. Do not
  remove that policy to make something work.
- **Work outside the store's repository and keep the copy out of version
  control.** Put it in a scratch folder.
- **Say it is a preview.** Report what was swapped and what was not.

## Steps

1. Get from the user: the saved HTML file, the cloud name, the product's tags or
   public IDs (see media-preparation.md), and the store's image CDN hostname if
   it uses a custom domain or CNAME.
2. Find the gallery's wrapper element in the saved page (an id or class
   selector). Open the file and search for the gallery's markup.
3. **Measure their gallery before you configure anything.** Do not eyeball it
   or accept the widget's defaults: the default layout (a vertical thumbnail
   bar beside one image) rarely matches a store's own. Open the page at
   desktop width (1440) and phone width (375), in the saved copy
   (`?original` once the script runs) or on the live page in the browser
   pane, and record with JavaScript (`getBoundingClientRect`, computed styles):
   - the **layout switch**: the viewport width where the gallery changes.
     Reload at each width you test, because many pages choose their layout at
     load and do not reflow on resize. Test a few widths (for example 900, 960,
     1024, 1200) to bracket it.
   - **columns, gap and image size** on desktop, and whether thumbnails, dots
     or arrows exist at all.
   - **what each layout shows**: all images at once, or one at a time.
   - the **zoom behaviour** (click for fullscreen, hover, none).
   - the **aspect ratio** of the main image.

   Then map each measurement to a widget setting (see pdp-widget.md):
   `displayProps` (`mode`, `columns`, `spacing`), `carouselStyle` (`none`,
   `thumbnails`, `indicators`), `zoomProps`, `aspectRatio`. The script takes
   the common ones as flags (`--aspect`, `--desktop-min-width`, `--columns`,
   `--spacing`); for anything else, edit the `galleryWidget({...})` call in the
   script's `swapScript`. The widget's own `viewportBreakpoints` follow the
   widget's width, not the page's, so use `--desktop-min-width` when the store
   switches layout at a viewport width.
4. Get the current widget version from the changelog and pin it.
5. Run the preview:

```bash
node scripts/preview-pgw.mjs \
  --page ./saved/product.html \
  --selector "#product-gallery" \
  --cloud your-cloud-name \
  --version <pinned version> \
  --tag sku-1042 --video-tag sku-1042 --spin-tag sku-1042-360 \
  --aspect 3:4 \
  --desktop-min-width 960 --columns 2 --spacing 3 \
  --allow https://images.example-store.com
```

No tags yet? List public IDs instead (repeat `--public-id`; read them from the
image URLs on the saved page). On a custom image hostname (CNAME), add
`--secure-distribution images.example-store.com`: the script sets `secure`,
`privateCdn` and `secureDistribution` for you and allows that host in the
policy. Check first that the host serves standard paths, for example
`curl -s -o /dev/null -w '%{http_code}' https://images.example-store.com/image/upload/w_400/<public id>`
returns `200`.

The widget sorts assets by public ID. If the store's public IDs are hashes, the
order will look random: add `--keep-order` to show the assets in the order you
listed them. That sets the `sort: "none"` parameter, which the reference marks
deprecated in favour of `sortProps`, whose other sources are contextual or
structured metadata. For a real integration, store a sort key in metadata and
use `sortProps`.

6. Open `http://127.0.0.1:4173/` for the swapped page and
   `http://127.0.0.1:4173/?original` for the page as saved, side by side at a
   desktop width and a phone width.

Stop the server by its process ID when finished. Do not kill processes by name
pattern, since that can hit other work.

## Match it, then check it

Compare the preview with `?original` at the same widths, using the same
measurements as step 3, not screenshots alone: the position and size of the
first few images, the number of columns, and whether thumbnails or dots appear.
Fix a difference by changing the config, then reload. Report the remaining
differences as numbers (for example "cells 468 px against their 473 px, inset
3 px"), not as "looks the same".

## Check the preview

| Check | Expected | On failure |
| --- | --- | --- |
| `document.documentElement.getAttribute("data-pgw-preview")` in the console | `rendered` | The selector did not match (console error "selector not found"), or the widget script failed to load |
| Resource Timing for hosts other than the preview, Cloudinary and your `--allow` list | Only entries with `responseStart` of 0 (blocked) | Add the host to `--allow` only if it is the store's own image or font CDN, never an analytics or tag host |
| Console messages starting `[preview] blocked` | Only analytics, tag manager and similar hosts | A blocked image CDN or font host shows up here: allow it if it is the store's own |
| Layout at each width you measured | Same columns, image size and controls as `?original`, within a few pixels | Re-measure, change `displayProps`, `carouselStyle` or `--desktop-min-width`, reload |
| The gallery after load | Shows the product's images, then video and spin | "No media assets available" means the tag is wrong or the Resource list restriction is on (SKILL.md prerequisites) |
| Product images load from the store's CDN, not `localhost` | Image URLs are on the delivery host | Set `secure`, `privateCdn` and `secureDistribution` in the widget config for a custom hostname |
| The store's own scripts re-rendered the gallery over the preview | Preview still visible | Their framework re-hydrated the wrapper: pick a more specific child selector, or remove their gallery script from the saved copy |

The widget's own startup analytics request to Cloudinary is blocked by the
policy, which does not affect rendering.

## What to report

- Which page and which product were previewed, and the widget version.
- Screenshots or a description of both the original and the swapped page at two
  widths, and the specific differences (thumbnails, zoom, video, spin).
- The result of the network-lockdown check above.
- What the preview does not show: the store's real server rendering, its
  tracking hooks, its add-to-cart interplay, and real-user performance. Measure
  performance on the real integration, not on this copy.

Do not make performance claims from the preview. If the user wants a
before-and-after measurement, run it on the integrated page, with the same
network conditions for both variants, several runs each, and report
differences within run-to-run spread as unchanged.
