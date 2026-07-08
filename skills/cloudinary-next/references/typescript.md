# TypeScript patterns

Use this for safe upload result narrowing, server upload result types, refs, and avoiding `any`.


## TypeScript Patterns

### Upload result type

The widget result `info` shape is documented but loosely typed. Define a local interface and narrow:

```ts
export interface CloudinaryUploadResult {
  public_id: string;
  secure_url: string;
  url: string;
  width: number;
  height: number;
  format: string;
  resource_type: 'image' | 'video' | 'raw';
  bytes: number;
  created_at: string;
  // …extend with any other fields you need
}

function isUploadInfo(info: unknown): info is CloudinaryUploadResult {
  return (
    typeof info === 'object' &&
    info !== null &&
    'public_id' in info &&
    typeof (info as CloudinaryUploadResult).public_id === 'string'
  );
}
```

Then narrow inside callbacks:

```tsx
<CldUploadWidget
  uploadPreset="..."
  onSuccess={(result) => {
    if (isUploadInfo(result?.info)) {
      const { public_id, secure_url } = result.info;
    }
  }}
>{({ open }) => <button onClick={() => open()}>Upload</button>}</CldUploadWidget>
```

- ❌ **WRONG**: `onSuccess={(result: any) => …}` — use the type emitted by `next-cloudinary` plus your narrowed type.
- ❌ **WRONG**: Treating `result.info` as always being an object — it can be a string for non-success events.

### Server-side upload result

The Node SDK exports types — use them:

```ts
import { v2 as cloudinary, type UploadApiResponse, type UploadApiErrorResponse } from 'cloudinary';
```

`UploadApiResponse` covers the full response shape (`public_id`, `secure_url`, `width`, `height`, `bytes`, `format`, `resource_type`, `created_at`, etc.).

### Refs

```tsx
import type { CldVideoPlayerProps } from 'next-cloudinary';
import { useRef } from 'react';

const playerRef = useRef<unknown>(null);     // Cloudinary player instance — type as unknown until you need methods
const videoRef = useRef<HTMLVideoElement>(null);
```

### Avoid `any`
- ❌ **WRONG**: `const result: any = …`
- ✅ **CORRECT**: `unknown` + a narrowing type guard, or the explicit type from the SDK.
