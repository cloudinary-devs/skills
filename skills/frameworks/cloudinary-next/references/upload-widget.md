# Browser upload widget

Use this for browser uploads with `CldUploadWidget` or `CldUploadButton`, upload events, and choosing signed versus unsigned uploads. For the complete signature endpoint pattern, also read `signed-uploads.md`.


## CldUploadWidget — uploading from the browser

```tsx
'use client';

import { CldUploadWidget } from 'next-cloudinary';

<CldUploadWidget uploadPreset="<unsigned-preset>">
  {({ open }) => (
    <button type="button" onClick={() => open()}>Upload</button>
  )}
</CldUploadWidget>;
```

- ✅ **`"use client"` is required**.
- ✅ The widget renders **nothing by default** — pass a function-as-children that returns the trigger UI. The function receives `{ open, close, cloudinary, widget, results, error, isLoading }`.
- ✅ Use `<CldUploadButton>` for a one-line drop-in if you don't need custom UI.
- ✅ **Default to unsigned uploads** unless the user explicitly asks for "secure" or "signed". Signed requires a running backend route and will fail out of the box without it.
- ✅ Pass widget params via the `options` prop, not as top-level props (sources, multiple, maxFiles, folder, tags, etc.):

```tsx
<CldUploadWidget
  uploadPreset="..."
  options={{
    sources: ['local', 'url', 'camera'],
    multiple: false,
    maxFiles: 1,
    folder: 'user-uploads',
  }}
>{({ open }) => <button onClick={() => open()}>Upload</button>}</CldUploadWidget>
```

### Upload events (use `onSuccess`, NOT `onUpload`)

```tsx
<CldUploadWidget
  uploadPreset="..."
  onSuccess={(result, { widget }) => {
    // result.event === 'success'
    // result.info has { public_id, secure_url, width, height, format, ... }
    if (typeof result?.info === 'object' && result.info && 'public_id' in result.info) {
      console.log('Uploaded:', result.info.public_id);
    }
    widget.close();
  }}
  onError={(error) => console.error(error)}
  onQueuesEnd={(_, { widget }) => widget.close()}
>{({ open }) => <button onClick={() => open()}>Upload</button>}</CldUploadWidget>
```

- ✅ **Prefer `onSuccess`** — `onUpload` is deprecated.
- ✅ The "Action" variants (`onSuccessAction`, `onUploadAddedAction`, etc.) are the same events but only receive `results` (no widget instance) — use them when wiring directly to a Server Action so the callback is serializable.
- ✅ `result.info` shape includes at least: `public_id`, `secure_url`, `url`, `width`, `height`, `format`, `resource_type`, `bytes`, `created_at`. Type it explicitly (see TypeScript section).
- ❌ **Don't** treat `result.info` as always an object — when the event isn't `success` it can be a string. Narrow before accessing.

### Signed vs unsigned — when to use which

**Unsigned** (simpler, no backend):
- For: low-risk apps, where you want to enable end users to upload assets with your app. 
- Trade-off: anyone who learns the preset name can upload to your cloud (subject to preset restrictions).
- ✅ Set the preset to **Unsigned** when creating it (via AI or in the Console) and then add `uploadPreset="<name>"` to the widget. 

**Signed** (backend required):
- For: upload by authenticated users or controlled backend uploads.
- Trade-off: requires a running route handler. More secure.
- ✅ Use `signatureEndpoint` + the route handler.

**Default**: Prefer unsigned unless the user explicitly asks for signed/secure uploads.
