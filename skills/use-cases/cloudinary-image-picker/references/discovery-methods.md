# Discovery methods

Read this in step 4, after you've chosen a discovery method from the table in SKILL.md. It has the commands and filtering rules for each method; read only the section for the method you chose.

## A. Visual Search

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

## B. Browse the scope

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

## C. Search API on tags and captions

Turn each query variant into keywords: the main subject, setting, and season (`autumn`, `forest`, `path`). Search with tokenized, prefix matching on tags and captions, combined with the user's scope:

```
resource_type:image AND tags:CC0 AND (tags:autumn* OR context.caption:autumn* OR tags:forest*)
```

Assets get content tags and captions from the [Cloudinary AI Content Analysis add-on](https://cloudinary.com/documentation/cloudinary_ai_content_analysis_automatic_tagging.md?install_source=skillspack&referrer=image-picker-skill). If the scope has no auto-tags or captions, offer the user a one-time pass. **Ask first**: it writes tags to their assets and uses add-on quota. For each asset, call the Admin API `update` method:

- `detection=lvis` and `auto_tagging=0.6` to add tags for detected objects with 60% confidence or more
- `detection=captioning` to get a one-sentence caption. The caption comes back in `info.detection.captioning.data.caption`. Save it to the asset's `caption` context field so the Search API can match it.

## D. Search API on existing tags and names

Search the keywords from method C against `tags`, `public_id`, `display_name`, and `context`. Results depend on how well uploaders labeled their assets, so expect weak results and more generation.
