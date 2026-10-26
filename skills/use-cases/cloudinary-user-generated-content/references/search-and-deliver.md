# Search and Delivery Reference

Canonical page: [Search for resources](https://cloudinary.com/documentation/admin_api_resources_search_for_resources.md?install_source=skillspack&referrer=ugc-skill). Verify parameter names there before generating code — don't guess.

## Marking an asset approved and searchable

When your server flips `moderation_status` to `approved` (see [moderation.md](moderation.md)), also add a durable tag in the same call — e.g. `ugc_approved` — via the Admin API `update` method's `tags` parameter (or your SDK's dedicated tag-management call). Do this once, at approval time. The feed query below filters on this tag; it does not re-check `moderation_status` per request.

## Building the feed/gallery query

Use the Search API (`GET /resources/search`), not the Admin API's moderation listing — that endpoint is for the review queue (see [moderation.md](moderation.md#listing-pending-assets)), not public-facing results.

Expression syntax:

- `resource_type:image` / `resource_type:video` — exact match.
- `tags:ugc_approved` — tokenized, case-insensitive; `tags=ugc_approved` — exact, case-sensitive.
- Combine with `AND` / `OR` / `-` (negation), e.g. `resource_type:image AND tags=ugc_approved`.

```javascript
cloudinary.v2.search
  .expression('resource_type:image AND tags=ugc_approved')
  .sort_by('created_at', 'desc')
  .max_results(50)
  .execute()
  .then(result => console.log(result));
```

- `max_results`: integer 0–500, default 50.
- Paginate with the `next_cursor` the response returns — pass it back as `next_cursor` on the next call, keeping every other parameter unchanged.
- `sort_by` takes field/direction pairs (`asc`/`desc`); repeat it for a multi-level sort.
- Initialize a **new** `search` query object for every distinct query. Reusing one instance — especially after `sort_by` was already set — can produce unexpected results.
- Search results are eventually consistent: an asset approved moments ago can take a few seconds to appear. Don't treat an empty or stale result right after approval as a sign the approval failed.

## Delivering the result to a viewer

- **Public (`type: upload`):** build the delivery URL the normal way — `res.cloudinary.com/<cloud_name>/image/upload/.../<public_id>`. Transformation syntax (resizing, `f_auto/q_auto`, feed-specific crops) is out of this skill's scope; hand off to `cloudinary-transformations`.
- **Still `authenticated`/token-gated:** mint the signed or token URL per viewer, per request, at the moment that viewer's page/feed renders — see [access-control.md](access-control.md). Don't generate one signed URL server-side and cache/reuse it across different viewers; it's bound to the specific signature/`auth_token` parameters it was issued with.
