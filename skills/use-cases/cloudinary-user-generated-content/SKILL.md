---
name: cloudinary-user-generated-content
description: "End-to-end recipe for user-generated content (UGC) pipelines on Cloudinary. Use when users upload images or videos, Cloudinary must process and moderate them, and only approved assets should be delivered to other users — covering unsigned client uploads, automatic/manual moderation, pending-vs-approved access control, and moderation webhooks."
license: MIT
metadata:
  author: cloudinary
  version: '1.0.0'
---

# Cloudinary User-Generated Content

## When to Use

- A user-facing app lets end users upload photos or videos that other users will eventually see (social feeds, marketplaces, reviews, community galleries, profile pictures).
- The flow needs any of: unsigned/direct browser or mobile uploads, automatic or manual content moderation, a pending-review state, or gating delivery until an asset is approved.
- Error/symptom triggers: "how do I keep unapproved uploads from being public", "unsigned upload preset for user content", "moderate images before they go live", "duplicate upload detection", "notify my app when moderation finishes".

**Not in scope:** generating the transformation string inside an already-public delivery URL (use `cloudinary-transformations` once step 5 hands off to it), general SDK setup or API lookups outside this flow (use `cloudinary-docs`), and framework-specific upload widget wiring (use the matching framework skill, e.g. `cloudinary-react`, if installed — otherwise fall back to `cloudinary-docs`).

## Non-Negotiable Rules

1. **Never deliver pending content through a public URL.** Upload UGC with `type=authenticated` (or `private`) so the asset isn't reachable via its plain `res.cloudinary.com/.../upload/...` URL while it's `pending`. Only an app server decision — after moderation approves the asset — should make it publicly deliverable (see [Delivery and access control](#3-gate-delivery-by-moderation-status)). Treating a "status" field as the only gate while uploading `type=upload` means anyone with the direct URL sees unapproved content regardless of what your app's UI shows.
2. **Lock down unsigned upload presets.** An unsigned preset used for direct-from-browser/mobile UGC uploads must set `unsigned: true`, a fixed `folder` (or `asset_folder`), `disallow_public_id: true`, and `allowed_formats`. Without these, an uploader can pick their own `public_id` or folder and overwrite or collide with another user's asset.
3. **Pick one moderation strategy per asset type and be explicit about it.** Automatic add-on moderation (`aws_rek` for images, `aws_rek_video`/`google_video_moderation` for video, `webpurify` for images, `duplicate:<threshold>` for duplicate detection) requires the matching add-on enabled on the account — that's a console/billing action only the user can take; tell them which add-on to enable rather than assuming it's already on. `manual` moderation needs no add-on but means a human reviews it in the Media Library or via the Admin API. Combine types by piping them (`aws_rek|duplicate:0`); when `manual` is combined with others it must be listed last.
4. **Re-check moderation status server-side before exposing an asset**, using the Admin API, not a client-supplied flag. A mobile/web client can fake a "status: approved" field in its own request; it cannot fake what the Admin API returns for that asset's `moderation` status.
5. **Don't rely on the Admin API's bulk "update access mode" endpoint** — it's been retired. To flip an asset from authenticated to public once approved, update it per-asset (`explicit`/`update` with the asset's `type`/`access_control`), not a bulk by-tag or by-prefix call.
6. Never hardcode or print `CLOUDINARY_API_SECRET`, Admin API keys, or add-on credentials. Read them from environment variables and tell the user which ones to set.

## Core Workflow

```
- [ ] 1. Accept the upload (unsigned preset, scoped per user)
- [ ] 2. Apply moderation at upload time
- [ ] 3. Gate delivery by moderation status (authenticated until approved)
- [ ] 4. React to moderation results (webhook or manual review queue)
- [ ] 5. Deliver approved content to other users
```

### 1. Accept the upload

Use when the client uploads directly (browser/mobile) rather than through your app server. For server-side uploads, use a signed upload instead and skip the preset.

- Create an **unsigned upload preset** (Console → Upload Presets, or the Admin API `upload_presets` method) with: `unsigned: true`, `folder` or `asset_folder` fixed to something like `ugc/<app>/incoming`, `disallow_public_id: true`, `allowed_formats` restricted to the formats you support, and `tags` including a constant like `ugc`.
- Set `type: "authenticated"` on the preset (or in the client's upload call) so the asset is never publicly reachable, even for a moment, before moderation runs. See [Rule 1](#non-negotiable-rules).
- Set `context` to carry the uploader's user ID (e.g. `context="uploaded_by=<user_id>"`) so you can look up "this user's pending uploads" later without a separate database write, though most apps still want their own row to track UI state.
- Full unsigned-upload parameter list and the exact browser/SDK call syntax: [Client-side uploading](https://cloudinary.com/documentation/client_side_uploading.md?install_source=skillspack&referrer=ugc-skill) and [Upload presets](https://cloudinary.com/documentation/upload_presets.md?install_source=skillspack&referrer=ugc-skill).

### 2. Apply moderation at upload time

Set the `moderation` upload parameter (on the preset or the request) to one of:

| Value | Moderates | Needs add-on? |
|---|---|---|
| `manual` | image or video | No — reviewed in Media Library or Admin API |
| `aws_rek` | image | Yes — Amazon Rekognition AI Moderation |
| `aws_rek_video` | video | Yes — Amazon Rekognition Video Moderation |
| `google_video_moderation` | video | Yes — Google AI Video Moderation |
| `webpurify` | image | Yes — WebPurify Image Moderation |
| `duplicate:<threshold>` | image | Yes — Duplicate Image Detection |

Pipe-separate to combine (e.g. `aws_rek|duplicate:0`); if `manual` is one of them, put it last. The asset's `moderation_status` starts `pending`, resolves to `approved`/`rejected` (or `queued`/`aborted` for later steps in a pipeline). Full details, statuses, and the Admin API example for overriding a status: [references/moderation.md](references/moderation.md).

If moderation runs asynchronously (any automatic type, or async-processed manual queues), set `notification_url` on the upload so your app server gets a webhook instead of polling. See [references/moderation.md](references/moderation.md#notifications).

### 3. Gate delivery by moderation status

While `moderation_status` is `pending` or `rejected`, the asset must stay non-public:

- Keep `type: "authenticated"`. Deliver it to the uploader themselves (e.g. an "upload received, pending review" preview) with a signed URL: set `sign_url: true` and `type: "authenticated"` in the SDK's URL/tag helper.
- Once an asset is `approved`, your app server (never the client) updates it — either re-upload-in-place via `explicit` with `type: "upload"`, or serve it through signed/token-based authenticated delivery permanently if you don't want it ever fully public. Token-based access (premium) lets you issue short-lived signed URLs per viewer instead of flipping the asset public. Full parameter names and code samples: [references/access-control.md](references/access-control.md).
- Authenticated assets can't be transformed on the fly — only transformations generated at upload (`eager`) or via `explicit` are servable. Plan your `eager` derivatives (thumbnail, feed size, etc.) at upload time if you need them before approval flips the asset public.

### 4. React to moderation results

- **Manual queue:** list pending assets with the Admin API's resources-by-moderation endpoint, filtered to `moderation_status=pending`, and build your review UI against that — not against your own app's copy of the status, which can drift. See [references/moderation.md](references/moderation.md#listing-pending-assets).
- **Automatic/webhook:** verify the webhook signature, read the `moderation_status` the notification reports, and update your app's record plus the asset's delivery type (step 3) accordingly. Treat the webhook payload as untrusted input until the signature verifies — see [references/moderation.md](references/moderation.md#notifications).

### 5. Deliver approved content to other users

This is the step that actually completes the workflow: getting the approved asset in front of *other* users, not just the uploader.

- **Make approved assets findable.** At the moment your server flips an asset to approved (step 3/4), also add a durable marker your gallery/feed query can filter on — a tag (e.g. `ugc_approved`) or a `context` field. Don't make the feed query re-derive "is this approved" from `moderation_status` on every request; you already verified it once server-side at approval time, so trust your own marker instead of re-querying the Admin API per asset on every page load.
- **List approved assets with the Search API**, filtering on that marker, e.g. an expression like `tags:ugc_approved AND resource_type:image`, sorted and paginated for a feed or gallery. The Search API is the right tool for "give me a page of assets matching criteria"; the Admin API's moderation listing (step 4) is for the review queue, not the public-facing feed.
- **Generate the delivery URL for viewers** the same way you would for any public asset once `type` is `upload`: a plain `res.cloudinary.com/<cloud_name>/image|video/upload/...` URL, optionally with transformations. Building that transformation string (resizing, `f_auto/q_auto`, cropping for a feed layout, etc.) is outside this skill's scope — hand off to `cloudinary-transformations`.
- **If you kept the asset `authenticated`/token-gated instead of flipping it public** (e.g. "approved but only visible to logged-in users," see [references/access-control.md](references/access-control.md)), the delivery step changes: your app server mints a short-lived signed/token URL *per viewer, per request* — not once and cached — since each viewer's token is tied to that viewer's session, not to the asset.
- Full search expression syntax, pagination, and delivery URL construction: [references/search-and-deliver.md](references/search-and-deliver.md).

## Output Expectations

When you generate code or configuration for this flow, the response must include:

- Which of the two upload paths (unsigned client preset vs. signed server upload) was chosen, and why.
- The exact preset/upload parameters used (`type`, `moderation`, `folder`/`asset_folder`, `disallow_public_id`, `allowed_formats`, `notification_url` if async).
- Where the moderation-status check happens (server-side, via the Admin API) before any delivery URL reaches another user.
- How other users actually discover and receive approved content — the marker used to query approved assets (tag/context), the Search API call or equivalent that builds the feed/gallery, and whether delivery is a plain public URL or a per-viewer signed/token URL.
- Which environment variables the user must set (`CLOUDINARY_URL` or `CLOUDINARY_API_KEY`/`CLOUDINARY_API_SECRET`/`CLOUDINARY_CLOUD_NAME`), never inline credentials.
- If an add-on moderation type is used: an explicit note that the user must enable that add-on in the Console before it will work.

## Self-Validation Checklist

- [ ] Unsigned preset (if used) sets `unsigned: true`, a fixed folder, `disallow_public_id: true`, and `allowed_formats`.
- [ ] Pending/rejected assets are never reachable at a public `type=upload` URL.
- [ ] A chosen `moderation` value matches an add-on the user has confirmed is enabled, or is `manual`.
- [ ] Delivery to other users checks `moderation_status` via the Admin API (or a trusted server-side webhook record), not a client-supplied field.
- [ ] No bulk "update access mode" Admin API call is used (it's retired); per-asset updates only.
- [ ] Approved assets are actually made discoverable to other users (a tag/context marker set at approval time, queried with the Search API) — the flow doesn't stop at "asset is approved" without a path for other users to see it.
- [ ] No credential is hardcoded, printed, or requested in chat.

### Common Mistakes

| Wrong | Right |
|---|---|
| `cloudinary.uploader.unsigned_upload(file, "ugc_preset")` with no `type` set, then checking a DB `status` column before rendering | Upload with `type: "authenticated"` so the CDN itself blocks pending content; the DB status only drives your UI, it isn't the security boundary |
| Unsigned preset with no `allowed_formats` or `disallow_public_id` | Preset sets `allowed_formats: "jpg,png,mp4"` and `disallow_public_id: true` |
| Assuming `aws_rek` just works because the parameter is accepted | Confirm with the user that Amazon Rekognition AI Moderation is enabled on their account before relying on it |
| Polling the Admin API in a loop to detect moderation completion | Set `notification_url` and handle the moderation webhook |

## Reference Map

- [references/moderation.md](references/moderation.md) — moderation types, combining types, statuses, Admin API status override, webhook notification handling, listing pending assets. Use when configuring or reacting to moderation.
- [references/access-control.md](references/access-control.md) — `type`/`access_mode` delivery types, signed URLs, token-based (premium) access, flipping an asset from pending to public. Use when deciding how pending vs. approved content is delivered.
- [references/search-and-deliver.md](references/search-and-deliver.md) — tagging an asset approved and searchable, Search API expression syntax and pagination, delivering the result to a viewer. Use when building the feed/gallery that shows approved content to other users.

## Examples

**User:** "Users upload profile photos; nobody else should see a photo until we've reviewed it."

**AI does:** Maps this to manual moderation (no add-on needed) plus `type: "authenticated"` at upload (step 1 and 3). Builds the review queue against the Admin API's moderation-status listing (step 4), not a custom "approved" boolean the client could set. Flags that flipping an approved asset to public delivery must happen via a per-asset Admin API call, not the retired bulk access-mode endpoint.

**User:** "We want explicit images auto-rejected with Rekognition, and skip human review entirely."

**AI does:** Uses `moderation: "aws_rek"` alone (no `manual`, since the user explicitly wants no human step). Tells the user this requires enabling Amazon Rekognition AI Moderation in the Console first — an account action only they can take — before the upload parameter has any effect. Sets `notification_url` so the app finds out the automatic result instead of polling, and still gates delivery on `moderation_status` server-side in case the webhook is delayed.

**User:** "Also catch people re-uploading the same image under a different account."

**AI does:** Adds duplicate detection to the existing moderation chain rather than a separate system: `moderation: "aws_rek|duplicate:0"`. Notes the add-on dependency for `duplicate` too, and that if `manual` were added to this chain it would need to go last.

**User:** "Once a photo's approved, how do other users actually see it in the feed?"

**AI does:** Treats this as step 5, not a restatement of step 3. Has the approval action (wherever `moderation_status` is read and the asset is flipped, step 3/4) also set a `ugc_approved` tag. Builds the feed query against the Search API filtered on that tag, not against `moderation_status` per request. Generates the viewer-facing delivery URL as a normal public URL if the asset was flipped to `type: upload`, or a per-request signed/token URL if it's staying `authenticated`, and defers the actual transformation syntax (thumbnail sizing, `f_auto/q_auto`) to `cloudinary-transformations`.

## Key References

- [Moderate assets](https://cloudinary.com/documentation/moderate_assets.md?install_source=skillspack&referrer=ugc-skill)
- [Control access to media](https://cloudinary.com/documentation/control_access_to_media.md?install_source=skillspack&referrer=ugc-skill)
- [Client-side uploading](https://cloudinary.com/documentation/client_side_uploading.md?install_source=skillspack&referrer=ugc-skill)
- [Upload presets](https://cloudinary.com/documentation/upload_presets.md?install_source=skillspack&referrer=ugc-skill)
- [Notification messages (webhooks)](https://cloudinary.com/documentation/notification_messages.md?install_source=skillspack&referrer=ugc-skill)
- [Admin API](https://cloudinary.com/documentation/admin_api.md?install_source=skillspack&referrer=ugc-skill)
- [Search for resources](https://cloudinary.com/documentation/admin_api_resources_search_for_resources.md?install_source=skillspack&referrer=ugc-skill)
