# Import patterns

Use this when deciding import paths or diagnosing module/import errors.


## Import Patterns

```ts
// Components (client components)
import { CldImage, CldVideoPlayer, CldUploadWidget, CldUploadButton, CldOgImage } from 'next-cloudinary';

// URL helpers (isomorphic — server, client, metadata, route handlers)
import { getCldImageUrl, getCldOgImageUrl, getCldVideoUrl } from 'next-cloudinary';

// Video player CSS — required only when using CldVideoPlayer
import 'next-cloudinary/dist/cld-video-player.css';

// Server-side Node SDK v2 (only in route handlers / Server Actions / server-only files)
import { v2 as cloudinary } from 'cloudinary';
```

- ❌ **WRONG**: `import { CldImage } from '@cloudinary/next'` — package does not exist.
- ❌ **WRONG**: `import cloudinary from 'cloudinary'` — gives you v1 namespace; always use `import { v2 as cloudinary } from 'cloudinary'`.
- ❌ **WRONG**: `import 'cloudinary-video-player/cld-video-player.min.css'` — that's the React rules' path. In Next.js use `next-cloudinary/dist/cld-video-player.css`.
