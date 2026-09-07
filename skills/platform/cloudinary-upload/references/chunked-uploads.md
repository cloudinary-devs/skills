# Chunked Uploads — Large File Reference

Reference for uploading files larger than 100 MB using the chunked upload API.

## When to Use

- Files > 100 MB
- Unreliable network connections where resumable uploads help
- Progress tracking on large uploads

## Required Headers

Every chunk request must include:

| Header | Value | Notes |
|---|---|---|
| `Content-Range` | `bytes <start>-<end>/<total>` | See arithmetic below |
| `X-Unique-Upload-Id` | Any unique string | Same value for all chunks of one file |
| `Content-Type` | `multipart/form-data` | Standard upload content type |

## Content-Range Arithmetic

**Format:** `bytes <start>-<end>/<total>`

- `start`: byte offset of first byte in this chunk (0-indexed)
- `end`: byte offset of **last byte** in this chunk (inclusive — this is where off-by-one errors happen)
- `total`: total file size in bytes

**Example — 22,744,222 byte file split into 6 MB chunks:**

| Chunk | Start | End | Total | Header |
|---|---|---|---|---|
| 1 | 0 | 5,999,999 | 22,744,222 | `bytes 0-5999999/22744222` |
| 2 | 6,000,000 | 11,999,999 | 22,744,222 | `bytes 6000000-11999999/22744222` |
| 3 | 12,000,000 | 17,999,999 | 22,744,222 | `bytes 12000000-17999999/22744222` |
| 4 | 18,000,000 | 22,744,221 | 22,744,222 | `bytes 18000000-22744221/22744222` |

**Key:** end = start + chunk_size - 1 (not start + chunk_size)

## Chunk Size Rules

- **Minimum chunk size:** 5 MB (5,242,880 bytes) — enforced for all chunks except the last
- **Maximum chunk size:** No hard limit, but 20 MB is a practical ceiling for reliability
- **Last chunk:** Can be any size (even 1 byte)

## X-Unique-Upload-Id

- Generate once per file upload (UUID or similar)
- Use the **same value** for every chunk of that file
- Cloudinary uses this to reassemble chunks on its end
- Generating a new ID mid-upload = Cloudinary treats it as a new upload

## Response Handling

| Chunk | Response | Meaning |
|---|---|---|
| Intermediate | `{"done": false}` | Chunk received, waiting for more |
| Final | Full upload result object | Upload complete |

Do not treat `{"done": false}` as an error. Track chunk index and continue sending.

## Chunking Algorithm

```
chunk_size = 6 * 1024 * 1024  # 6 MB
upload_id = generate_uuid()
total_size = file.size
offset = 0

while offset < total_size:
    chunk_end = min(offset + chunk_size, total_size) - 1
    chunk_data = file.read(offset, chunk_end + 1)

    headers = {
        "Content-Range": f"bytes {offset}-{chunk_end}/{total_size}",
        "X-Unique-Upload-Id": upload_id
    }

    response = post("/upload", data=chunk_data, headers=headers)

    if response["done"]:
        return response  # final result
    else:
        offset = chunk_end + 1
```

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Off-by-one in `end` (using `start + size` instead of `start + size - 1`) | `400 Invalid Content-Range` | end = start + chunk_size - 1 |
| Different `X-Unique-Upload-Id` per chunk | Upload never completes; new upload started | Generate once, reuse for all chunks |
| Chunk size < 5 MB (not final chunk) | `400 Chunk too small` | Enforce 5 MB minimum for all but last chunk |
| Not handling `done: false` | Treating mid-upload as error | Only treat HTTP errors as failures |
| Wrong `total` in Content-Range | `400 Invalid Content-Range` | Use actual file byte size, not estimated |

Official documentation: [Manual Chunked Upload](https://cloudinary.com/documentation/upload_images.md#manual_chunked_upload_rest)
