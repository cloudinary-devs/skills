# Signed Uploads — Signature Generation

Complete reference for generating Cloudinary upload signatures.

## Minimal Recommended Request

When the upload parameters live in an upload preset, the request carries only `upload_preset`, `timestamp`, `api_key`, `file`, and `signature`. Only two of those are signed, and they are already in alphabetical order:

```
timestamp=1718100000&upload_preset=product-imagesMY_API_SECRET
```

Hash that string and send the hex digest as `signature`. No further sorting or joining rules come into play. Use the full algorithm below only when the request carries additional parameters.

## The Algorithm

1. **Collect parameters**: every non-empty upload request parameter except:
   - `file`
   - `cloud_name`
   - `resource_type`
   - `api_key`
   - `signature` itself

2. **Sort alphabetically** by parameter key (a–z)

3. **Build the parameter string**: join as `key=value` pairs with `&`, signing each value exactly as it is sent:
   ```
   folder=uploads&public_id=my_asset&tags=product,sale&timestamp=1718100000
   ```

4. **Append API secret**: append directly, no `&`, no `=`, no separator:
   ```
   folder=uploads&public_id=my_asset&tags=product,sale&timestamp=1718100000MY_API_SECRET
   ```

5. **Hash it** with SHA-1 or SHA-256 (SHA-256 recommended for new implementations):
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

## Value Encoding

Sign the value exactly as it appears in the request:

- **Arrays are comma-separated.** `tags: ["product", "sale"]` is signed as `tags=product,sale`.
- **Multiple eager transformations are pipe-separated**, because that is how the `eager` value itself is sent: `eager=c_fill,w_400|c_scale,w_200`.
- **`&` inside a value is encoded as `%26`** before hashing, so it cannot be confused with the parameter separator. This matters for values such as a `notification_url` with a query string: `notification_url=https://example.com/hook?a=1%26b=2`.
- **Empty parameters are left out** of both the request and the signature.

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Timestamp in milliseconds | `Signature has expired` immediately | Divide by 1000 in JS |
| Including `file` in signature | `Invalid signature` | Exclude `file` from signature params |
| Including `api_key` in signature | `Invalid signature` | Exclude `api_key` from signature params |
| Wrong sort order | `Invalid signature` | Sort keys a–z strictly |
| Missing parameter in signature | `Invalid signature` | Include every non-empty request param except the excluded ones |
| Tags joined with `\|` | `Invalid signature` | Sign arrays comma-separated, exactly as sent |
| Unencoded `&` inside a value | `Invalid signature` | Encode `&` in values as `%26` before hashing |
| Parameter in request but not signature | `Invalid signature` | Any param sent in the request must be in the signature |
| Wrong API secret | `Invalid signature` | Verify you're using the correct secret for the cloud |

## Verification

To debug a signature mismatch:
1. Log the exact parameter string before hashing (temporarily)
2. Verify each parameter appears in both the string and the request
3. Verify sort order: compare your sorted keys to alphabetical
4. Verify timestamp value is ≤ 3600 seconds in the past

Official documentation: [Authentication Signatures](https://cloudinary.com/documentation/authentication_signatures.md?install_source=skillspack&referrer=upload-skill)
