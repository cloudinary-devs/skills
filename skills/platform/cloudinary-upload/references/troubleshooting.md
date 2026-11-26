# Upload Troubleshooting

Error messages, causes, and fixes for Cloudinary upload failures.

## Error Response Format

Cloudinary returns errors as JSON:
```json
{"error": {"message": "Exact error message here"}}
```
HTTP status is typically 400 (bad request) or 401 (auth failure).

## Error Reference

### Authentication & Signature Errors

| Error message | Root cause | Fix |
|---|---|---|
| `Invalid signature` | Signature mismatch | Check: parameter sort order, excluded params (file, cloud_name, resource_type, api_key), API secret is correct. See [signed-uploads.md](signed-uploads.md) |
| `Signature has expired` | Timestamp > 1 hour old, or timestamp in milliseconds | Use `Math.floor(Date.now() / 1000)` in JS; regenerate signature |
| `Missing required parameter - signature` | Signed upload missing signature field | Add `signature` to request |
| `Missing required parameter - timestamp` | Signed upload missing timestamp field | Add `timestamp` (seconds) to request |
| `Unknown API key` | Wrong or missing `api_key` | Ask the user to confirm the API key and secret pair in Cloudinary Console → Settings → API Keys, and that it belongs to the same cloud as `cloud_name` |

### Upload Preset Errors

| Error message | Root cause | Fix |
|---|---|---|
| `Upload preset must be specified` | Unsigned upload missing `upload_preset` | Add `upload_preset` parameter |
| `Upload preset not found` | Preset name is wrong or doesn't exist | Check preset name in Console → Settings → Upload |
| `Upload preset is not enabled for unsigned uploads` | Preset is set to signed mode | Change preset mode to unsigned, or use signed upload |

### Resource & File Errors

| Error message | Root cause | Fix |
|---|---|---|
| `Invalid image file` | Wrong `resource_type` for uploaded file | Set `resource_type: "video"` for videos, `"raw"` for non-media files |
| `Invalid file type` | File extension not in `allowed_formats` | Add format to preset's `allowed_formats`, or use a different file |
| `Resource not found` | Wrong `public_id` or asset doesn't exist | Check `public_id` for whitespace; verify asset exists |

### Chunked Upload Errors

| Error message | Root cause | Fix |
|---|---|---|
| `Invalid Content-Range header` | Wrong format or arithmetic | Use `bytes start-end/total`; end = start + chunk_size - 1 |
| `Chunk too small` | Non-final chunk < 5 MB | Ensure all chunks except last are ≥ 5,242,880 bytes |

### Account & Quota Errors

These need action from the account owner. Tell the user what to do; the agent cannot fix them in code.

| Error message | Root cause | Fix |
|---|---|---|
| `Account is not active` | New account not email-verified | Ask the user to verify their email address from the Cloudinary sign-up email |
| `Quota exceeded` | Storage or bandwidth limit reached | Ask the user to upgrade their plan or delete unused assets |
| `Transformation credits exceeded` | Eager transformations over quota | Reduce eager transformations, or ask the user to upgrade their plan |

## Silent Failures (No Error, Wrong Behavior)

| Behavior | Root cause | Fix |
|---|---|---|
| Asset gets random public_id instead of expected | `public_id` has whitespace, or null/empty | Strip whitespace from `public_id` before upload |
| Extra parameters ignored in unsigned upload | Parameters not in the unsigned allow-list | Move parameters to the upload preset |
| Allow-listed parameter (e.g. `folder`, `tags`) ignored in unsigned upload | Preset defines the same parameter; for unsigned uploads the preset wins (only `public_id` and `filename_override` come from the request; `context` and `metadata` merge) | Remove the parameter from the preset, or switch to a signed upload |
| Asset lands in the root folder despite slashes in `public_id` | Dynamic folder mode: `public_id` path does not set the folder | Set `asset_folder` (in the preset) |
| Folder path missing from delivery URL | Dynamic folder mode: `asset_folder` is not part of the `public_id` | Add `public_id_prefix` or `use_asset_folder_as_public_id_prefix: true` |
| Eager transformation exists but delivery still generates lazily | Delivery string differs from the eager string (parameter order, extension, `f_auto`) | Use identical strings or a shared `t_<name>`; pre-generate explicit formats and deliver with `f_auto` and no extension |
| `f_auto` in `eager` or incoming `transformation` does nothing | No requesting browser at upload time | Use explicit formats (`f_webp`, `f_jpg`) in eager; keep `f_auto` on the delivery URL |
| `overwrite: true` has no effect | Forced `false` for unsigned uploads | Switch to signed upload if overwrite is needed |
| Format not converted as expected | File type is in `allowed_formats` — stored as-is | Remove file type from `allowed_formats` if conversion is needed |
| Async upload result never arrives | `notification_url` not set | Add `notification_url` to request or preset |

## Debugging Workflow

When an upload fails or behaves unexpectedly and the tables above don't match, follow these steps in order.

### Step 1: Read the error response
Cloudinary errors are in the response body:
```json
{"error": {"message": "..."}}
```
Note the exact message before doing anything else, and check it against the [Error Reference](#error-reference) above.

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
3. Is every value signed exactly as sent (comma-separated `tags`, `&` inside values encoded as `%26`, empty parameters left out)?
4. Is the API secret appended directly with no separator?
5. Is the timestamp within the last hour?

See [signed-uploads.md](signed-uploads.md) for the full algorithm.

### Step 6: Check preset configuration
Open Cloudinary Console → Settings → Upload → [your preset] and verify:
- Preset mode matches usage (signed vs unsigned)
- `allowed_formats` isn't blocking the file type
- Eager transformations don't contain `f_auto`

### Step 7: Check eager and delivery transformations match
- Does the delivery URL use the identical transformation string (same parameter order, same format component)?
- Delivering with `f_auto`? Pre-generate each format you expect `f_auto` to pick (for example `f_webp`, `f_avif`, `f_jpg`) as separate eager variants, and deliver without a file extension so the extension does not become part of the transformation string.
- Was `eager_async` used? The derived asset may not exist yet; check the `eager_notification_url` webhook.

### Step 8: Check chunked upload (large files only)
- Is `Content-Range` in the form `bytes <start>-<end>/<total>`?
- Is the range inclusive on both ends?
- Is `X-Unique-Upload-Id` the same value across all chunks?
- Are all chunks except the last ≥ 5 MB?

See [chunked-uploads.md](chunked-uploads.md) for arithmetic details.

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
- Set `allowed_formats` on unsigned presets
- Use `eager_async: true` for video eager transformations
- Build delivery URLs with the cloudinary-transformations skill so they match eager output
