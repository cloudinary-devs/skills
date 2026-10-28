---
name: cloudinary-image-picker
description: "End-to-end recipe for choosing the right images for a website from a Cloudinary product environment, and generating new ones when nothing fits. Use when building a website or page that needs images, filling empty or placeholder image slots, replacing or refreshing existing site images (for example, a seasonal hero banner), or when the user asks to find, pick, match, or generate images for their site from Cloudinary."
license: MIT
metadata:
  author: cloudinary
  version: '0.3.0'
  internal: true
---

# Cloudinary Image Picker

Picks the best image for every image slot on a website from the assets in a Cloudinary product environment. It reads the page to understand what each slot needs, finds candidates with the best search method the product environment supports, looks at and scores them, adapts near-misses with generative AI edits, and generates a new image with the Image Generation API when no existing asset is close enough. Every chosen or generated image is delivered with transformations sized for its slot, then checked on the rendered page before handing back to the user.

## When to Use

- The user asks you to build a website or page, and the design includes images (hero banners, product cards, team photos, blog headers, backgrounds)
- An existing site has empty image slots, placeholder images (for example, `placehold.co`, `picsum.photos`, `via.placeholder.com`, gray boxes), or broken image links
- The user wants to replace or refresh existing images, for example, swapping a summer hero banner for an autumn one
- The user asks to find, match, or generate images for their site from their Cloudinary media library

Don't use this skill for logos, icons, or brand marks: use the user's own files. For transformation syntax details, use cloudinary-transformations. For anything outside this skill's scope, use cloudinary-docs.

## Prerequisites

- **Credentials**: `CLOUDINARY_URL` (`cloudinary://<API_KEY>:<API_SECRET>@<CLOUD_NAME>`), or `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, and `CLOUDINARY_API_SECRET`. Never print the secret or put it in client-side code.
- **Vision**: you must be able to view images (fetch an image URL and see its contents). Scoring depends on it.
- **Image Generation add-on** must be registered for the product environment to generate images. If it isn't, report the gap instead of generating.

Optional, used when available (see [Choose a discovery method](#choose-a-discovery-method)):

- **Visual Search**: Enterprise feature. The best way to search a large library by what images look like.
- **Cloudinary AI Content Analysis add-on**: auto-tagging and captioning, which make the Search API useful for finding images by content. Free tier available.
- **Cloudinary AI Vision add-on**: answers questions about an image, used to check shortlisted candidates. Free tier available.

Every API call in this skill runs server-side (shell, script, or MCP tool). Only delivery URLs go into the site.

## Workflow

Copy this checklist and track progress:

```
- [ ] 1. Inventory image slots
- [ ] 2. Confirm scope and write permission with the user
- [ ] 3. Write search queries per slot
- [ ] 4. Search and collect candidates
- [ ] 5. Score candidates and choose
- [ ] 6. Adapt near-miss images
- [ ] 7. Generate images for unfilled slots
- [ ] 8. Deliver with slot-sized transformations
- [ ] 9. Self-check the rendered page
- [ ] 10. Report to the user
```

### 1. Inventory image slots

Before searching, build a slot list from the page code, the design, or your own plan for the site. For each slot, record:

| Field | How to find it |
|---|---|
| `slot_id` | A short name, for example `home-hero`, `product-card-3` |
| Purpose | What the image does: sets a mood, shows a product, shows people, illustrates an article |
| Context | The heading, body text, and calls to action closest to the slot. This is the main signal for what the image should show. |
| Site context | Brand, audience, tone, color palette, season or campaign |
| Display size | Rendered width and height in CSS pixels at the largest breakpoint, from the CSS, the component props, or the layout |
| Aspect ratio | From the display size, or from `aspect-ratio`, `object-fit`, or fixed width and height. Check the media queries too: if the ratio changes at a breakpoint (for example, a 12:5 hero that becomes 4:5 on phones), record each ratio and its breakpoint. |
| Minimum source size | Display size multiplied by 2 for high-density screens. For example, a 1440x600 hero needs a source of at least 2880x1200, or at least 1920 wide as a floor. |
| Overlay | Whether text or buttons sit on top of the image, and where. The image needs a calm, low-detail area there. |
| Current image | The existing URL, if any, and why it's being replaced |

Read the copy closely and connect the dots. A section titled "Fresh from our kitchen" above a bakery menu needs warm, close-up food photography, not a generic "food" image. A "Meet the team" grid needs consistent head-and-shoulders portraits, not mixed group shots.

### 2. Confirm scope and permissions with the user

Ask one short, batched question before you search. Skip a scope or style question when the user already answered it, but **always ask for write permission** unless the user already gave it: editing and generating create new assets in their product environment and use add-on quota, and without explicit permission your agent's safety checks may block the upload at the end of the run, after the quota is already spent.

- **Scope**: limit the search to a folder, tag, or collection? (for example, only assets tagged `approved` or `CC0`)
- **Style**: photography or illustration, people or no people, color mood?
- **Write permission**: may you edit existing images or generate new ones when nothing in the library fits, and save the results to the product environment as new assets? Mention the quota cost (see [Check the generation budget](#check-the-generation-budget)).

If the user says to go ahead without answering, search all public images, and edit or generate where needed. If they decline write permission, use library images only and flag any slots that don't reach the acceptance score.

### 3. Write search queries per slot

Visual Search matches what an image *looks like*, so describe the picture, not the marketing message.

- Use concrete nouns, setting, lighting, and composition: "close-up of a croissant on a wooden table, warm morning light", not "delicious bakery goodness"
- Include the orientation or framing the slot needs: "wide landscape view", "portrait of one person, head and shoulders", "product on a plain white background"
- Mention empty space when there's a text overlay: "with empty sky on the left"
- Write 2 or 3 query variants per slot, from specific to broad. The broad variant catches assets the specific one misses.

Example for a `home-hero` slot above the heading "Autumn collection is here":

1. `woman walking through a park with orange autumn leaves, wide shot, soft light`
2. `autumn leaves forest path, wide landscape`
3. `autumn fashion outdoor`

### 4. Search and collect candidates

#### Choose a discovery method

Pick the first method that works for the product environment and the user's scope, and note which one you used for the report:

| Method | Use when | Finds images by |
|---|---|---|
| A. Visual Search | A test call succeeds (Enterprise feature) | What they look like |
| B. Browse the scope | The scope (folder, tag, or whole library) holds about 100 images or fewer | Your own viewing of every image |
| C. Search API on tags and captions | The scope is larger, and assets have auto-tags or captions | Content keywords |
| D. Search API on existing tags and names | None of the above | Whatever keywords the uploader added |

To test for Visual Search, run one visual search call with a broad query that should match something in any library, such as `outdoor` or `person`. Treat it as unavailable if the call returns an error saying the feature isn't enabled, or if it returns no results: the feature may be off, or the images may not be indexed yet. Move on without mentioning it again. To size the scope, run a Search API call with the scope expression and read `total_count`.

#### A. Visual Search

Run a [visual search](https://cloudinary.com/documentation/admin_api.md?install_source=skillspack&referrer=image-picker-skill#visual_search_for_resources) for each query variant:

```bash
curl -s -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/resources/visual_search" \
  --data-urlencode "text=autumn leaves forest path, wide landscape" -G
```

```javascript
const res = await cloudinary.api.visual_search({ text: 'autumn leaves forest path, wide landscape' });
```

Results come back ordered by relevance. Then:

- **Apply the user's scope yourself.** Visual search takes only `text`, `image_url`, or `image_asset_id`, so filter the results on `tags`, `asset_folder`, or other returned fields after the call. Keep only `resource_type: image` and `access_mode: public`.
- **Page with `next_cursor`** if fewer than 5 candidates survive the filter, up to 3 pages per query.
- **Search by example** once you've found one good match: pass its `asset_id` as `image_asset_id` to find visually similar images. This keeps a page consistent, for example, all product cards with the same background style.

#### B. Browse the scope

When the scope is small, list it once with the [Search API](https://cloudinary.com/documentation/search_method.md?install_source=skillspack&referrer=image-picker-skill) and view every image yourself:

```bash
curl -s -X POST "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/resources/search" \
  -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"expression": "resource_type:image AND tags:CC0", "max_results": 100, "with_field": ["tags", "context"]}'
```

- Drop images that are too small for every slot (`width` and `height` below the smallest slot's display size) before viewing.
- View the remaining images as **contact sheets**: download small thumbnails (`c_limit,w_300/f_jpg/q_auto`) and tile 12 to 20 of them into one grid image, each labeled with its public ID and pixel size (for example, with ImageMagick `montage` or Pillow). Viewing a few sheets is much faster than viewing each image on its own.
- Write a one-line description of each image from the sheets. Reuse these descriptions for every slot instead of viewing the images again. View a shortlisted image on its own, at a larger size, before you score it.
- Match descriptions against each slot's needs to build its shortlist.

#### C. Search API on tags and captions

Turn each query variant into keywords: the main subject, setting, and season (`autumn`, `forest`, `path`). Search with tokenized, prefix matching on tags and captions, combined with the user's scope:

```
resource_type:image AND tags:CC0 AND (tags:autumn* OR context.caption:autumn* OR tags:forest*)
```

Assets get content tags and captions from the [Cloudinary AI Content Analysis add-on](https://cloudinary.com/documentation/cloudinary_ai_content_analysis_automatic_tagging.md?install_source=skillspack&referrer=image-picker-skill). If the scope has no auto-tags or captions, offer the user a one-time pass. **Ask first**: it writes tags to their assets and uses add-on quota. For each asset, call the Admin API `update` method:

- `detection=lvis` and `auto_tagging=0.6` to add tags for detected objects with 60% confidence or more
- `detection=captioning` to get a one-sentence caption. The caption comes back in `info.detection.captioning.data.caption`. Save it to the asset's `caption` context field so the Search API can match it.

#### D. Search API on existing tags and names

Search the keywords from method C against `tags`, `public_id`, `display_name`, and `context`. Results depend on how well uploaders labeled their assets, so expect weak results and more generation.

#### For every method

- **Merge and deduplicate** candidates across query variants by `asset_id`. Keep the best rank each one reached.
- Keep the top 5 to 8 candidates per slot for scoring.

### 5. Score candidates and choose

Read each candidate's `width`, `height`, `tags`, and `context` from the search results. Then **look at the image itself**: fetch a small preview such as `https://res.cloudinary.com/<CLOUD_NAME>/image/upload/c_limit,w_600/f_jpg/q_auto/<PUBLIC_ID>` and view it. Never choose from the public ID, filename, or tags alone: they're often wrong or vague.

Score every candidate against the slot:

| Criterion | Weight | 0 | 1 | 2 |
|---|---|---|---|---|
| Subject match | 3 | Wrong subject | Related but generic | Shows exactly what the copy describes |
| Resolution | 2 | Below the display size | Between display size and the minimum source size | Meets the minimum source size |
| Crop fit | 2 | Key subject would be cut off at the slot's aspect ratio | Fits with a tight crop | Fits naturally, with room to spare |
| Composition | 1 | Busy or cluttered, or no calm area where an overlay needs one | Acceptable | Clear focal point, overlay area is clean |
| Tone and consistency | 1 | Clashes with the site's mood, palette, or the other chosen images | Neutral | Matches the mood and the other images on the page |
| Clean | 1 | Visible watermark, unrelated text, or third-party logos | Minor distractions | None |

Maximum score: 20. Rules:

- **Hard fails**: a 0 on subject match or resolution disqualifies the candidate, whatever its total.
- **Accept** the highest scorer if it reaches **14 or more**.
- **Don't reuse** one asset in two slots on the same page, unless the design intends it.
- **Check crop fit** by comparing aspect ratios: a 4:3 source in a 21:9 hero loses most of its height. `g_auto` helps, but can't add pixels that aren't there.
- **Third-party logos and brand names** on products (for example, a brand logo on sunglasses) score 0 on Clean for a store or brand site, because they misrepresent what's for sale.
- If no candidate reaches 14, but one scores 10 or more and an edit could fix what it's missing, the slot goes to step 6. Otherwise, it goes to step 7.
- **An accepted image with a fixable flaw also goes to step 6**, when you have write permission. For example: a visible logo (remove it), or a product shot whose background doesn't match the other product cards (replace the background). Passing the acceptance score doesn't mean the image can't be improved.

**Optional second opinion**: if the [Cloudinary AI Vision add-on](https://cloudinary.com/documentation/cloudinary_ai_vision_addon.md?install_source=skillspack&referrer=image-picker-skill) is available, use it to check slot-specific details on the top 2 or 3 candidates, for example, whether there's empty space for a headline. Ask yes-or-no questions with `ai_vision_general`:

```bash
curl -s -X POST "https://api.cloudinary.com/v2/analysis/$CLOUDINARY_CLOUD_NAME/analyze/ai_vision_general" \
  -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "source": { "asset_id": "<ASSET_ID>" },
    "prompts": ["Is the left third of this image plain enough to place a white headline over it? Answer yes or no, then give one reason."]
  }'
```

Treat the answer as one input to your score, not a replacement for viewing the image.

Record the score and a one-line reason for each choice. You need them for the report.

### 6. Adapt near-miss images

Editing an existing image is often better than generating a new one: it keeps a real photo, matches the rest of the library, and costs less. Consider it for:

- A near-miss candidate from step 5 that has the right subject but one fixable problem
- An accepted candidate with a fixable flaw, such as a logo, or a background that doesn't match the images next to it
- The slot's current image, when you're replacing or refreshing it. For example, a summer hero can become an autumn one by changing its background or season, while keeping the same people and layout.

Match the problem to the fix:

| Problem | Fix | Example |
|---|---|---|
| Wrong aspect ratio, and cropping would cut the subject | Generative fill extends the image | `b_gen_fill,c_pad,ar_21:9,w_2000` |
| Unwanted object, person, or text | Generative remove | `e_gen_remove:prompt_(text;person)` |
| One object is wrong for the page | Generative replace | `e_gen_replace:from_coffee%20cup;to_pumpkin%20spice%20latte` |
| Wrong setting or season behind the subject | Generative background replace | `e_gen_background_replace:prompt_autumn%20park%20with%20orange%20leaves` |
| A product or item is the wrong color | Generative recolor | `e_gen_recolor:prompt_jacket;to-color_8B4513` |
| Low resolution or compression artifacts | Upscale, or generative restore | `e_upscale`, `e_gen_restore` |
| Several changes, or a restyle | The `image_to_image` endpoint, with the asset as the reference image | See below |

Prompts inside a transformation URL must be URL-encoded (for example, spaces as `%20`). Use cloudinary-transformations for the exact syntax and limits of each [generative AI transformation](https://cloudinary.com/documentation/generative_ai_transformations.md?install_source=skillspack&referrer=image-picker-skill).

For several changes or a restyle, use `image_to_image` with a temporary target, so you can check the result first:

```bash
curl -s -X POST "https://api.cloudinary.com/v2/generate/$CLOUDINARY_CLOUD_NAME/image_to_image" \
  -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Keep the people and composition of [1], change the season to autumn with orange leaves and warm light",
    "reference_images": [{ "source_type": "managed_asset", "asset_id": "<ASSET_ID>" }],
    "model": { "mode": "auto" },
    "target": { "target_type": "temporary" }
  }'
```

Then:

1. **Check the result**: open the transformation URL (the first request can take a while, since the edit runs then) or the `image_to_image` preview URL, and view it. Score it with the step 5 rubric. If it scores under 14, try a different fix or a clearer prompt, up to 2 attempts, then go to step 7.
2. **Save the approved result as a new asset**, using the same upload call as in step 7, with `tags=ai-edited,image-picker`. Don't overwrite the original. Saving also means the responsive sizes in step 8 resize one fixed image, instead of running the generative edit again for every width.

### 7. Generate images for unfilled slots

Use the [Image Generation API](https://cloudinary.com/documentation/image_generation_addon.md?install_source=skillspack&referrer=image-picker-skill) when no existing asset fits. If the user said not to generate, leave the best candidate in place and flag the slot in the report.

#### Check the generation budget

Every `text_to_image` and `image_to_image` call uses Image Generation quota, and a free plan's allotment runs out after a handful of images. Every response reports the quota in `limits.addons_quota` (`used_by_request`, `remaining`, `limit`).

- After the first call, work out how many more images the remaining quota allows, and plan around it: generate the slots that matter most first (hero, then products, then decorative backgrounds).
- Count retries against the budget. If the budget can't cover every slot plus a retry each, tell the user which slots you'll leave as library near-misses, before you spend it.
- Report the quota used and remaining at the end.

**Write the prompt** from the slot inventory, not from the search query. A good prompt states:

1. Subject and action: "a barista pouring latte art into a ceramic cup"
2. Setting and props: "on a marble counter in a small, sunlit cafe"
3. Style and medium: "editorial photography, shallow depth of field"; or "flat vector illustration" for illustrated sites
4. Lighting and palette, matched to the site: "warm golden morning light, cream and brown tones"
5. Composition for the slot: "wide 16:9 framing, subject on the right third, empty soft-focus space on the left for a headline"
6. Exclusions: "no text, no logos, no watermarks"

Match the style of the images you already chose for the page, so the generated image doesn't stand out.

**Generate a temporary preview first** so you can inspect it before saving anything:

```bash
curl -s -X POST "https://api.cloudinary.com/v2/generate/$CLOUDINARY_CLOUD_NAME/text_to_image" \
  -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "<PROMPT>",
    "model": { "mode": "auto", "preference": "quality" },
    "image_size": { "aspect_ratio": "16:9", "resolution": "2K" },
    "target": { "target_type": "temporary" }
  }'
```

- Set `aspect_ratio` to the slot's ratio, or the nearest supported one, and choose a `resolution` that meets the minimum source size. `2K` is about 2048 pixels on the long side, which is enough for slots up to about 1000 CSS pixels wide at 2x.
- For wider slots, such as a full-width hero, request the highest resolution the API supports. If the result is still under the minimum source size, upscale the approved image with `e_upscale` before saving it, or save it as is and flag the slot in the report.
- For text-heavy or vector needs, `mode: auto` picks a suitable model. Only pin a `model.id` if the user asks.
- If an existing image is close to what you need, adapt it in step 6 instead of generating from scratch.

**Verify the preview** by viewing `data.assets[0].storage.secure_url`. Score it with the step 5 rubric. If it scores under 14, rewrite the prompt to fix what's wrong (name the specific problem, for example "the subject is centered, move it to the right third") and try again. Stop after 3 attempts per slot, keep the best result, and flag the slot in the report.

**Save the approved image** by uploading the preview URL before it expires, so you keep exactly the image you checked:

```bash
curl -s -X POST "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload" \
  -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  -F "file=<PREVIEW_SECURE_URL>" \
  -F "public_id=<SITE_NAME>/<SLOT_ID>" \
  -F "tags=ai-generated,image-picker" \
  -F "context=alt=<ALT_TEXT>|prompt=<PROMPT>"
```

### 8. Deliver with slot-sized transformations

Build each delivery URL with cloudinary-transformations. The defaults for a slot are:

- Crop to the slot: `c_fill,g_auto,h_<H>,w_<W>`, with `ar_<RATIO>` for fluid layouts
- Always optimize: `f_auto/q_auto` as the final components
- Responsive images: a `srcset` at 1x and 2x the display width, or `w_auto` where the site uses Client Hints
- Overlay text: if contrast is weak, darken behind the text with `e_brightness:-20` or a gradient overlay rather than choosing a busier image

Example for a 1440x600 hero: `https://res.cloudinary.com/<CLOUD_NAME>/image/upload/c_fill,g_auto,h_600,w_1440/f_auto/q_auto/<PUBLIC_ID>`

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

Write meaningful `alt` text for every image, based on what the image actually shows and why it's on the page. Use an empty `alt=""` only for purely decorative images.

When replacing an existing image, change only the image source, size, and `alt`. Keep the surrounding markup, classes, and loading behavior.

### 9. Self-check the rendered page

Before handing back, open the page and check it, using a browser tool if you have one, or by fetching and viewing each delivery URL if not.

Check the page as a visitor sees it, with all its styles, scripts, and fonts loaded. Use the project's dev server if it has one. For a static site, serve the folder over local HTTP (for example, `python3 -m http.server`) rather than opening the file directly: some browser tools load a `file://` page without its stylesheet, which hides crop and overlay problems. If the page renders unstyled, fix that before checking anything else. Take a screenshot at desktop width and one at phone width.

- [ ] Every delivery URL returns HTTP 200 and an image, not an error placeholder
- [ ] Each image shows what its slot needs, at the size it's displayed
- [ ] No key subject is cropped badly (cut-off heads, products cut in half), at desktop or phone width
- [ ] Overlay text is readable over the image
- [ ] The images look consistent together on the page
- [ ] No image appears blurry or pixelated at 2x

Fix any failure by returning to step 5 for that slot (next candidate), step 6 (edit), or step 7 (new generation). Limit this to 2 fix rounds, then report what's left.

### 10. Report to the user

End with a short table, one row per slot:

| Slot | Source | Asset | Score | Why |
|---|---|---|---|---|
| `home-hero` | Library | `samples/autumn-path` | 17/20 | Wide autumn path, clean sky for the headline |
| `menu-banner` | Adapted | `bakery-site/menu-banner` | 16/20 | Library photo was 4:3; extended to 21:9 with generative fill |
| `about-team` | Generated | `bakery-site/about-team` | 15/20 | No team photos in the library; generated a matching portrait |

Also list the discovery method you used, any slots you flagged, any images you edited or generated and saved (with their public IDs and the original asset for edits), the Image Generation quota used and remaining, and anything the user should review, such as generated images of people presented as real staff or customers.

## Common Mistakes

- Assuming Visual Search is available: test it, and fall back to another discovery method without fuss
- Starting to generate without asking for write permission, then being blocked from saving after the quota is spent
- Running an auto-tagging or captioning pass on the user's assets without asking
- Accepting a product shot with a third-party logo, or a background that clashes with the cards next to it, instead of fixing it in step 6
- Checking the page from a `file://` URL that loads without its stylesheet
- Generating from scratch when an edit to an existing image would fix the problem
- Overwriting the original asset with an edited version, or leaving a generative edit in a `srcset` URL so it runs again for every width
- Choosing from the public ID or tags without viewing the image
- Searching with the page's marketing copy instead of a visual description
- Choosing a small image and scaling it up: check `width` and `height` against the minimum source size
- Placing a portrait image in a wide banner and relying on `g_auto` to rescue it
- Delivering one wide crop to a slot whose aspect ratio changes on phones, so CSS center-cropping cuts out the subject
- Using the same image twice on one page
- Generating before searching, or saving every generation attempt to the product environment
- Putting API credentials in client-side code
