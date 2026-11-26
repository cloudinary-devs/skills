# Responsive crops and the visible AI label

Read this in step 8 when a slot's aspect ratio changes at a breakpoint or with the viewport width (the `<picture>` pattern), or when the user wants a visible "AI" label on AI-generated and AI-edited images.

**When a slot's aspect ratio changes at a breakpoint**, deliver a separate crop for each ratio. Don't rely on one wide image plus CSS `object-fit: cover`: the browser crops from the center and can cut the subject out entirely. Use `<picture>` with a `<source>` per breakpoint, each with its own `c_fill,g_auto` crop, so Cloudinary keeps the subject in frame at every ratio:

```html
<picture>
  <source media="(max-width: 720px)" sizes="100vw"
    srcset="https://res.cloudinary.com/<CLOUD_NAME>/image/upload/c_fill,g_auto,w_480,h_600/f_auto/q_auto/<PUBLIC_ID> 480w,
            https://res.cloudinary.com/<CLOUD_NAME>/image/upload/c_fill,g_auto,w_960,h_1200/f_auto/q_auto/<PUBLIC_ID> 960w">
  <img src="https://res.cloudinary.com/<CLOUD_NAME>/image/upload/c_fill,g_auto,w_1440,h_600/f_auto/q_auto/<PUBLIC_ID>"
    srcset="https://res.cloudinary.com/<CLOUD_NAME>/image/upload/c_fill,g_auto,w_2880,h_1200/f_auto/q_auto/<PUBLIC_ID> 2x"
    width="1440" height="600" alt="<ALT_TEXT>">
</picture>
```

- Keep the existing `<img>` class and attributes on the `<img>` inside `<picture>`, so the site's CSS still applies. Add `width` and `height` only if the original `<img>` had them.
- Score the image for every ratio, not only the widest one. A subject on the right third of a wide hero may be the only thing a phone crop needs to keep, and `g_auto` handles that. If the subject still gets cut off, or the overlay text has nowhere calm to sit at a ratio, look for a better candidate, or extend the image with generative fill in step 6.
- If the overlay text moves at a breakpoint (for example, from the left side to the top), check that the crop for that breakpoint has a calm area where the text now sits. If it doesn't, darken behind the text more, move the text, or regenerate the image with a prompt that keeps calm space at both ratios, and flag the slot in the report if it's still weak.


## Fluid slots: match the crop to the box at every width

A breakpoint isn't the only place the ratio changes. If a slot has a fixed height and a fluid width (for example, a 600-pixel-tall hero at `width: 100%`), its box is 1440x600 at 1440 pixels wide but 1000x600 at 1000. A 1440x600 crop shown in a 1000x600 box is trimmed by `object-fit: cover` to the middle 69% of its width, and the bottom-right AI label is cut off.

Fix it with one of these, in this order of preference:

1. **Give the slot a fixed ratio in CSS** (`aspect-ratio: 12 / 5` instead of a fixed height), so the box and the crop match at every width above the breakpoint. This is a design change: the slot now gets shorter as the page narrows (a 12:5 hero is 417 pixels tall at 1000 pixels wide, not 600), and a phone ratio such as 4:5 can make it taller than before (900 pixels at 720 wide, not 480). Tell the user, and prefer option 2 when they want the original heights.
2. **Add a `<source>` per width band**, each with `media="(min-width: Npx) and (max-width: Mpx)"`, a crop whose ratio matches the box at that width (for example, `c_fill,g_auto,w_1000,h_600`), and its own label size. A `srcset` with `w` descriptors can't do this: every candidate in one `srcset` must have the same ratio. A band's crop matches the box exactly only at the width you chose it for. Between those widths the box and the crop can differ by up to about 15%, and `object-fit: cover` trims the difference. Use narrower bands, or option 1, when that matters, and check the widths in between.
3. **Give up the corner label's position** only if neither is possible: set `object-position: right bottom` so the bottom-right corner stays visible, and check that the subject isn't cut off.

Deliver each crop at about the width it's displayed (1x and 2x of that width), not at the largest width scaled down. A 1100-pixel crop shown 327 pixels wide shrinks its label to about 19 CSS pixels, which is unreadable. Size the label for each crop (see step 3 of the label section below).

With a `w`-descriptor `srcset`, the label's size on screen is its share of the crop's width times the box width, whichever candidate the browser picks. So one label ratio can't give a steady label size across a box that varies from 327 to 1100 pixels: add a `<source>` per width band (for example, up to 480, 481 to 720, and above) and set the label width for each band. Accept a range between bands, as long as the visible circle stays within about 36 to 60 CSS pixels.

If the box is small (under about 150 CSS pixels wide, such as a card squeezed into a narrow grid column), make the label no more than a third of the box width, so it doesn't cover the image, and say in the report that the label is small there.

Check the result at 3 or more widths, including ones between breakpoints: compare each `<img>`'s `clientWidth / clientHeight` with the ratio of the delivered image, which you read from the width and height of the file at `currentSrc`. If they differ by more than about 2%, the browser is cropping it again.

Two practical notes:

- **Cap each crop at the source's size.** `c_fill` upscales silently, so don't ask for a crop wider or taller than the source image. Use `c_limit` first or lower the width.
- **A `<picture>` wrapper is inline.** If the `<img>` had `height: 100%` or filled a container, add `picture { display: block; height: 100%; }` (or the equivalent) so the layout doesn't change.

## Add a visible AI label

If the user wants AI disclosure (step 2), add an "AI" label in the bottom-right corner of every generated or AI-edited image, as a [conditional overlay](https://cloudinary.com/documentation/content_provenance_and_authenticity.md?install_source=skillspack&referrer=image-picker-skill#adding_a_visible_ai_disclosure) applied at delivery. The original asset is never changed.

**1. Make sure the labels are in the product environment.** There are four versions of the label, all round "AI" badges on a transparent canvas:

| Public ID | Look | Use on |
|---|---|---|
| `ai-labels/LABEL_AI_white_transparent` | Translucent white circle, black "AI" | A calm, dark corner |
| `ai-labels/LABEL_AI_black_transparent` | Translucent black circle, white "AI" | A calm, light corner |
| `ai-labels/LABEL_AI_white` | Solid white circle, black "AI" | A busy or mid-tone corner that's darker overall |
| `ai-labels/LABEL_AI_black` | Solid black circle, white "AI" | A busy or mid-tone corner that's lighter overall |

Check for each label with the Admin API (`GET /resources/image/upload/ai-labels/<NAME>`). Upload any that are missing, from Cloudinary's copies, keeping the same names:

```bash
for n in white_transparent black_transparent white black; do
  curl -s -X POST "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload" \
    -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
    -F "file=https://res.cloudinary.com/demo/image/upload/v1792417795/docs/icons/LABEL_AI_$n.png" \
    -F "public_id=ai-labels/LABEL_AI_$n" \
    -F "overwrite=false" \
    -F "tags=image-picker"
done
```

Don't set `ai_generated` on the labels themselves.

**2. Choose a label for each crop.** View the bottom-right corner of each delivered crop: the label sits on the crop, not the original, and each breakpoint crop has a different corner. Judge the corner's brightness and how busy it is, and pick from the table. When in doubt, choose a solid label: readability matters more than subtlety. The labels don't need to match each other across a page.

**3. Size the label.** The badge is padded: its visible circle is only about 65% of the asset's width. Aim for a visible circle of about 40 to 56 CSS pixels, and at least 36 on phones, which means the label asset is about 62 to 86 CSS pixels wide (and at least 55 on phones). Scale it in pixels relative to the crop's delivered width and its displayed width: label width in pixels = target CSS pixels × (delivered width ÷ displayed width). For example, `w_64` on a crop delivered at 1x, and `w_128` on the 2x crop of the same slot. For a fluid box, see the width bands above. The badge has transparent padding built in, so it doesn't need an extra offset from the corner.

**4. Add the overlay after the crop and before `f_auto/q_auto`**, so it lands in the corner of the crop the visitor sees:

```
c_fill,g_auto,h_600,w_1440/if_ctx:!cld_ai_generated!_eq_!true!/l_ai-labels:LABEL_AI_black_transparent/c_scale,w_64/fl_layer_apply,g_south_east/if_end/f_auto/q_auto/<PUBLIC_ID>
```

- The condition shows the label only when the asset's AI-generated field is `true`, so the same URL pattern is safe to use on library images too. It depends on the asset having been saved with `ai_generated=true` (step 7).
- For an AI-generated asset that isn't marked with `ai_generated=true` (for example, one saved by another tool), drop the `if_ctx` and `if_end` components and add the overlay unconditionally.
- Add the overlay to every URL for the slot: each `srcset` width, each `<source>` crop, and CSS `background-image` URLs.
- Add the disclosure to the alt text too, so screen reader users get it: for example, "AI-generated image: two hikers on an autumn trail".
