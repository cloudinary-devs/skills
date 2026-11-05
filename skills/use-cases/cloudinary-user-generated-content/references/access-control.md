# Delivery and Access Control Reference

Canonical page: [Control access to media](https://cloudinary.com/documentation/control_access_to_media.md?install_source=skillspack&referrer=ugc-skill). Verify parameter names there before generating code — don't guess.

## Delivery types (`type` upload parameter)

Set once, at upload:

| `type` | Original | Derived versions |
|---|---|---|
| `upload` (default) | Public via CDN | Public |
| `private` | Signed URL only | Public unless strict transformations are enabled |
| `authenticated` | Signed URL or token only | Also requires a signed URL or token |

For UGC awaiting moderation, upload with `type: "authenticated"` so nothing — original or derivative — is reachable by a bare CDN URL while `moderation_status` is `pending` or `rejected`. See [Rule 1 in SKILL.md](../SKILL.md#non-negotiable-rules).

## Serving a pending asset back to its own uploader

Generate a signed URL rather than exposing the raw path:

```ruby
cl_image_tag("secret_couple.jpg", height: 300, width: 300, crop: "fill", sign_url: true, type: "authenticated")
```

This produces a URL with a signature segment, e.g. `https://res.cloudinary.com/demo/image/authenticated/s--77PWXXNB--/c_fill,h_300,w_300/v1515589189/secret_couple.jpg`. Every Cloudinary SDK's URL/tag helper takes the same `sign_url`/`type` combination — check the SDK in use for its exact option names.

Authenticated assets cannot be transformed on the fly: only transformations generated at upload (`eager`) or added afterward via `explicit` are servable. Decide your needed derivatives (thumbnail, feed size, etc.) before moderation finishes if you want them ready the instant an asset is approved.

## Token-based access (premium add-on)

Instead of ever making the asset fully public, issue short-lived per-viewer signed URLs:

```ruby
cl_image_tag("sample.jpg", sign_url: true, auth_token: { key: "MyKey", duration: 300 }, type: "authenticated")
```

`key` is the encryption key Cloudinary provides for this feature (not the account's API secret) — tell the user to generate it in the Console and set it as an environment variable, never hardcode it. `duration`/`expiration` controls how long that specific URL is valid.

## Flipping an asset from pending to approved

Once `moderation_status` is `approved` (see [moderation.md](moderation.md)), make the asset deliverable per-asset — there is no safe bulk shortcut:

- The Admin API's bulk "update access mode by tag/prefix" endpoint has been retired. Do not generate calls to it.
- Update the single asset instead: re-upload in place or use the Admin API's per-asset `explicit`/`update` methods with the target `type`/`access_control` for that one public ID. Confirm the exact parameter the SDK version expects against the [Admin API reference](https://cloudinary.com/documentation/admin_api.md?install_source=skillspack&referrer=ugc-skill) — don't assume `access_mode` is still settable this way without checking.
- If the product goal is "approved but still restricted to logged-in users" rather than "fully public," skip the flip entirely and keep serving it via token-based access instead.
