# Adapting near-miss images

Read this in step 6, once you've picked a fix from the table in SKILL.md. It covers the `image_to_image` call, how to check an edit, and how to save an approved edit as a new asset.

For several changes or a restyle, use `image_to_image`, saving the result straight to the product environment as a new asset (never overwrite the original). Image Generation sets `ai_generated` on it automatically. Set `<PREFERENCE>` to the generation priority answer from step 2 (`quality`, `economy`, or `balanced`, with `_fast` added if speed matters; `balanced` if unanswered):

```bash
curl -s -X POST "https://api.cloudinary.com/v2/generate/$CLOUDINARY_CLOUD_NAME/image_to_image" \
  -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Keep the people and composition of [1], change the season to autumn with orange leaves and warm light",
    "reference_images": [{ "source_type": "managed_asset", "asset_id": "<ASSET_ID>" }],
    "model": { "mode": "auto", "preference": "<PREFERENCE>" },
    "target": { "target_type": "managed_asset", "public_id": "<SITE_NAME>/<SLOT_ID>" }
  }'
```

Then:

1. **Check the result**: open the transformation URL (the first request can take a while, since the edit runs then, and may return `423` with "Processing continued in the background": repeat the request until it returns `200`) or the `secure_url` of the saved `image_to_image` asset, and view it. Score it with the step 5 rubric. If it scores under 14, try a different fix or a clearer prompt, up to 2 attempts, then go to step 7.
2. **Save the approved result as a new asset.** An `image_to_image` edit is already saved: delete each rejected attempt with `delete-asset` (or the Admin API) before retrying, then add the tags `ai-edited,image-picker` and the `alt` context. For an edit made with a transformation from the table, save the transformation URL as a new asset, but only once the URL returns `200` (saving it while it returns `423` fails with "423 Locked"), with `tags=ai-edited,image-picker`, the `alt` context, and `ai_generated=true`. Don't overwrite the original:

```bash
curl -s -X POST "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload" \
  -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  -F "file=<TRANSFORMATION_URL>" \
  -F "public_id=<SITE_NAME>/<SLOT_ID>" \
  -F "tags=ai-edited,image-picker" \
  -F "context=alt=<ALT_TEXT>" \
  -F "ai_generated=true"
```

Without API credentials, use the `upload-asset` tool with the same parameters. Separate several `context` pairs with `|` (for example, `alt=<ALT_TEXT>|prompt=<PROMPT>`), and escape any `=` or `|` inside a value with a backslash.

Always save generative edits as assets like this, instead of leaving the generative transformation in the delivery URL. The responsive sizes in step 8 then resize one fixed image instead of re-running the edit for every width, and the image's AI provenance comes from the saved asset's `ai_generated` field. C2PA data depends on the account. On accounts with the C2PA flags enabled, Cloudinary adds a manifest to images delivered with generative transformations and preserves and extends an existing one when any other transformation is applied (resizing, cropping, format changes, overlays), so saving the transformation URL keeps the manifest in the new asset and its derivatives. On accounts without the flags, deliveries carry no C2PA data, and a manifest that a model embedded in a generated original isn't kept in any transformed delivery. Cloudinary doesn't add C2PA data to Image Generation output itself, and some models embed their own manifest in the original PNG. The `ai_generated` field is the provenance signal on every account.
