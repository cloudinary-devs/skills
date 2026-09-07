---
name: cloudinary-upload
description: Guide uploading assets to Cloudinary — signed and unsigned uploads, upload presets, large files, remote/fetch uploads, and signature generation. Use when uploading files or URLs to Cloudinary, configuring upload presets, generating upload signatures, or debugging upload failures. For Next.js or React projects, use cloudinary-next or cloudinary-react alongside this skill.
license: MIT
metadata:
  author: cloudinary
  version: '1.0.0'
---

# Cloudinary Upload

## When to Use

- Uploading images, videos, or raw files to Cloudinary from any SDK or the REST API
- Generating upload signatures for signed uploads
- Configuring upload presets (signed or unsigned)
- Debugging upload failures (error responses, silent failures, unexpected behavior)
- Setting up remote/fetch uploads from external URLs
- Uploading large files (> 100 MB)

## Quick Start

**Unsigned upload (client-side, browser):**
```
POST https://api.cloudinary.com/v1_1/<cloud_name>/<resource_type>/upload
  upload_preset: <preset_name>
  file: <file_data_or_url>
```

**Signed upload (server-side only):**
```
POST https://api.cloudinary.com/v1_1/<cloud_name>/<resource_type>/upload
  api_key: <api_key>
  timestamp: <unix_timestamp_in_seconds>
  signature: <generated_signature>
  file: <file_data_or_url>
```

**Remote/fetch upload (signed, server-side):**
```
POST https://api.cloudinary.com/v1_1/<cloud_name>/<resource_type>/upload
  api_key: <api_key>
  timestamp: <unix_timestamp_in_seconds>
  signature: <generated_signature>
  file: <public_url_to_fetch>
  type: fetch
```

> **Note:** Replace `<resource_type>` with `image`, `video`, or `raw` — never omit it or rely on a default. See the `resource_type` section below.

## Signed vs Unsigned

| | Unsigned | Signed |
|---|---|---|
| **Who runs it** | Client (browser, mobile) | Server only |
| **Auth** | Upload preset name | API key + secret signature |
| **Upload preset** | Required | Optional (recommended for defaults) |
| **Parameter control** | Restricted whitelist only | Full |
| **Overwrite** | Always forced to `false` | Configurable |
| **Security** | Preset name visible in requests | API secret never leaves server |
| **Use when** | Public-facing upload widgets | Server pipelines, sensitive apps |

**Key rule:** If you need `overwrite: true`, or need to pass parameters not in the unsigned whitelist, use a signed upload.

## `resource_type` — Set This Explicitly

**Default is `image`.** Cloudinary will attempt to process any upload as an image unless you override.

| File type | Required `resource_type` |
|---|---|
| JPEG, PNG, GIF, WebP, SVG, etc. | `image` (default — still set explicitly) |
| MP4, MOV, AVI, WebM, etc. | `video` |
| PDF, ZIP, audio files, etc. | `raw` |
| Unknown or mixed | `auto` (Cloudinary detects) |

**Failure modes when wrong:**
- Video uploaded as `image` → Cloudinary tries image processing → error or corrupted result
- Raw file uploaded as `image` → rejected or misprocessed
- Audio file → use `video` resource_type (Cloudinary processes audio under video)

**Recommendation:** Use `auto` when file type is not known in advance. Use specific types when you control the upload.

## Upload Presets

Upload presets define default parameters for uploads. Configure at: **Cloudinary Console → Settings → Upload → Upload presets**.

**For unsigned uploads:** Preset is required. Preset defines the parameters that can't be passed at request time.

**For signed uploads:** Preset is optional but useful for shared defaults across upload calls.

### Parameter Precedence

**Signed uploads:** Request parameters override preset parameters. Exception: `eager` and `incoming_transformation` are merged, not overridden.

**Unsigned uploads:** Request parameters (from the allowed whitelist) override the corresponding preset values. Parameters not in the whitelist are controlled entirely by the preset and cannot be overridden from the request.

### Common preset settings to configure
- `folder` — target folder for organized asset management
- `allowed_formats` — restrict accepted file types
- `eager` — transformations to generate immediately on upload
- `tags` — default tags applied to all uploads
- `moderation` — manual or AI moderation pipeline
- `auto_tagging` — AI tagging confidence threshold (0.0–1.0)

## Upload Parameters

### Unsigned upload — allowed parameters at request time

Only these parameters may be passed in an unsigned upload request. All others must be set in the upload preset:

```
upload_preset       (required)
public_id           (custom asset name/path)
folder              (target folder)
tags                (comma-separated list)
context             (key=value metadata pairs)
metadata            (structured metadata)
face_coordinates    (manual face bounding boxes)
custom_coordinates  (manual focus area)
regions             (named regions)
filename_override   (override original filename)
```

Any parameter not in this list is silently ignored in unsigned uploads. Move it to the upload preset instead.

### `public_id` — common traps

- **Whitespace in `public_id`** → silently ignored → Cloudinary assigns a random ID
- **Null or empty `public_id`** → random UUID assigned
- **File extension in `public_id`** → extension is stored as part of the ID, not stripped
- Once assigned, `public_id` cannot be changed without re-uploading or using the rename API

### `format` vs `allowed_formats` interaction

- **`allowed_formats`** validates the incoming file type. If the file type is in this list, it is stored as-is (no conversion).
- **`format`** converts files to the specified format — but only for files **not** in `allowed_formats`.
- If a file type is in `allowed_formats`, the `format` parameter is ignored for that file.

**Example:** `allowed_formats: [jpg, png]`, `format: webp`
- Upload a JPG → stored as JPG (not converted to WebP)
- Upload a BMP → converted to WebP

## Large Files

**Threshold:** Files > 100 MB require chunked upload.

**Minimum chunk size:** 5 MB (except the final chunk, which can be smaller).

**How it works:**
1. Split file into chunks of ≥ 5 MB
2. Send each chunk with `Content-Range` header and a consistent `X-Unique-Upload-Id` header
3. Cloudinary returns `done: false` for intermediate chunks — handle this response, do not treat as error
4. Final chunk response contains the full upload result

**Content-Range format:**
```
bytes <start>-<end>/<total>
```
- Range is **inclusive** on both ends
- First chunk of 6 MB: `bytes 0-5999999/22744222` (6,000,000 bytes)
- Off-by-one errors here cause rejected chunks

For full Content-Range arithmetic and request structure, see [references/chunked-uploads.md](references/chunked-uploads.md).

**SDK note:** Most SDKs handle chunking automatically above their threshold. Check your SDK's upload method for large-file variants (e.g. Python's `upload_large()` for files > 100 MB).

## Remote/Fetch Upload

Upload an asset directly from a public URL without downloading it first.

**Request:**
```
POST https://api.cloudinary.com/v1_1/<cloud_name>/<resource_type>/upload
  type: fetch
  file: <public_url>
  api_key: <api_key>
  timestamp: <unix_seconds>
  signature: <signature>
```

**URL rules:**
- Maximum 255 characters
- Must be URL-encoded (spaces → `%20`, special chars → `%XX`)
- URL must be publicly accessible (no auth required)
- Remote server timeouts apply if asset is large or slow

**Signed fetch:** If your account has fetch URL restrictions enabled, the fetch URL itself must be signed. See your account security settings.

## Signed Upload Signature

Signatures authenticate server-side upload requests. **The API secret must never appear in client-side code.**

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
- Must be Unix timestamp in **seconds**, not milliseconds
- JavaScript: `Math.floor(Date.now() / 1000)` — `Date.now()` returns ms, divide by 1000
- Signature expires 1 hour after the timestamp

**Example parameter string (before hashing):**
```
folder=uploads&public_id=my_image&timestamp=1718100000YOUR_API_SECRET
```

For complete algorithm with edge cases and examples, see [references/signed-uploads.md](references/signed-uploads.md).

## Security

### API secret
- **Never** include `api_secret` in client-side code, browser requests, or mobile apps
- **Never** commit to version control (check `.env` files, config files)
- **Never** log it — check logging middleware and error handlers
- If exposed: rotate immediately in Cloudinary Console → Settings → Security → Access Keys

### Unsigned preset exposure
- The upload preset name is visible in browser network requests and source code
- Attackers can discover and reuse it to upload to your account (quota abuse)
- Unsigned uploads cannot overwrite existing assets — this limits damage
- Use signed uploads for sensitive applications or when upload volume abuse is a concern

### Checklist before going live
- API secret is server-side only
- Upload preset is set to unsigned only if truly needed client-side
- `allowed_formats` restricts file types to what your app expects
- `max_bytes` set in preset to prevent oversized uploads

## Async Uploads

Set `async: true` to process uploads in the background. Useful for large files or expensive eager transformations.

**Response when async:** Only contains `{status: "pending", batch_id: "..."}`. The full upload result is **not** in this response.

**Full result delivery:** Cloudinary POSTs the result to `notification_url` when processing completes.

**Required:** Set `notification_url` in your request or upload preset when using `async: true`. Without it, the result is lost.

**Python SDK:** `async` is a reserved keyword. Pass it as a dictionary key:
```python
# Wrong — syntax error
cloudinary.uploader.upload("file.jpg", async=True)

# Correct
cloudinary.uploader.upload("file.jpg", **{"async": True})
# or
cloudinary.uploader.upload("file.jpg", notification_url="https://...", **{"async": True})
```

## Generate + Validate Checklist

**After generating any upload configuration or code, verify all of the following before returning:**

1. ✅ **`resource_type` explicitly set** — not relying on default `image`; matches the actual file type
2. ✅ **Unsigned param list valid** — request only contains parameters from the unsigned whitelist; everything else is in the preset
3. ✅ **`public_id` has no whitespace** — leading/trailing spaces cause silent fallback to random ID
4. ✅ **Signature timestamp in seconds** — not milliseconds (`Math.floor(Date.now() / 1000)` in JS)
5. ✅ **API secret not in client code** — only present in server-side signature generation
6. ✅ **`notification_url` set when `async: true`** — without it, upload result is lost
7. ✅ **`overwrite: true` not expected in unsigned flow** — silently forced to `false`
8. ✅ **Large file (> 100 MB) → chunked upload** — plain upload will fail or time out

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
- URL contains `/image/upload/` but file is a video → change to `/video/upload/`
- Use `/auto/upload/` if file type varies

### Step 3: Check upload type (signed vs unsigned)
- **Unsigned:** Is `upload_preset` in the request? Is it spelled correctly and set to unsigned in the Console?
- **Signed:** Is `api_key`, `timestamp`, and `signature` all present? Is timestamp in seconds?

### Step 4: Check parameter validity
- **Unsigned:** Are any non-whitelisted parameters in the request? Remove them or move to preset.
- **All:** Is `public_id` free of whitespace?

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

### Step 7: Check chunked upload (large files only)
- Is `Content-Range` format correct: `bytes <start>-<end>/<total>`?
- Is the range inclusive on both ends?
- Is `X-Unique-Upload-Id` the same value across all chunks?
- Are all chunks except the last ≥ 5 MB?

See [references/chunked-uploads.md](references/chunked-uploads.md) for arithmetic details.

### Step 8: Remote/fetch upload checks
- Is the URL ≤ 255 characters?
- Are special characters URL-encoded?
- Is the URL publicly accessible without authentication?

## Related Skills

- **cloudinary-next** and **cloudinary-react** — framework-specific upload wiring: API routes and server actions, upload widget components, and environment variable handling.
- **cloudinary-docs** — anything outside this skill's scope, looked up in the current Cloudinary documentation.

## Additional Resources

- [references/signed-uploads.md](references/signed-uploads.md) — Full signature algorithm with examples
- [references/chunked-uploads.md](references/chunked-uploads.md) — Content-Range arithmetic, chunk requirements
- [references/troubleshooting.md](references/troubleshooting.md) — Error messages and fixes
- [Upload API Reference](https://cloudinary.com/documentation/image_upload_api_reference.md)
- [Upload Images Documentation](https://cloudinary.com/documentation/upload_images.md)
- [Authentication Signatures](https://cloudinary.com/documentation/authentication_signatures.md)
- [Upload Presets](https://cloudinary.com/documentation/upload_presets.md)
