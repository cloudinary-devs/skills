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
| `Unknown API key` | Wrong or missing `api_key` | Verify api_key in Cloudinary Console → Settings → Security |

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
| `File size too large` | Exceeds `max_bytes` in preset | Increase preset limit or reduce file size |
| `Invalid file type` | File extension not in `allowed_formats` | Add format to preset's `allowed_formats`, or use a different file |
| `Resource not found` | Wrong `public_id` or asset doesn't exist | Check `public_id` for whitespace; verify asset exists |

### Chunked Upload Errors

| Error message | Root cause | Fix |
|---|---|---|
| `Invalid Content-Range header` | Wrong format or arithmetic | Use `bytes start-end/total`; end = start + chunk_size - 1 |
| `Chunk too small` | Non-final chunk < 5 MB | Ensure all chunks except last are ≥ 5,242,880 bytes |

### Account & Quota Errors

| Error message | Root cause | Fix |
|---|---|---|
| `Account is not active` | New account not email-verified | Verify email address in Cloudinary Console |
| `Quota exceeded` | Storage or bandwidth limit reached | Upgrade plan or delete unused assets |
| `Transformation credits exceeded` | Eager transformations over quota | Reduce eager transforms or upgrade plan |

## Silent Failures (No Error, Wrong Behavior)

| Behavior | Root cause | Fix |
|---|---|---|
| Asset gets random public_id instead of expected | `public_id` has whitespace, or null/empty | Strip whitespace from `public_id` before upload |
| Extra parameters ignored in unsigned upload | Parameters not in unsigned whitelist | Move parameters to upload preset |
| `overwrite: true` has no effect | Forced `false` for unsigned uploads | Switch to signed upload if overwrite is needed |
| Format not converted as expected | File type is in `allowed_formats` — stored as-is | Remove file type from `allowed_formats` if conversion is needed |
| Async upload result never arrives | `notification_url` not set | Add `notification_url` to request or preset |
| Video transformation returns still image | Used `f_auto` instead of `f_auto:video` | Use `f_auto:video` for video outputs (handled by cloudinary-transformations skill) |

## Debugging Checklist

If the above table doesn't match your error, run through the debugging workflow in [SKILL.md](../SKILL.md#debugging-workflow).
