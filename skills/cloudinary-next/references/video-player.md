# Video player

Use this for `CldVideoPlayer` setup, required CSS, and client-only video player code.


## CldVideoPlayer — the player

Wraps the Cloudinary Video Player. **Required**: `width`, `height`, `src`. **Always** import the CSS once on the page (or in a layout).

```tsx
'use client';

import { CldVideoPlayer } from 'next-cloudinary';
import 'next-cloudinary/dist/cld-video-player.css';

<CldVideoPlayer
  width="1920"
  height="1080"
  src="samples/elephants"
/>;
```

- ✅ **`"use client"` is required** — the player mounts a video element, attaches refs, and uses effects.
- ✅ CSS path is exactly `next-cloudinary/dist/cld-video-player.css`. No other variant is exposed.
- ✅ Use `colors`, `fontFace`, `logo`, `poster`, `textTracks` for customization (see CldVideoPlayer configuration page).
- ✅ For event hooks: `onMetadataLoad`, `onPlay`, `onPause`, `onEnded`, `onError` — each receives `{ player }`. The player exposes `player.duration()`, `player.currentTime()`, etc.
- ✅ For programmatic control, pass `playerRef` (Cloudinary player) or `videoRef` (HTML video element) refs.
- ❌ **Don't** import the `cloudinary-video-player` package directly in a Next.js app — `next-cloudinary` wraps it.
- ❌ **Don't** put `<CldVideoPlayer>` in a Server Component without `"use client"`.
