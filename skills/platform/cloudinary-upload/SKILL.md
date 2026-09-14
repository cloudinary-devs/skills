---
name: cloudinary-upload
description: Reference for uploading assets to Cloudinary, covering signed and unsigned uploads, upload presets, transformations on upload, naming and folders, large files, remote uploads, and signature generation. Use when uploading files or URLs to Cloudinary, configuring upload presets, generating upload signatures, choosing between the SDK, REST API, or Upload widget, or debugging upload failures. For Next.js or React projects, use cloudinary-next or cloudinary-react alongside this skill.
license: MIT
metadata:
  author: cloudinary
  version: '1.0.0'
---

# Cloudinary Upload

## When to Use

- Uploading images, videos, or raw files to Cloudinary from any SDK, the REST API, or the Upload widget
- Choosing how to upload: backend SDK, Upload widget, or direct REST call
- Creating or configuring upload presets (signed or unsigned)
- Applying transformations at upload time (eager or incoming)
- Deciding how uploaded assets are named and organized into folders
- Generating upload signatures for signed uploads
- Uploading large files (> 100 MB) or from remote URLs
- Debugging upload failures (error responses, silent failures, unexpected behavior)

## Quick Start

### Default Best Practices: Apply These to Every Upload

Unless the user has a specific reason not to, every upload configuration you generate should:

1. **Use an upload preset.** Whenever more than one asset will be uploaded with the same parameters, put those parameters in a preset and pass only `upload_preset` in the request. See [Upload Presets](#upload-presets).
2. **Set `resource_type` explicitly** (`image`, `video`, `raw`, or `auto`). Never rely on the default. See [`resource_type`](#resource_type--set-this-explicitly).
3. **Decide naming deliberately.** Either set a deterministic `public_id`, or set `use_filename: true`. Never let production assets fall back to random IDs by accident. See [Naming and Folders](#naming-and-folders).
4. **Restrict what can be uploaded**: `allowed_formats` and `max_bytes` in the preset, especially for unsigned uploads.
5. **Pre-generate derived assets with `eager`** when the delivery transformations are known up front, and use `eager_async: true` for video. See [Transformations on Upload](#transformations-on-upload).
6. **Keep the API secret server-side.** Signed uploads run on the server; browsers use unsigned presets or a server-issued signature.

**Important:** The parameter values shown throughout this skill are illustrative. Choose preset names, folders, formats, and transformations based on the user's actual requirements, not the example values.

### Choosing the Upload Method

| Method | Use when | Why |
|---|---|---|
| **Backend SDK** (Node, Python, Ruby, PHP, Java, .NET, Go) | Server-side uploads in a language Cloudinary supports | Handles signature generation, chunked uploads for large files, and response validation for you. **Default choice for server code.** |
| **Upload widget** | Users upload from a browser and need a UI | Complete drop-in UI (drag and drop, camera, URL, social and stock sources, cropping, progress). Works unsigned with a preset or signed via your backend. |
| **REST API directly** | No SDK for the language, or a minimal client-side unsigned upload without the widget | Full control, but you write the multipart request, signature, chunking, and error handling yourself. |

**Recommendation:** Prefer the SDK on the server and the Upload widget in the browser. Fall back to raw REST only when neither fits. For React and Next.js widget wiring, use the cloudinary-react or cloudinary-next skill.

### Request Shapes

**Unsigned upload (client-side, browser):**
```
POST https://api.cloudinary.com/v1_1/<cloud_name>/<resource_type>/upload
  upload_preset: <unsigned_preset_name>
  file: <file_data_or_url>
```

**Signed upload (server-side only):**
```
POST https://api.cloudinary.com/v1_1/<cloud_name>/<resource_type>/upload
  upload_preset: <preset_name>          (recommended)
  api_key: <api_key>
  timestamp: <unix_timestamp_in_seconds>
  signature: <generated_signature>
  file: <file_data_or_url>
```

**Upload widget (browser, unsigned):**
```html
<script src="https://upload-widget.cloudinary.com/latest/global/all.js"></script>
<script>
  const widget = cloudinary.createUploadWidget(
    { cloudName: '<cloud_name>', uploadPreset: '<unsigned_preset_name>' },
    (error, result) => {
      if (!error && result.event === 'success') console.log(result.info);
    }
  );
  document.getElementById('upload').addEventListener('click', () => widget.open());
</script>
```

**Remote/fetch upload (signed, server-side):**
```
POST https://api.cloudinary.com/v1_1/<cloud_name>/<resource_type>/upload
  api_key: <api_key>
  timestamp: <unix_timestamp_in_seconds>
  signature: <generated_signature>
  file: <public_url_to_fetch>
```

> **Note:** Replace `<resource_type>` with `image`, `video`, `raw`, or `auto`. Never omit it or rely on a default.

## Signed vs Unsigned

| | Unsigned | Signed |
|---|---|---|
| **Who runs it** | Client (browser, mobile) | Server only |
| **Auth** | Unsigned upload preset name | API key + secret signature |
| **Upload preset** | Required | Optional, but recommended |
| **Parameter control** | Restricted allow-list in the request; everything else comes from the preset | Full |
| **Precedence when a param is in both** | Preset wins (with exceptions, see below) | Request wins (with exceptions, see below) |
| **Overwrite** | Always forced to `false` | Configurable |
| **Security** | Preset name visible in requests | API secret never leaves the server |
| **Use when** | Public-facing upload UI, user-generated content | Server pipelines, migrations, anything needing overwrite or restricted params |

**Key rule:** If you need `overwrite: true`, or need to pass parameters outside the unsigned allow-list at request time, use a signed upload.

## Upload Presets

An upload preset is a named, centrally managed set of upload parameters. Pass `upload_preset: <name>` and every parameter in the preset is applied to the upload.

**Recommend a preset whenever more than one asset will be uploaded with the same parameters.** Treat request-time parameters as the exception, not the default. Presets:

- Keep upload behavior consistent across every SDK, widget, and REST call in the project
- Let the team change folders, transformations, moderation, or limits in the Console without redeploying code
- Are the only way to control non-allow-listed parameters for unsigned uploads, and the only way to lock them down
- Make the security posture auditable: one place to check `allowed_formats`, `max_bytes`, and folder placement

Configure at **Cloudinary Console → Settings → Upload → Upload presets**, or programmatically with the Admin API `upload_presets` methods.

### Recommended Preset Settings

Proactively suggest these when creating a preset; ask about the ones that depend on the use case:

| Setting | Why |
|---|---|
| `asset_folder` (dynamic folder mode) or `folder` (fixed folder mode) | Organizes uploads. See [Naming and Folders](#naming-and-folders) for which one applies. |
| `use_filename: true` + `unique_filename` | Readable public IDs derived from the original filename, with or without a random suffix. |
| `allowed_formats` | Rejects unexpected file types. Essential for unsigned presets. |
| `max_bytes` | Caps file size. Essential for unsigned presets. |
| `eager` (+ `eager_async: true` for video) | Pre-generates the derived assets your app will deliver. See [Transformations on Upload](#transformations-on-upload). |
| `transformation` (incoming) | Normalizes user-generated content before storage (cap dimensions, clip duration). |
| `tags`, `context`, `metadata` | Default classification applied to every upload through the preset. |
| `moderation`, `categorization`, `auto_tagging` | Add-on pipelines for user-generated content. |
| `notification_url` | Webhook for async results and moderation outcomes. |

Name presets by purpose (`user-avatars`, `product-images`, `video-social`), not by who created them.

### Parameter Precedence

When the same parameter is in both the preset and the request:

**Signed uploads:** the **request** value wins, except `eager` and incoming `transformation`, which are **merged** (both sets applied).

**Unsigned uploads:** the **preset** value wins, except:
- `context` and `metadata` are **merged**
- `public_id` and `filename_override` come from the **request** (unless the preset sets `disallow_public_id: true`)

**Important:** This means an unsigned request cannot override the preset's `folder`, `asset_folder`, or `tags`. If a value must vary per upload in an unsigned flow, either leave it out of the preset or use a signed upload.

## Transformations on Upload

Cloudinary generates transformations lazily on first delivery request by default. Two upload-time options change that:

| | `eager` | `transformation` (incoming) |
|---|---|---|
| **What it does** | Generates derived versions **in addition to** the stored original | Modifies the original **before** it is stored |
| **Original preserved?** | Yes | No, the transformed result is the original |
| **Use for** | Warming the cache so first visitors get instant delivery; video transformations; AI or add-on transformations that are slow; strict transformations mode | Normalizing user-generated content: cap resolution, clip video duration, strip metadata, reduce storage cost |
| **Default recommendation** | **Yes**, when the delivery transformations are known up front | Only when you genuinely want to discard the original |

**Rules:**

- **Prefer eager.** Keep originals unless there is a storage or normalization reason to alter them. Never apply an incoming transformation to layered formats such as PSD or TIFF.
- **Do not put the same transformation in both** `eager` and `transformation`. Pick one per transformation.
- **Never use `f_auto` in eager or incoming transformations.** Format negotiation happens at delivery based on the requesting browser, so there is nothing to negotiate at upload time. Pre-generate each format explicitly in eager (for example one `f_webp` and one `f_jpg` variant), then deliver with `f_auto` and no file extension so `f_auto` resolves to one of the pre-generated variants. `q_auto` is fine in both.
- **Delivery URLs must match the eager transformation exactly.** Cloudinary treats `c_fill,h_400,w_600` and `c_fill,w_600,h_400` as different derived assets. If the delivery URL differs by parameter order, extension, or an added `f_auto`, the eager asset is wasted and a new one is generated lazily. Use the cloudinary-transformations skill to build the delivery URL and keep the two in sync.
- **Use named transformations for anything reused.** Define `t_<name>` once, pass `eager: t_<name>`, and deliver with `t_<name>`. This guarantees the eager and delivery strings match and lets the team change the transformation without touching upload or delivery code. `f_auto` does not work inside a named transformation, so append it on the delivery URL: `t_<name>/f_auto`.
- **Use `eager_async: true` with `eager_notification_url` for video** and other slow transformations, so the upload call returns immediately and Cloudinary notifies you when derived assets are ready.
- **REST syntax:** `eager` is a pipe-separated list of transformation strings; chained components use `/`. SDKs accept arrays of transformation hashes.

```
eager: c_fill,g_auto,h_400,w_600,f_webp|c_fill,g_auto,h_400,w_600,f_jpg|t_product_card
eager_async: true
eager_notification_url: https://example.com/webhooks/cloudinary
```

## Naming and Folders

### Choose the naming strategy

| Strategy | Set | Result |
|---|---|---|
| Deterministic ID (recommended for app-managed assets) | `public_id: products/sku-1234` | Predictable URLs; combine with `overwrite: false` to skip duplicates or `overwrite: true, invalidate: true` to replace |
| Original filename | `use_filename: true` | `public_id` derived from the uploaded filename with a random suffix appended |
| Original filename, no suffix | `use_filename: true, unique_filename: false` | Exact filename as `public_id`; collisions are governed by `overwrite` |
| Random (default) | nothing | Random `public_id`. Acceptable for throwaway or user-generated content, not for SEO or predictable delivery |

Set the strategy in the preset so every upload path agrees. `filename_override` stores an original-filename value different from the uploaded file's name and works with `use_filename`.

### `public_id` rules and traps

- Do not include a file extension for images or videos. Include it only for `raw` files.
- Up to 255 characters. Avoid `? & # \ % < > +`. Cannot begin or end with a space or `/`.
- **Whitespace or empty `public_id`** → silently ignored → Cloudinary assigns a random ID
- Once assigned, `public_id` cannot be changed without re-uploading or using the rename API, and changing it breaks existing delivery URLs

### Dynamic vs fixed folder mode

Every product environment is in one of two folder modes. **All accounts created after June 2024 are dynamic.** Check **Console → Settings → Product environment** or the Admin API `config` method if unsure.

| | Dynamic folder mode (default) | Fixed folder mode (legacy) |
|---|---|---|
| **Folder parameter** | `asset_folder` | `folder` |
| **Does the folder appear in the URL?** | No. `asset_folder` only controls Console placement. Add `public_id_prefix` (or `use_asset_folder_as_public_id_prefix: true`) if you also want the path in the `public_id` | Yes. `folder` is prepended to `public_id` and becomes part of the delivery URL |
| **Moving or renaming folders** | Safe, URLs unchanged | Changes `public_id` and breaks URLs |
| **Display name** | `display_name` or `use_filename_as_display_name: true` sets a human-friendly Console name independent of the URL | Not supported |

**Rules:**
- In dynamic folder mode, **do not add `folder` to new code**. Use `asset_folder`, and `public_id_prefix` if the path should be in the URL.
- In dynamic folder mode, a `public_id` containing slashes does **not** place the asset in a folder. Set `asset_folder` too, or the asset lands in the root.
- `folder`, `asset_folder`, `public_id_prefix`, and `use_asset_folder_as_public_id_prefix` all belong in the preset for consistency.

### Overwrite and duplicates

- `overwrite` defaults to `false`. With a deterministic `public_id`, a repeat upload is skipped and the response includes the existing asset. This is the recommended way to avoid duplicates; no existence check is needed.
- To replace an asset in place: signed upload with `overwrite: true` and `invalidate: true` so CDN copies are refreshed.
- Unsigned uploads always treat `overwrite` as `false`.

## `resource_type` — Set This Explicitly

**Default is `image`.** Cloudinary will attempt to process any upload as an image unless you override.

| File type | Required `resource_type` |
|---|---|
| JPEG, PNG, GIF, WebP, SVG, etc. | `image` (default — still set explicitly) |
| MP4, MOV, AVI, WebM, and audio (MP3, WAV, FLAC) | `video` |
| PDF, ZIP, text, and other non-media files | `raw` |
| Unknown or mixed | `auto` (Cloudinary detects) |

**Failure modes when wrong:**
- Video uploaded as `image` → Cloudinary tries image processing → error or corrupted result
- Raw file uploaded as `image` → rejected or misprocessed
- Audio uploaded as `raw` → no audio transformations available; use `video`

**Recommendation:** Use `auto` when the file type is not known in advance. Use specific types when you control the upload.

## Unsigned Upload Parameters

Only these parameters may be passed directly in an unsigned upload request. Everything else must come from the upload preset:

```
upload_preset           (required)
public_id
public_id_prefix        (dynamic folder mode only)
folder
asset_folder            (dynamic folder mode only)
tags
context
metadata
face_coordinates
custom_coordinates
regions
source
filename_override
manifest_transformation
manifest_json
template
template_vars
```

Any other parameter in an unsigned request is silently ignored. Move it to the upload preset. Remember that for most of these the **preset value wins** if both are set (see [Parameter Precedence](#parameter-precedence)).

### `format` vs `allowed_formats` interaction

- **`allowed_formats`** validates the incoming file type. If the file type is in this list, it is stored as-is (no conversion).
- **`format`** converts files to the specified format, but only for files **not** in `allowed_formats`.
- If a file type is in `allowed_formats`, the `format` parameter is ignored for that file.

**Example:** `allowed_formats: [jpg, png]`, `format: webp`
- Upload a JPG → stored as JPG (not converted to WebP)
- Upload a BMP → converted to WebP

## Large Files

**Threshold:** Files > 100 MB require chunked upload.

**SDK first:** Every backend SDK handles chunking for you (for example Python's `upload_large()`, Node's `upload_large()`). Prefer the SDK method over hand-rolled chunking whenever an SDK is available.

**Minimum chunk size:** 5 MB (except the final chunk, which can be smaller).

**How it works (REST):**
1. Split the file into chunks of ≥ 5 MB
2. Send each chunk with a `Content-Range` header and a consistent `X-Unique-Upload-Id` header
3. Cloudinary returns `done: false` for intermediate chunks. Handle this response; do not treat it as an error
4. The final chunk response contains the full upload result

**Content-Range format:**
```
bytes <start>-<end>/<total>
```
- Range is **inclusive** on both ends
- First chunk of 6 MB: `bytes 0-5999999/22744222` (6,000,000 bytes)
- Off-by-one errors here cause rejected chunks

For full Content-Range arithmetic and request structure, see [references/chunked-uploads.md](references/chunked-uploads.md).

## Remote/Fetch Upload

Upload an asset directly from a public URL without downloading it first. Pass the URL as the `file` parameter of a normal (signed) upload; the asset is stored in your account like any other upload.

**URL rules:**
- Maximum 255 characters
- Must be URL-encoded (spaces → `%20`, special chars → `%XX`)
- Must be publicly accessible (no auth required)
- Remote server timeouts apply if the asset is large or slow

**Not the same as `type: fetch` delivery.** Fetch delivery URLs (`/image/fetch/<url>`) proxy a remote asset on the fly without storing it as an upload. Use a remote upload when you want the asset in your Media Library with its own `public_id`.

## Signed Upload Signature

Signatures authenticate server-side upload requests. **The API secret must never appear in client-side code.** If an SDK is available, let it sign the request; only implement this by hand for raw REST calls.

**What to include in the signature string:**
- All request parameters **except**: `file`, `cloud_name`, `resource_type`, `api_key`
- Do not include `signature` itself

**How to generate:**
1. Collect all upload parameters (excluding the four above)
2. Sort parameters alphabetically by key
3. Join as `key=value` pairs with `&` between them
4. Append your API secret directly (no separator): `sorted_params_stringYOUR_API_SECRET`
5. SHA-1 or SHA-256 hash the result

**Timestamp rules:**
- Must be a Unix timestamp in **seconds**, not milliseconds
- JavaScript: `Math.floor(Date.now() / 1000)`. `Date.now()` returns ms; divide by 1000
- Signature expires 1 hour after the timestamp

**Example parameter string (before hashing):**
```
folder=uploads&public_id=my_image&timestamp=1718100000YOUR_API_SECRET
```

For the complete algorithm with edge cases and examples, see [references/signed-uploads.md](references/signed-uploads.md).

## Security

### API secret
- **Never** include `api_secret` in client-side code, browser requests, or mobile apps
- **Never** commit it to version control (check `.env` files, config files)
- **Never** log it. Check logging middleware and error handlers
- If exposed: rotate immediately in Cloudinary Console → Settings → Security → Access Keys

### Unsigned preset exposure
- The upload preset name is visible in browser network requests and source code
- Anyone can reuse it to upload to your account (quota abuse)
- Unsigned uploads cannot overwrite existing assets, which limits the damage
- Lock the preset down: `allowed_formats`, `max_bytes`, `asset_folder` or `folder`, and `moderation` for user-generated content
- Use signed uploads for sensitive applications or when upload volume abuse is a concern

### Checklist before going live
- API secret is server-side only
- Upload preset is set to unsigned only if truly needed client-side
- `allowed_formats` restricts file types to what your app expects
- `max_bytes` set in the preset to prevent oversized uploads

## Async Uploads

Set `async: true` to process uploads in the background. Useful for large files or expensive eager transformations.

**Response when async:** Only contains `{status: "pending", batch_id: "..."}`. The full upload result is **not** in this response.

**Full result delivery:** Cloudinary POSTs the result to `notification_url` when processing completes.

**Required:** Set `notification_url` in your request or upload preset when using `async: true`. Without it, the result is lost.

**Python SDK:** `async` is a reserved keyword. Pass it as a dictionary key:
```python
# Wrong: syntax error
cloudinary.uploader.upload("file.jpg", async=True)

# Correct
cloudinary.uploader.upload("file.jpg", **{"async": True})
# or
cloudinary.uploader.upload("file.jpg", notification_url="https://...", **{"async": True})
```

## Self-Validation Checklist

**After generating any upload configuration or code, verify all of the following before returning:**

1. ✅ **Upload preset used** for any repeated upload pattern; request-time params limited to what genuinely varies per upload
2. ✅ **`resource_type` explicitly set**, matching the actual file type
3. ✅ **Naming strategy is deliberate**: deterministic `public_id`, `use_filename`, or an explicit decision to accept random IDs
4. ✅ **Folder parameter matches the folder mode**: `asset_folder` (+ `public_id_prefix` if needed) in dynamic mode, `folder` only in fixed mode
5. ✅ **Unsigned request only contains allow-listed parameters**, and nothing in the request expects to override a preset value that the preset wins
6. ✅ **No `f_auto` in `eager` or incoming `transformation`**; `f_auto` belongs on the delivery URL
7. ✅ **Eager transformations match the delivery URL string exactly**, or both use the same `t_<name>`
8. ✅ **`eager_async: true` + `eager_notification_url`** for video or slow eager transformations
9. ✅ **`public_id` has no whitespace and no extension** (extension only for `raw`)
10. ✅ **Signature timestamp in seconds**, not milliseconds
11. ✅ **API secret not in client code**; only present in server-side signature generation
12. ✅ **`notification_url` set when `async: true`**
13. ✅ **`overwrite: true` not expected in an unsigned flow**; it is silently forced to `false`
14. ✅ **Large file (> 100 MB) → SDK large-upload method or chunked upload**
15. ✅ **`allowed_formats` and `max_bytes` set on any unsigned preset**

## Debugging Workflow

When an upload fails or behaves unexpectedly, follow these steps in order:

### Step 1: Read the error response
Cloudinary errors are in the response body:
```json
{"error": {"message": "..."}}
```
Note the exact message before doing anything else. See [references/troubleshooting.md](references/troubleshooting.md) for error message → fix mappings.

### Step 2: Check `resource_type`
Is the `resource_type` in the URL correct for the file being uploaded?
- URL contains `/image/upload/` but the file is a video → change to `/video/upload/`
- Use `/auto/upload/` if the file type varies

### Step 3: Check upload type (signed vs unsigned)
- **Unsigned:** Is `upload_preset` in the request? Is it spelled correctly and set to unsigned in the Console?
- **Signed:** Are `api_key`, `timestamp`, and `signature` all present? Is the timestamp in seconds?

### Step 4: Check parameter validity and precedence
- **Unsigned:** Are any non-allow-listed parameters in the request? Remove them or move them to the preset.
- **Unsigned:** Is a request parameter being "ignored"? Check whether the preset defines the same parameter; the preset wins for most of them.
- **All:** Is `public_id` free of whitespace? Is the folder parameter right for the folder mode?

### Step 5: Verify the signature (signed uploads only)
1. Did you exclude `file`, `cloud_name`, `resource_type`, `api_key` from the signature string?
2. Are parameters sorted alphabetically before joining?
3. Is the API secret appended directly with no separator?
4. Is the timestamp within the last hour?

See [references/signed-uploads.md](references/signed-uploads.md) for the full algorithm.

### Step 6: Check preset configuration
Open Cloudinary Console → Settings → Upload → [your preset] and verify:
- Preset mode matches usage (signed vs unsigned)
- `allowed_formats` isn't blocking the file type
- `max_bytes` limit isn't exceeded
- Eager transformations don't contain `f_auto`

### Step 7: Eager asset not being used on delivery
- Does the delivery URL use the identical transformation string (same parameter order, same format component)?
- Delivering with `f_auto`? Pre-generate each format you expect `f_auto` to pick (for example `f_webp`, `f_avif`, `f_jpg`) as separate eager variants, and deliver without a file extension so the extension does not become part of the transformation string.
- Was `eager_async` used? The derived asset may not exist yet; check the `eager_notification_url` webhook.

### Step 8: Check chunked upload (large files only)
- Is `Content-Range` in the form `bytes <start>-<end>/<total>`?
- Is the range inclusive on both ends?
- Is `X-Unique-Upload-Id` the same value across all chunks?
- Are all chunks except the last ≥ 5 MB?

See [references/chunked-uploads.md](references/chunked-uploads.md) for arithmetic details.

### Step 9: Remote upload checks
- Is the URL ≤ 255 characters?
- Are special characters URL-encoded?
- Is the URL publicly accessible without authentication?

## Common Mistakes & Best Practices

**Avoid:**
- ❌ Passing `folder`, `tags`, `eager`, `allowed_formats` on every request → ✅ Put them in an upload preset and pass `upload_preset`
- ❌ `eager: c_fill,w_600,h_400,f_auto` → ✅ `eager: c_fill,h_400,w_600,f_webp|c_fill,h_400,w_600,f_jpg` (no `f_auto` at upload; explicit formats)
- ❌ Eager `c_fill,h_400,w_600`, delivery `c_fill,w_600,h_400` → ✅ Identical strings, or `t_card` in both
- ❌ `folder: products` in a dynamic-folder environment → ✅ `asset_folder: products` (+ `public_id_prefix: products` if the path belongs in the URL)
- ❌ `public_id: photo.jpg` → ✅ `public_id: photo` (extension only for `raw`)
- ❌ Expecting `overwrite: true` in an unsigned upload → ✅ Signed upload for overwrites
- ❌ Hand-rolling chunked upload in Node or Python → ✅ SDK `upload_large()`
- ❌ Incoming `transformation` to "optimize" originals → ✅ `eager` to warm derived assets; keep the original unless normalizing user-generated content

**Always:**
- Recommend an upload preset for any repeated upload pattern
- Set `resource_type` explicitly
- Set `allowed_formats` and `max_bytes` on unsigned presets
- Use `eager_async: true` for video eager transformations
- Build delivery URLs with the cloudinary-transformations skill so they match eager output

## Related Skills

- **cloudinary-transformations**: build the delivery URLs that must match eager transformations, and define named transformations reused in `eager`.
- **cloudinary-next** and **cloudinary-react**: framework-specific upload wiring, including `CldUploadWidget`, signature API routes and server actions, and environment variable handling.
- **cloudinary-docs**: anything outside this skill's scope, looked up in the current Cloudinary documentation.

## Additional Resources

### Skill References (Progressive Disclosure)
- [references/signed-uploads.md](references/signed-uploads.md) - Use when implementing signature generation by hand or debugging `Invalid signature`
- [references/chunked-uploads.md](references/chunked-uploads.md) - Use when implementing chunked upload over REST or debugging `Content-Range` errors
- [references/troubleshooting.md](references/troubleshooting.md) - Use when an upload returns an error or behaves unexpectedly

### Core Cloudinary Documentation
- [Upload API Reference](https://cloudinary.com/documentation/image_upload_api_reference.md?install_source=skillspack&referrer=upload-skill) - All upload parameters, unsigned allow-list, response format
- [Upload Guide](https://cloudinary.com/documentation/upload_images.md?install_source=skillspack&referrer=upload-skill) - Upload methods, chunked upload, avoiding duplicates
- [Upload Parameters](https://cloudinary.com/documentation/upload_parameters.md?install_source=skillspack&referrer=upload-skill) - Naming, folders, replacing assets, audio uploads
- [Upload Presets](https://cloudinary.com/documentation/upload_presets.md?install_source=skillspack&referrer=upload-skill) - Creating presets, precedence rules, best practices
- [Eager and Incoming Transformations](https://cloudinary.com/documentation/eager_and_incoming_transformations.md?install_source=skillspack&referrer=upload-skill)
- [Folder Modes](https://cloudinary.com/documentation/folder_modes.md?install_source=skillspack&referrer=upload-skill) - Dynamic vs fixed folders, `asset_folder` vs `folder`
- [Upload Widget](https://cloudinary.com/documentation/upload_widget.md?install_source=skillspack&referrer=upload-skill)
- [Upload Widget Reference](https://cloudinary.com/documentation/upload_widget_reference.md?install_source=skillspack&referrer=upload-skill) - All widget options and events
- [Authentication Signatures](https://cloudinary.com/documentation/authentication_signatures.md?install_source=skillspack&referrer=upload-skill)
- [Client-Side Uploading](https://cloudinary.com/documentation/client_side_uploading.md?install_source=skillspack&referrer=upload-skill)
