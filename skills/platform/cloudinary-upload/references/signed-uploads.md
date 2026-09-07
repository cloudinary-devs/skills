# Signed Uploads — Signature Generation

Complete reference for generating Cloudinary upload signatures.

## The Algorithm

1. **Collect parameters** — all upload request parameters except:
   - `file`
   - `cloud_name`
   - `resource_type`
   - `api_key`
   - `signature` (obviously)

2. **Sort alphabetically** by parameter key (a–z)

3. **Build the parameter string** — join as `key=value` pairs with `&`:
   ```
   folder=uploads&public_id=my_asset&timestamp=1718100000&tags=product,sale
   ```

4. **Append API secret** — append directly, no `&`, no `=`, no separator:
   ```
   folder=uploads&public_id=my_asset&timestamp=1718100000&tags=product,saleMY_API_SECRET
   ```

5. **Hash it** — SHA-1 or SHA-256 (SHA-256 recommended for new implementations):
   ```
   signature = sha256(parameter_string + api_secret)
   ```

## Timestamp Rules

- Must be **Unix time in seconds** (not milliseconds)
- JavaScript pitfall: `Date.now()` → milliseconds → divide by 1000:
  ```javascript
  const timestamp = Math.floor(Date.now() / 1000);
  ```
- Python: `int(time.time())` returns seconds natively
- Signature is valid for **1 hour** from the timestamp value
- Expired signatures return: `{"error": {"message": "Signature has expired"}}`

## Multi-Value Parameters

Some parameters accept multiple values (e.g. `tags`, `eager`). Join with `|` before including in signature string:
```
tags=product|sale|featured
eager=c_fill,w_400|c_scale,w_200
```

> **Note:** Tags are comma-separated in the request body (e.g. `tags: "product,sale"`) but joined with `|` only within the signature string. These are different contexts — don't confuse them.

## Upload Preset in Signature

If using an upload preset in a signed upload, include `upload_preset` in the signature string. Since `t` comes before `u` alphabetically, `timestamp` sorts before `upload_preset`:
```
timestamp=1718100000&upload_preset=my_presetMY_API_SECRET
```

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Timestamp in milliseconds | `Signature has expired` immediately | Divide by 1000 in JS |
| Including `file` in signature | `Invalid signature` | Exclude `file` from signature params |
| Including `api_key` in signature | `Invalid signature` | Exclude `api_key` from signature params |
| Wrong sort order | `Invalid signature` | Sort keys a–z strictly |
| Missing parameter in signature | `Invalid signature` | Include ALL request params except the four excluded ones |
| Parameter in request but not signature | `Invalid signature` | Any param sent in the request must be in the signature |
| Wrong API secret | `Invalid signature` | Verify you're using the correct secret for the cloud |

## Verification

To debug a signature mismatch:
1. Log the exact parameter string before hashing (temporarily)
2. Verify each parameter appears in both the string and the request
3. Verify sort order: compare your sorted keys to alphabetical
4. Verify timestamp value is ≤ 3600 seconds in the past

Official documentation: [Authentication Signatures](https://cloudinary.com/documentation/authentication_signatures.md)
