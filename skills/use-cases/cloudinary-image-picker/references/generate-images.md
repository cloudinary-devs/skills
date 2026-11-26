# Generating images

Read this in step 7 before you generate anything. It covers the quota budget, matching sets from one reference, writing the prompt, generating straight to a hosted asset, verifying and retrying, and checking that the `ai_generated` field is set.

## Check the generation budget

Every `text_to_image` and `image_to_image` call uses Image Generation quota, and a free plan's allotment runs out after a handful of images. Every response reports the quota in `limits.addons_quota` (`used_by_request`, `remaining`, `limit`).

- After the first call, work out how many more images the remaining quota allows, and plan around it: generate the slots that matter most first (hero, then products, then decorative backgrounds).
- Count retries against the budget. If the budget can't cover every slot plus a retry each, tell the user which slots you'll leave as library near-misses, before you spend it.
- The cost per image varies with the model, the resolution, and the endpoint, so read `used_by_request` after each call instead of assuming a fixed price. Request only the resolution the slot needs, and never more than `2K`: in testing, one 4K hero cost 19 units, about as much as 7 smaller images together. For wider slots, generate at `2K` and upscale (see below).
- The quota is counted in units, not images: in testing, a `2K` hero cost 5 units and a `1K` card cost 1. If the user gives a cap in images, keep to it and still track units.
- Report the quota used and remaining at the end.

## Generate matching sets from one reference

When several slots need images that look alike, such as product cards, a gallery, or a set of article headers:

1. Generate or choose **one** image that sets the look: the setting, props, light, and palette. Often this is the hero, or the first card.
2. Make the rest with the `image_to_image` endpoint, passing that image as the reference, and describe only what changes for each slot: "Same kraft bag, table, and light as [1], with dark espresso beans and a small espresso cup beside it".

This keeps the set consistent, which separate `text_to_image` prompts rarely do, and it's often much cheaper per image. Check `used_by_request` on the first one to confirm the saving before you make the rest.

**Write the prompt** from the slot inventory, not from the search query. A good prompt states:

1. Subject and action: "a barista pouring latte art into a ceramic cup"
2. Setting and props: "on a marble counter in a small, sunlit cafe"
3. Style and medium: "editorial photography, shallow depth of field"; or "flat vector illustration" for illustrated sites
4. Lighting and palette, matched to the site: "warm golden morning light, cream and brown tones"
5. Composition for the slot: "wide 16:9 framing, subject on the right third, empty soft-focus space on the left for a headline"
6. Exclusions: "no text, no logos, no watermarks"

Match the style of the images you already chose for the page, so the generated image doesn't stand out.

**Generate straight to a hosted asset** so what you check is exactly what you keep, and Image Generation sets `ai_generated` itself:

```bash
curl -s -X POST "https://api.cloudinary.com/v2/generate/$CLOUDINARY_CLOUD_NAME/text_to_image" \
  -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "<PROMPT>",
    "model": { "mode": "auto", "preference": "quality" },
    "image_size": { "aspect_ratio": "16:9", "resolution": "2K" },
    "target": { "target_type": "managed_asset", "public_id": "<SITE_NAME>/<SLOT_ID>" }
  }'
```

Without API credentials, call `generate-image` (or `generate-image-from-images`) with the same `target`.

- Set `aspect_ratio` to the slot's ratio, or the nearest supported one, and choose a `resolution` that meets the minimum source size. `2K` is about 2048 pixels on the long side, which is enough for slots up to about 1000 CSS pixels wide at 2x. The supported ratios are `1:1`, `16:9`, `9:16`, `4:3`, and `3:4` (there is no `21:9`: generate `16:9` and crop). The size you get varies by model (a `1K` square came back at 1600x1600, a `2K` 16:9 at 2048x1152), so read `width` and `height` from the response before you decide whether the image meets the minimum source size.
- For wider slots, such as a full-width hero, still generate at `2K`, which costs far less than `4K`. If the approved image is under the slot's minimum source size, upscale it when you save it: `e_upscale` always multiplies each dimension by 4, so follow it with `c_limit` to stop at the minimum source size, and save that derived image. For example, for a 1440x600 hero, save `e_upscale/c_limit,w_2880/<PUBLIC_ID>` rather than the full 8192-pixel result. Upscaling doesn't use Image Generation quota. The pre-upscale original stays in the library as the approved image, and the upscaled copy is a separate asset: list both in the report.
- For text-heavy or vector needs, `mode: auto` picks a suitable model. Only pin a `model.id` if the user asks.
- If an existing image is close to what you need, adapt it in step 6 instead of generating from scratch.

**Verify the result** by viewing `data.assets[0].storage.secure_url`. Score it with the step 5 rubric. If it scores under 14, delete that attempt with `delete-asset` (or the Admin API), rewrite the prompt to fix what's wrong (name the specific problem, for example "the subject is centered, move it to the right third") and try again. Stop after 3 attempts per slot, keep the best result, and flag the slot in the report. Delete every rejected attempt, so only the approved image is left in the library.

**Then add the tags and context** (`ai-generated,image-picker`, plus the `alt` and `prompt`) with `manage-asset-tags` and `manage-asset-context`, or the Admin API.

**Check the AI-generated field.** Image Generation sets [`ai_generated`](https://cloudinary.com/documentation/content_provenance_and_authenticity.md?install_source=skillspack&referrer=image-picker-skill#provenance_and_ai_fields) on every image it saves to the product environment, on any account, whether or not the user wants a visible label. Search and the conditional AI label in step 8 rely on it. Confirm it with `search-assets` and the expression `ai_generated=true AND public_id="<PUBLIC_ID>"`. If it isn't set, add the step 8 AI label unconditionally, and say in the report that the asset isn't marked as AI-generated.

When you save anything else that is AI-generated or AI-edited by uploading it (such as a generative transformation URL, as in step 6), pass `ai_generated=true` (the `ai_generated` parameter of the `upload-asset` and `sign-upload` tools, or `-F "ai_generated=true"` with the Upload API). Only set it on images that really are AI-generated or AI-edited: once `true`, it's permanent, even if you upload over the same public ID, and it can't be added to an asset after upload.
