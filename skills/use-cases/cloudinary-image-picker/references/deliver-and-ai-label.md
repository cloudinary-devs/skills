# Responsive crops and the visible AI label

Read this in step 8 when a slot's aspect ratio changes at a breakpoint (the `<picture>` pattern), or when the user wants a visible "AI" label on AI-generated and AI-edited images.

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

- Keep the existing `<img>` class and attributes on the `<img>` inside `<picture>`, so the site's CSS still applies.
- Score the image for every ratio, not only the widest one. A subject on the right third of a wide hero may be the only thing a phone crop needs to keep, and `g_auto` handles that. If the subject still gets cut off, or the overlay text has nowhere calm to sit at a ratio, look for a better candidate, or extend the image with generative fill in step 6.
- If the overlay text moves at a breakpoint (for example, from the left side to the top), check that the crop for that breakpoint has a calm area where the text now sits.


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

**3. Size the label.** Aim for a label about 48 to 64 CSS pixels across on screen. Scale it in pixels relative to the crop's delivered width: for example, `w_64` on a crop delivered at 1x, and `w_128` on the 2x crop of the same slot. The badge has transparent padding built in, so it doesn't need an extra offset from the corner.

**4. Add the overlay after the crop and before `f_auto/q_auto`**, so it lands in the corner of the crop the visitor sees:

```
c_fill,g_auto,h_600,w_1440/if_ctx:!cld_ai_generated!_eq_!true!/l_ai-labels:LABEL_AI_black_transparent/c_scale,w_64/fl_layer_apply,g_south_east/if_end/f_auto/q_auto/<PUBLIC_ID>
```

- The condition shows the label only when the asset's AI-generated field is `true`, so the same URL pattern is safe to use on library images too. It depends on the asset having been saved with `ai_generated=true` (step 7).
- For an AI-generated asset that isn't marked with `ai_generated=true` (for example, one saved by another tool), drop the `if_ctx` and `if_end` components and add the overlay unconditionally.
- Add the overlay to every URL for the slot: each `srcset` width, each `<source>` crop, and CSS `background-image` URLs.
- Add the disclosure to the alt text too, so screen reader users get it: for example, "AI-generated image: two hikers on an autumn trail".
