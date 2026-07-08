# Server-side upload and delete

Use this for Server Actions or route handlers that upload or delete assets using the Cloudinary Node SDK v2.


## Server-side upload (Server Action / route handler)

Use the Node SDK v2 directly. This is for: uploading a file you already have on the server (e.g. a Server Action receiving a `FormData`), uploading a remote URL, scheduled jobs, etc.

```ts
// app/actions/upload.ts
'use server';

import { v2 as cloudinary, type UploadApiResponse } from 'cloudinary';

cloudinary.config({
  cloud_name: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
  api_key: process.env.NEXT_PUBLIC_CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export async function uploadImage(formData: FormData): Promise<{ publicId: string; url: string }> {
  const file = formData.get('file');
  if (!(file instanceof File)) throw new Error('No file provided');

  const arrayBuffer = await file.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);

  const result = await new Promise<UploadApiResponse>((resolve, reject) => {
    cloudinary.uploader
      .upload_stream({ folder: 'user-uploads', resource_type: 'auto' }, (err, res) => {
        if (err || !res) return reject(err);
        resolve(res);
      })
      .end(buffer);
  });

  return { publicId: result.public_id, url: result.secure_url };
}
```

- ✅ **`"use server"`** at the top of the file (Server Actions) **or** put this in a route handler — never in a client file.
- ✅ Use `upload_stream` with a `Buffer` for `File`/`Blob` inputs from `FormData`. For URL or base64 string inputs, use `cloudinary.uploader.upload(input, options)`.
- ✅ `resource_type: 'auto'` works for both images and videos.
- ✅ Configure `cloudinary` at module scope (top of the file) — config is idempotent.
- ❌ **Don't** call `cloudinary.uploader.upload` from a Client Component.
- ❌ **Don't** use the Edge runtime for routes/actions that import `cloudinary` — it will fail. Default Node runtime is fine.
- ❌ **Don't** read or stream the file before converting to `Buffer`/base64 — `File` objects from `FormData` don't pass directly to `upload`.

## Delete an asset (Server Action / route handler)

```ts
// app/actions/delete.ts
'use server';

import { v2 as cloudinary } from 'cloudinary';

cloudinary.config({
  cloud_name: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
  api_key: process.env.NEXT_PUBLIC_CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export async function deleteAsset(
  publicId: string,
  resourceType: 'image' | 'video' | 'raw' = 'image',
): Promise<{ result: string }> {
  const res = await cloudinary.uploader.destroy(publicId, {
    resource_type: resourceType,
    invalidate: true,   // purge the CDN cache
  });
  // res.result === 'ok' | 'not found'
  return { result: res.result };
}
```

- ✅ **`destroy` takes a public ID, not a URL.** Strip any URL/extension first if needed.
- ✅ Pass `resource_type: 'video'` for video assets, `'raw'` for non-image/non-video. The default is `'image'`.
- ✅ Pass `invalidate: true` to evict the CDN cache (one of the most common follow-up bug reports).
- ✅ A successful response is `{ result: 'ok' }`; a missing asset is `{ result: 'not found' }` — handle both.
- ❌ **Don't** call `destroy` from the client — it requires `api_secret`.
- ❌ **Don't** confuse `destroy` (single asset) with `delete_resources` (admin API, batch).
