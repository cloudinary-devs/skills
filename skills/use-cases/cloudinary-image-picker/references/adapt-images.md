# Adapting near-miss images

Read this in step 6, once you've picked a fix from the table in SKILL.md. It covers the `image_to_image` call, how to check an edit, and how to save an approved edit as a new asset.

For several changes or a restyle, use `image_to_image`, saving the result straight to the product environment as a new asset (never overwrite the original). Image Generation sets `ai_generated` on it automatically:

```bash
curl -s -X POST "https://api.cloudinary.com/v2/generate/$CLOUDINARY_CLOUD_NAME/image_to_image" \
  -u "$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Keep the people and composition of [1], change the season to autumn with orange leaves and warm light",
    "reference_images": [{ "source_type": "managed_asset", "asset_id": "<ASSET_ID>" }],
    "model": { "mode": "auto" },
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

Without API credentials, use the `upload-asset` tool with the same parameters.

Always save generative edits as assets like this, instead of leaving the generative transformation in the delivery URL. The responsive sizes in step 8 then resize one fixed image instead of re-running the edit for every width, and the image's AI provenance comes from the saved asset's `ai_generated` field. On accounts that add C2PA data to images delivered with generative transformations (only some do), saving the transformation URL keeps that C2PA manifest in the new asset, and in its resized derivatives. Images made with Image Generation (`text_to_image` and `image_to_image`) don't get C2PA data, only the `ai_generated` field.
